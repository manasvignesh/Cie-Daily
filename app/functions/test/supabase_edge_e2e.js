'use strict';

const fs = require('node:fs');
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {initializeApp, cert, deleteApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');

async function firebaseIdToken(auth, uid, apiKey) {
  const customToken = await auth.createCustomToken(uid);
  const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${encodeURIComponent(apiKey)}`,
      {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({token: customToken, returnSecureToken: true}),
      },
  );
  const result = await response.json();
  assert.equal(response.ok, true, `Firebase token exchange failed (${response.status})`);
  assert.equal(typeof result.idToken, 'string');
  return result.idToken;
}

async function invoke(baseUrl, name, token, body) {
  const response = await fetch(`${baseUrl}/${name}`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(30000),
  });
  const result = await response.json();
  return {status: response.status, result};
}

function assertStatus(stage, response, expected) {
  const safeCode = typeof response.result?.error === 'string' ? response.result.error : 'unknown';
  const remoteStage = typeof response.result?.stage === 'string' ? response.result.stage : 'unknown';
  const diagnostic = typeof response.result?.diagnostic === 'string' ? response.result.diagnostic : 'unknown';
  const errorType = typeof response.result?.errorType === 'string' ? response.result.errorType : 'unknown';
  assert.equal(
      response.status,
      expected,
      `${stage} returned HTTP ${response.status} (${safeCode}, stage=${remoteStage}, diagnostic=${diagnostic}, type=${errorType})`,
  );
}

async function main() {
  const credentialFile = process.env.FIREBASE_SERVICE_ACCOUNT_FILE;
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  const baseUrl = process.env.SUPABASE_FUNCTIONS_URL;
  if (!credentialFile || !apiKey || !baseUrl) {
    console.log(JSON.stringify({ok: true, skipped: true, reason: 'production E2E environment not configured'}));
    return;
  }
  const serviceAccount = JSON.parse(fs.readFileSync(credentialFile, 'utf8'));
  assert.equal(serviceAccount.project_id, 'cie-connect');

  const app = initializeApp({credential: cert(serviceAccount)}, `edge-e2e-${Date.now()}`);
  const auth = getAuth(app);
  const db = getFirestore(app);
  const suffix = randomUUID().replaceAll('-', '').slice(0, 12);
  const senderUid = `edge-sender-${suffix}`;
  const recipientUid = `edge-recipient-${suffix}`;
  const conversationId = `edge-conversation-${suffix}`;
  const requestId = `message-${suffix}`;
  const contentRequestId = `content-${suffix}`;
  const refsToDelete = [];

  try {
    await Promise.all([
      auth.createUser({uid: senderUid, email: `${senderUid}@example.com`, displayName: 'Edge Test Sender'}),
      auth.createUser({uid: recipientUid, email: `${recipientUid}@example.com`, displayName: 'Edge Test Recipient'}),
      db.collection('users').doc(senderUid).set({
        name: 'Edge Test Sender', role: 'creator', followers: [recipientUid],
      }),
      db.collection('users').doc(recipientUid).set({
        name: 'Edge Test Recipient', notificationPreferences: {enabled: true, creatorContent: true},
      }),
      db.collection('conversations').doc(conversationId).set({
        participants: [senderUid, recipientUid],
        participantDetails: {
          [senderUid]: {name: 'Edge Test Sender'},
          [recipientUid]: {name: 'Edge Test Recipient'},
        },
        unreadCounts: {[senderUid]: 0, [recipientUid]: 0},
      }),
      db.collection('follows').doc(`${recipientUid}_${senderUid}`).set({
        followerId: recipientUid, followingId: senderUid,
      }),
    ]);
    const token = await firebaseIdToken(auth, senderUid, apiKey);
    // Proves the exact credential and token are valid before the remote call.
    await auth.verifyIdToken(token, true);

    const messageBody = {conversationId, content: 'Edge integration test', clientMessageId: requestId};
    const firstMessage = await invoke(baseUrl, 'send-message', token, messageBody);
    assertStatus('send-message create', firstMessage, 200);
    assert.equal(firstMessage.result.created, true);
    const retryMessage = await invoke(baseUrl, 'send-message', token, messageBody);
    assertStatus('send-message retry', retryMessage, 200);
    assert.equal(retryMessage.result.created, false);
    const conversation = await db.collection('conversations').doc(conversationId).get();
    assert.equal(conversation.data().unreadCounts[recipientUid], 1);

    const forged = await invoke(baseUrl, 'send-message', token, {
      ...messageBody, clientMessageId: `${requestId}-forged`, senderId: recipientUid,
    });
    assertStatus('send-message forged sender', forged, 403);

    const draft = await invoke(baseUrl, 'publish-content', token, {
      clientContentId: `${contentRequestId}-draft`,
      post: {title: 'Disposable draft test', category: 'Article', blocks: [], status: 'draft'},
    });
    assertStatus('publish-content draft', draft, 200);
    assert.equal(draft.result.published, false);
    refsToDelete.push(db.collection('posts').doc(draft.result.postId));

    const publishBody = {
      clientContentId: contentRequestId,
      post: {title: 'Disposable published test', category: 'Article', blocks: [], status: 'approved'},
    };
    const published = await invoke(baseUrl, 'publish-content', token, publishBody);
    assertStatus('publish-content create', published, 200);
    assert.equal(published.result.created, true);
    const publishRetry = await invoke(baseUrl, 'publish-content', token, publishBody);
    assertStatus('publish-content retry', publishRetry, 200);
    assert.equal(publishRetry.result.created, false);
    refsToDelete.push(db.collection('posts').doc(published.result.postId));

    console.log(JSON.stringify({
      ok: true,
      message: {created: firstMessage.result.created, retryDeduplicated: !retryMessage.result.created},
      senderImpersonationRejected: forged.status === 403,
      draftDidNotNotify: draft.result.published === false,
      publishing: {created: published.result.created, retryDeduplicated: !publishRetry.result.created},
    }));

    const messageId = firstMessage.result.messageId;
    refsToDelete.push(
        db.collection('conversations').doc(conversationId).collection('messages').doc(messageId),
        db.collection('notifications').doc(`chat_${conversationId}_${messageId}_${recipientUid}`),
        db.collection('notifications').doc(`creator_${published.result.postId}_${recipientUid}`),
    );
  } finally {
    await Promise.allSettled(refsToDelete.map((ref) => ref.delete()));
    await Promise.allSettled([
      db.collection('follows').doc(`${recipientUid}_${senderUid}`).delete(),
      db.collection('conversations').doc(conversationId).delete(),
      db.collection('backendRateLimits').doc(`message_${senderUid}`).delete(),
      db.collection('users').doc(senderUid).delete(),
      db.collection('users').doc(recipientUid).delete(),
      auth.deleteUser(senderUid),
      auth.deleteUser(recipientUid),
    ]);
    await db.terminate();
    await deleteApp(app);
  }
}

main().catch((error) => {
  console.error(JSON.stringify({ok: false, name: error.name, message: error.message}));
  process.exitCode = 1;
});
