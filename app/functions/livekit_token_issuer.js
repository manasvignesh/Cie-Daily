'use strict';

const {AccessToken} = require('livekit-server-sdk');

async function issueLiveKitToken({apiKey, apiSecret, uid, roomName, role, displayName, ttl}) {
  const accessToken = new AccessToken(apiKey, apiSecret, {
    identity: uid,
    name: displayName,
    ttl,
    metadata: JSON.stringify({role}),
  });
  const canPublish = role !== 'listener';
  accessToken.addGrant({
    roomJoin: true,
    room: roomName,
    canSubscribe: true,
    canPublish,
    canPublishData: canPublish,
  });
  return accessToken.toJwt();
}

module.exports = {issueLiveKitToken};
