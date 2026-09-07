'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  chatPayload,
  chatRecipients,
  cleanText,
  processChatMessage,
} = require('../push_notifications');

test('chat recipients are limited to actual conversation participants', () => {
  const conversation = {participants: ['alice', 'bob']};
  assert.deepEqual(chatRecipients(conversation, 'alice', 'bob'), ['bob']);
  assert.deepEqual(chatRecipients(conversation, 'mallory', 'bob'), []);
  assert.deepEqual(chatRecipients(conversation, 'alice', 'mallory'), ['bob']);
});

test('chat notification payload contains safe routing strings', () => {
  const payload = chatPayload({
    conversationId: 'alice_bob',
    senderId: 'alice',
    senderName: 'Alice',
    content: 'Hello Bob',
  });
  assert.deepEqual(payload.notification, {title: 'Alice', body: 'Hello Bob'});
  assert.equal(payload.data.type, 'chat');
  assert.equal(payload.data.conversationId, 'alice_bob');
  for (const value of Object.values(payload.data)) assert.equal(typeof value, 'string');
});

test('notification text is bounded and has a safe fallback', () => {
  assert.equal(cleanText('   ', 'Fallback'), 'Fallback');
  const value = cleanText('x'.repeat(200), 'Fallback', 20);
  assert.equal(value.length, 20);
  assert.ok(value.endsWith('…'));
});

test('chat processing writes an inbox item and sends to registered devices', async () => {
  const writes = [];
  const notificationRef = {
    async get() { return {exists: false}; },
    async set(value) { writes.push(value); },
  };
  const tokenRef = {async delete() { throw new Error('should not delete valid token'); }};
  const db = {
    collection(name) {
      if (name === 'conversations') {
        return {doc() { return {async get() { return {
          exists: true,
          data: () => ({
            participants: ['alice', 'bob'],
            participantDetails: {alice: {name: 'Alice'}},
          }),
        }; }}; }};
      }
      if (name === 'notifications') return {doc() { return notificationRef; }};
      if (name === 'users') {
        return {doc() { return {collection() { return {async get() { return {
          docs: [{data: () => ({token: 'token-1'}), ref: tokenRef}],
        }; }}; }}; }};
      }
      throw new Error(`Unexpected collection ${name}`);
    },
  };
  const requests = [];
  const messaging = {
    async sendEachForMulticast(request) {
      requests.push(request);
      return {successCount: 1, responses: [{success: true}]};
    },
  };

  const result = await processChatMessage({
    db,
    messaging,
    conversationId: 'alice_bob',
    messageId: 'm1',
    message: {senderId: 'alice', receiverId: 'bob', content: 'Hi'},
  });

  assert.deepEqual(result, {recipients: 1, sent: 1});
  assert.equal(requests.length, 1);
  assert.deepEqual(requests[0].tokens, ['token-1']);
  assert.equal(requests[0].android.notification.channelId, 'cie_daily_messages');
  assert.equal(writes[0].userId, 'bob');
  assert.equal(writes.at(-1).pushStatus, 'sent');
});
