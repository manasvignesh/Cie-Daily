const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  addDoc,
  serverTimestamp,
} = require('firebase/firestore');
const { ref, uploadBytes } = require('firebase/storage');

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-cie-daily',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
    storage: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8'),
    },
  });
});

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'conversations', 'alice_bob'), {
      participants: ['alice', 'bob'],
      unreadCounts: { alice: 0, bob: 0 },
    });
    await setDoc(doc(db, 'conversations', 'alice_bob', 'messages', 'm1'), {
      senderId: 'alice',
      content: 'private',
    });
    await setDoc(doc(db, 'connections', 'alice_bob'), {
      users: ['alice', 'bob'],
    });
    await setDoc(doc(db, 'notifications', 'alice_notice'), {
      userId: 'alice',
      isRead: false,
    });
    await setDoc(doc(db, 'group_chats', 'private_group'), {
      createdById: 'alice',
      members: ['alice', 'bob'],
      isPublic: false,
      memberDetails: {},
    });
    await setDoc(doc(db, 'group_chats', 'private_group', 'messages', 'g1'), {
      senderId: 'alice',
      content: 'members only',
    });
  });
});

test.after(async () => {
  await env.cleanup();
});

test('conversation and messages are participant-only', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const attacker = env.authenticatedContext('mallory').firestore();
  const guest = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(alice, 'conversations', 'alice_bob')));
  await assertSucceeds(getDoc(doc(alice, 'conversations', 'alice_bob', 'messages', 'm1')));
  await assertFails(getDoc(doc(attacker, 'conversations', 'alice_bob')));
  await assertFails(getDoc(doc(attacker, 'conversations', 'alice_bob', 'messages', 'm1')));
  await assertFails(getDoc(doc(guest, 'conversations', 'alice_bob')));
});

test('direct clients cannot bypass authoritative message sending', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(
    doc(alice, 'conversations', 'alice_bob', 'messages', 'client-bypass'),
    {senderId: 'alice', receiverId: 'bob', content: 'bypass', isRead: false},
  ));
});

test('connection creation and deletion require a participant', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const attacker = env.authenticatedContext('mallory').firestore();
  await assertSucceeds(setDoc(doc(alice, 'connections', 'alice_charlie'), {
    users: ['alice', 'charlie'],
  }));
  await assertFails(setDoc(doc(attacker, 'connections', 'alice_charlie_2'), {
    users: ['alice', 'charlie'],
  }));
  await assertFails(deleteDoc(doc(attacker, 'connections', 'alice_bob')));
  await assertSucceeds(deleteDoc(doc(alice, 'connections', 'alice_bob')));
});

test('notifications are visible and mutable only by their owner', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const attacker = env.authenticatedContext('mallory').firestore();
  await assertSucceeds(getDoc(doc(alice, 'notifications', 'alice_notice')));
  await assertSucceeds(updateDoc(doc(alice, 'notifications', 'alice_notice'), { isRead: true }));
  await assertFails(getDoc(doc(attacker, 'notifications', 'alice_notice')));
  await assertFails(updateDoc(doc(attacker, 'notifications', 'alice_notice'), { isRead: true }));
});

test('private group messages require membership', async () => {
  const bob = env.authenticatedContext('bob').firestore();
  const attacker = env.authenticatedContext('mallory').firestore();
  await assertSucceeds(getDoc(doc(bob, 'group_chats', 'private_group')));
  await assertSucceeds(getDoc(doc(bob, 'group_chats', 'private_group', 'messages', 'g1')));
  await assertFails(getDoc(doc(attacker, 'group_chats', 'private_group')));
  await assertFails(getDoc(doc(attacker, 'group_chats', 'private_group', 'messages', 'g1')));
});

test('an unrelated user cannot self-join or rewrite a private community', async () => {
  const attacker = env.authenticatedContext('mallory').firestore();
  await assertFails(updateDoc(doc(attacker, 'group_chats', 'private_group'), {
    members: ['alice', 'bob', 'mallory'],
    memberDetails: {mallory: {name: 'Mallory', role: 'admin'}},
  }));
});

