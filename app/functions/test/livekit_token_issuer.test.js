'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {issueLiveKitToken} = require('../livekit_token_issuer');

function decodePayload(jwt) {
  return JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString('utf8'));
}

test('issued token uses verified identity, five-minute TTL, and exact room grant', async () => {
  const jwt = await issueLiveKitToken({
    apiKey: 'test-key',
    apiSecret: 'test-secret-that-is-long-enough-for-hmac',
    uid: 'firebase-uid-123',
    roomName: 'room_123',
    role: 'participant',
    displayName: 'Student',
    ttl: '5m',
  });
  const payload = decodePayload(jwt);
  assert.equal(payload.sub, 'firebase-uid-123');
  assert.equal(payload.video.room, 'room_123');
  assert.equal(payload.video.roomJoin, true);
  assert.equal(payload.video.canPublish, true);
  assert.equal(payload.video.canSubscribe, true);
  assert.equal(payload.exp - payload.nbf, 300);
  assert.deepEqual(JSON.parse(payload.metadata), {role: 'participant'});
});

test('listener token cannot publish media or data', async () => {
  const jwt = await issueLiveKitToken({
    apiKey: 'test-key',
    apiSecret: 'test-secret-that-is-long-enough-for-hmac',
    uid: 'listener-uid',
    roomName: 'room_123',
    role: 'listener',
    ttl: '5m',
  });
  const payload = decodePayload(jwt);
  assert.equal(payload.video.canPublish, false);
  assert.equal(payload.video.canPublishData, false);
  assert.equal(payload.video.roomAdmin ?? false, false);
});
