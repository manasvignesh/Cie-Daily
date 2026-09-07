'use strict';

const ALLOWED_REQUESTED_ROLES = new Set(['listener', 'participant', 'host']);
const TOKEN_TTL = '5m';
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX_REQUESTS = 10;

function sendJson(response, status, body) {
  response.status(status).json(body);
}

function bearerToken(header) {
  if (typeof header !== 'string') return null;
  const match = /^Bearer\s+([^\s]+)$/i.exec(header.trim());
  return match?.[1] ?? null;
}

function containsUser(value, uid) {
  return Array.isArray(value) && value.includes(uid);
}

function resolveAuthorization(data, uid, requestedRole) {
  if (!data || data.status !== 'live') return {allowed: false, reason: 'not_found'};

  const banned = [
    ...(Array.isArray(data.bannedUserIds) ? data.bannedUserIds : []),
    ...(Array.isArray(data.removedUserIds) ? data.removedUserIds : []),
  ];
  if (banned.includes(uid)) return {allowed: false, reason: 'not_authorized'};

  const isHost = data.hostId === uid;
  const isModerator = containsUser(data.moderatorIds, uid);
  const isMember = containsUser(data.members, uid) ||
      containsUser(data.allowedUserIds, uid) ||
      containsUser(data.participants, uid);
  const isPublic = data.isPublic !== false;
  if (!isPublic && !isHost && !isModerator && !isMember) {
    return {allowed: false, reason: 'not_authorized'};
  }

  let role = isHost ? 'host' : (isModerator ? 'moderator' : 'participant');
  if (requestedRole === 'listener' && !isHost && !isModerator) role = 'listener';
  return {allowed: true, role};
}

function createRateLimiter(now = () => Date.now()) {
  const buckets = new Map();
  return function consume(uid) {
    const current = now();
    const prior = buckets.get(uid);
    if (!prior || current - prior.startedAt >= RATE_LIMIT_WINDOW_MS) {
      buckets.set(uid, {startedAt: current, count: 1});
      return true;
    }
    if (prior.count >= RATE_LIMIT_MAX_REQUESTS) return false;
    prior.count += 1;
    return true;
  };
}

function createLiveKitTokenHandler({verifyIdToken, findRoom, issueToken, consumeRateLimit}) {
  return async function liveKitTokenHandler(request, response) {
    if (request.method !== 'POST') {
      response.set('Allow', 'POST');
      return sendJson(response, 405, {error: 'method_not_allowed'});
    }

    const token = bearerToken(request.get('authorization'));
    if (!token) return sendJson(response, 401, {error: 'unauthenticated'});

    let decoded;
    try {
      decoded = await verifyIdToken(token);
    } catch (_) {
      return sendJson(response, 401, {error: 'unauthenticated'});
    }
    const uid = decoded?.uid;
    if (typeof uid !== 'string' || uid.length === 0) {
      return sendJson(response, 401, {error: 'unauthenticated'});
    }
    if (!consumeRateLimit(uid)) {
      return sendJson(response, 429, {error: 'rate_limited'});
    }

    const spaceId = request.body?.spaceId;
    const roomName = request.body?.roomName;
    const requestedRole = request.body?.requestedRole ?? 'participant';
    if (typeof spaceId !== 'string' || spaceId.length < 1 || spaceId.length > 128 ||
        !/^[A-Za-z0-9_-]+$/.test(spaceId) ||
        typeof roomName !== 'string' || roomName.length < 1 || roomName.length > 128 ||
        !/^[A-Za-z0-9_-]+$/.test(roomName)) {
      return sendJson(response, 400, {error: 'invalid_request'});
    }
    if (!ALLOWED_REQUESTED_ROLES.has(requestedRole)) {
      return sendJson(response, 400, {error: 'invalid_request'});
    }

    try {
      const room = await findRoom(spaceId, roomName);
      if (!room) return sendJson(response, 404, {error: 'room_not_found'});
      const authorization = resolveAuthorization(room, uid, requestedRole);
      if (!authorization.allowed) {
        const status = authorization.reason === 'not_found' ? 404 : 403;
        return sendJson(response, status, {error: authorization.reason});
      }

      const issued = await issueToken({
        uid,
        roomName,
        role: authorization.role,
        displayName: typeof decoded.name === 'string' ? decoded.name.slice(0, 80) : undefined,
        ttl: TOKEN_TTL,
      });
      return sendJson(response, 200, {token: issued, expiresInSeconds: 300});
    } catch (_) {
      return sendJson(response, 503, {error: 'service_unavailable'});
    }
  };
}

module.exports = {
  TOKEN_TTL,
  bearerToken,
  createLiveKitTokenHandler,
  createRateLimiter,
  resolveAuthorization,
};
