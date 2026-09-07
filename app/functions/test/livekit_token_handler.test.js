'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createLiveKitTokenHandler,
  createRateLimiter,
  resolveAuthorization,
} = require('../livekit_token_handler');

function request({method = 'POST', authorization, body = {}} = {}) {
  return {
    method,
    body,
    get: (name) => name.toLowerCase() === 'authorization' ? authorization : undefined,
  };
}

function response() {
  return {
    statusCode: null,
    body: null,
    headers: {},
    status(value) { this.statusCode = value; return this; },
    json(value) { this.body = value; return this; },
    set(name, value) { this.headers[name] = value; return this; },
  };
}

function fixture(overrides = {}) {
  const room = {
    status: 'live',
    roomName: 'room_123',
    hostId: 'host',
    isPublic: true,
    ...overrides.room,
  };
  const issued = [];
  return {
    issued,
    handler: createLiveKitTokenHandler({
      verifyIdToken: overrides.verifyIdToken ?? (async () => ({uid: 'alice', name: 'Alice'})),
      findRoom: overrides.findRoom ?? (async () => room),
      issueToken: async (claims) => { issued.push(claims); return 'signed-token'; },
      consumeRateLimit: overrides.consumeRateLimit ?? (() => true),
    }),
  };
}

test('eligible authenticated participant receives a room-scoped short token', async () => {
  const {handler, issued} = fixture();
  const res = response();
  await handler(request({authorization: 'Bearer valid', body: {
    spaceId: 'space_123', roomName: 'room_123', requestedRole: 'participant',
  }}), res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.token, 'signed-token');
  assert.deepEqual(issued[0], {
    uid: 'alice', roomName: 'room_123', role: 'participant',
    displayName: 'Alice', ttl: '5m',
  });
});

test('missing and invalid authentication are rejected', async () => {
  const missing = fixture();
  const missingRes = response();
  await missing.handler(request({body: {spaceId: 'space_123', roomName: 'room_123'}}), missingRes);
  assert.equal(missingRes.statusCode, 401);

  const invalid = fixture({verifyIdToken: async () => { throw new Error('invalid'); }});
  const invalidRes = response();
  await invalid.handler(request({authorization: 'Bearer bad', body: {spaceId: 'space_123', roomName: 'room_123'}}), invalidRes);
  assert.equal(invalidRes.statusCode, 401);
});

test('private room denies an unrelated authenticated user', async () => {
  const {handler} = fixture({room: {isPublic: false, members: ['bob']}});
  const res = response();
  await handler(request({authorization: 'Bearer valid', body: {spaceId: 'space_123', roomName: 'room_123'}}), res);
  assert.equal(res.statusCode, 403);
  assert.deepEqual(res.body, {error: 'not_authorized'});
});

test('missing room and invalid requested permission are safely rejected', async () => {
  const missing = fixture({findRoom: async () => null});
  const missingRes = response();
  await missing.handler(request({authorization: 'Bearer valid', body: {spaceId: 'space_123', roomName: 'room_123'}}), missingRes);
  assert.equal(missingRes.statusCode, 404);

  const invalid = fixture();
  const invalidRes = response();
  await invalid.handler(request({authorization: 'Bearer valid', body: {
    spaceId: 'space_123', roomName: 'room_123', requestedRole: 'admin',
  }}), invalidRes);
  assert.equal(invalidRes.statusCode, 400);
  assert.equal(invalid.issued.length, 0);
});

test('caller cannot escalate to host and banned users are denied', () => {
  assert.equal(resolveAuthorization({status: 'live', isPublic: true, hostId: 'bob'}, 'alice', 'host').role, 'participant');
  assert.deepEqual(
      resolveAuthorization({status: 'live', isPublic: true, bannedUserIds: ['alice']}, 'alice', 'participant'),
      {allowed: false, reason: 'not_authorized'},
  );
});

test('rate limiter applies a per-user rolling issuance cap', () => {
  let now = 1000;
  const consume = createRateLimiter(() => now);
  for (let i = 0; i < 10; i += 1) assert.equal(consume('alice'), true);
  assert.equal(consume('alice'), false);
  assert.equal(consume('bob'), true);
  now += 60_000;
  assert.equal(consume('alice'), true);
});