test('a public community permits a narrow self-join but not metadata takeover', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'group_chats', 'public_group'), {
      createdById: 'alice', members: ['alice'], isPublic: true,
      memberDetails: {alice: {name: 'Alice', role: 'admin'}},
    });
  });
  const bob = env.authenticatedContext('bob').firestore();
  await assertSucceeds(updateDoc(doc(bob, 'group_chats', 'public_group'), {
    members: ['alice', 'bob'],
    memberDetails: {
      alice: {name: 'Alice', role: 'admin'},
      bob: {name: 'Bob', role: 'member'},
    },
  }));
  await assertFails(updateDoc(doc(bob, 'group_chats', 'public_group'), {
    members: ['alice', 'bob'],
    memberDetails: {
      alice: {name: 'Compromised', role: 'member'},
      bob: {name: 'Bob', role: 'admin'},
    },
  }));
});

test('post engagement updates only let a user toggle their own identity', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'posts', 'post1'), {
      authorId: 'creator', likedBy: [], likesCount: 0, bookmarkedBy: [], commentsCount: 0,
    });
  });
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(updateDoc(doc(alice, 'posts', 'post1'), {
    likedBy: ['alice'], likesCount: 1,
  }));
  await assertFails(updateDoc(doc(alice, 'posts', 'post1'), {
    likedBy: ['alice', 'bob'], likesCount: 2,
  }));
  await assertFails(updateDoc(doc(alice, 'posts', 'post1'), {
    authorId: 'alice',
  }));
});

test('client Firebase Storage writes are denied', async () => {
  const aliceStorage = env.authenticatedContext('alice').storage();
  const guestStorage = env.unauthenticatedContext().storage();
  await assertFails(uploadBytes(ref(aliceStorage, 'posts/alice/test.jpg'), Buffer.from('fake')));
  await assertFails(uploadBytes(ref(guestStorage, 'posts/guest/test.jpg'), Buffer.from('fake')));
});

test('a user may only add or remove themself from another profile followers', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users', 'bob'), {
      name: 'Bob',
    });
  });
  const alice = env.authenticatedContext('alice').firestore();
  const attacker = env.authenticatedContext('mallory').firestore();
  await assertSucceeds(updateDoc(doc(alice, 'users', 'bob'), {
    followers: ['alice'], followersCount: 1,
  }));
  await assertFails(updateDoc(doc(attacker, 'users', 'bob'), {
    followers: ['alice', 'charlie'], followersCount: 2,
  }));
  await assertSucceeds(updateDoc(doc(alice, 'users', 'bob'), {
    followers: [], followersCount: 0,
  }));
});

test('live messages cannot impersonate another author', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  await assertSucceeds(addDoc(collection(alice, 'liveStreams', 'room', 'messages'), {
    authorId: 'alice', text: 'hello',
  }));
  await assertFails(addDoc(collection(alice, 'liveStreams', 'room', 'messages'), {
    authorId: 'bob', text: 'forged',
  }));
});

test('FCM token documents are private and owner-bound', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const token = 'device-token-1';
  const tokenPath = `users/alice/fcmTokens/${token}`;
  await assertSucceeds(setDoc(doc(alice, tokenPath), {
    token,
    platform: 'android',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(alice, tokenPath)));
  await assertFails(getDoc(doc(bob, tokenPath)));
  await assertFails(setDoc(doc(alice, 'users/alice/fcmTokens/wrong-id'), {
    token,
    platform: 'android',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(bob, `users/alice/fcmTokens/${token}`), {
    token,
    platform: 'android',
    updatedAt: serverTimestamp(),
  }));
});

test('connection code reservations are owner-bound and immutable', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const guest = env.unauthenticatedContext().firestore();
  const codeRef = doc(alice, 'connectionCodes/ALICE-ABC123');

  await assertSucceeds(setDoc(codeRef, {
    uid: 'alice',
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(bob, 'connectionCodes/ALICE-ABC123')));
  await assertFails(setDoc(doc(bob, 'connectionCodes/BOB-ABC123'), {
    uid: 'alice',
    createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(bob, 'connectionCodes/ALICE-ABC123'), {
    uid: 'bob',
  }));
  await assertFails(getDoc(doc(guest, 'connectionCodes/ALICE-ABC123')));
});
