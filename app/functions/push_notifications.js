'use strict';

const {FieldValue} = require('firebase-admin/firestore');

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

function cleanText(value, fallback, maxLength = 160) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (!text) return fallback;
  return text.length <= maxLength ? text : `${text.slice(0, maxLength - 1)}…`;
}

function chatRecipients(conversation, senderId, receiverId) {
  const participants = Array.isArray(conversation?.participants)
    ? conversation.participants.filter((id) => typeof id === 'string' && id)
    : [];
  if (!participants.includes(senderId)) return [];
  if (receiverId && participants.includes(receiverId) && receiverId !== senderId) {
    return [receiverId];
  }
  return participants.filter((id) => id !== senderId);
}

function chatPayload({conversationId, senderId, senderName, content}) {
  return {
    notification: {
      title: cleanText(senderName, 'New message', 80),
      body: cleanText(content, 'Sent you a message', 140),
    },
    data: {
      type: 'chat',
      contentType: 'chat',
      contentId: conversationId,
      conversationId,
      senderId,
    },
  };
}

async function deliverToUser({db, messaging, uid, notificationId, payload, record}) {
  const notificationRef = db.collection('notifications').doc(notificationId);
  const existing = await notificationRef.get();
  if (existing.exists && existing.data()?.pushStatus === 'sent') return {sent: 0};

  await notificationRef.set({
    ...record,
    userId: uid,
    isRead: false,
    pushStatus: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const tokenSnapshot = await db.collection('users').doc(uid).collection('fcmTokens').get();
  const tokenDocs = tokenSnapshot.docs.filter((doc) => {
    const token = doc.data()?.token;
    return typeof token === 'string' && token.length > 0;
  });
  if (tokenDocs.length === 0) {
    await notificationRef.set({
      pushStatus: 'no_devices',
      pushUpdatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return {sent: 0};
  }

  let sent = 0;
  for (let offset = 0; offset < tokenDocs.length; offset += 500) {
    const chunk = tokenDocs.slice(offset, offset + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk.map((doc) => doc.data().token),
      notification: payload.notification,
      data: payload.data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'cie_daily_messages',
          sound: 'default',
          color: '#FF5A1F',
        },
      },
      apns: {
        payload: {aps: {sound: 'default'}},
      },
    });
    sent += response.successCount;
    const deletes = [];
    response.responses.forEach((result, index) => {
      if (!result.success && INVALID_TOKEN_CODES.has(result.error?.code)) {
        deletes.push(chunk[index].ref.delete());
      }
    });
    await Promise.allSettled(deletes);
  }

  await notificationRef.set({
    pushStatus: sent > 0 ? 'sent' : 'failed',
    pushUpdatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {sent};
}

async function processChatMessage({db, messaging, conversationId, messageId, message}) {
  const senderId = typeof message?.senderId === 'string' ? message.senderId : '';
  if (!senderId || message?.isSystemMessage === true) return {recipients: 0, sent: 0};

  const conversationSnapshot = await db.collection('conversations').doc(conversationId).get();
  if (!conversationSnapshot.exists) return {recipients: 0, sent: 0};
  const conversation = conversationSnapshot.data();
  const recipients = chatRecipients(conversation, senderId, message.receiverId);
  if (recipients.length === 0) return {recipients: 0, sent: 0};

  const senderDetails = conversation.participantDetails?.[senderId] ?? {};
  const senderName = cleanText(senderDetails.name, 'New message', 80);
  const payload = chatPayload({
    conversationId,
    senderId,
    senderName,
    content: message.content,
  });

  let sent = 0;
  for (const uid of recipients) {
    const result = await deliverToUser({
      db,
      messaging,
      uid,
      notificationId: `chat_${conversationId}_${messageId}_${uid}`,
      payload,
      record: {
        actorId: senderId,
        actorName: senderName,
        title: payload.notification.title,
        body: payload.notification.body,
        type: 'chat',
        contentType: 'chat',
        contentId: conversationId,
      },
    });
    sent += result.sent;
  }
  return {recipients: recipients.length, sent};
}

async function processPublishedPost({db, messaging, postId, post}) {
  if (!post || post.status !== 'approved') return {recipients: 0, sent: 0};
  const authorId = typeof post.authorId === 'string' ? post.authorId : '';
  if (!authorId) return {recipients: 0, sent: 0};

  const [followsSnapshot, authorSnapshot] = await Promise.all([
    db.collection('follows').where('followingId', '==', authorId).get(),
    db.collection('users').doc(authorId).get(),
  ]);
  const followerIds = new Set();
  for (const doc of followsSnapshot.docs) {
    const id = doc.data()?.followerId;
    if (typeof id === 'string' && id) followerIds.add(id);
  }
  const authorData = authorSnapshot.data() ?? {};
  for (const id of Array.isArray(authorData.followers) ? authorData.followers : []) {
    if (typeof id === 'string' && id) followerIds.add(id);
  }
  followerIds.delete(authorId);

  const authorName = cleanText(post.authorName ?? authorData.name, 'A creator you follow', 80);
  const contentType = String(post.category ?? '').toLowerCase() === 'reel' ? 'reel' : 'article';
  const payload = {
    notification: {
      title: `${authorName} published a new ${contentType}`,
      body: cleanText(post.title, 'Tap to view the latest story.', 140),
    },
    data: {
      type: contentType,
      contentType,
      contentId: postId,
      articleId: contentType === 'article' ? postId : '',
    },
  };

  let sent = 0;
  for (const uid of followerIds) {
    const result = await deliverToUser({
      db,
      messaging,
      uid,
      notificationId: `creator_${postId}_${uid}`,
      payload,
      record: {
        actorId: authorId,
        actorName: authorName,
        actorAvatar: authorData.photoUrl ?? post.authorAvatar ?? null,
        title: payload.notification.title,
        body: payload.notification.body,
        type: 'creator_content',
        contentType,
        contentId: postId,
      },
    });
    sent += result.sent;
  }
  return {recipients: followerIds.size, sent};
}

module.exports = {
  chatPayload,
  chatRecipients,
  cleanText,
  deliverToUser,
  processChatMessage,
  processPublishedPost,
};
