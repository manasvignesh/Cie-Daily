'use strict';

const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {onRequest} = require('firebase-functions/v2/https');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {logger} = require('firebase-functions');
const {defineSecret} = require('firebase-functions/params');
const {
  createLiveKitTokenHandler,
  createRateLimiter,
} = require('./livekit_token_handler');
const {issueLiveKitToken} = require('./livekit_token_issuer');
const {
  processChatMessage,
  processPublishedPost,
} = require('./push_notifications');

initializeApp();

const liveKitApiKey = defineSecret('LIVEKIT_API_KEY');
const liveKitApiSecret = defineSecret('LIVEKIT_API_SECRET');
const consumeRateLimit = createRateLimiter();

async function findRoom(spaceId, roomName) {
  const snapshot = await getFirestore().collection('liveStreams').doc(spaceId).get();
  if (!snapshot.exists) return null;
  const data = snapshot.data();
  const storedRoomName = data.roomName ?? data.roomId ?? data.room_id ?? data.room;
  return storedRoomName === roomName ? data : null;
}

async function issueToken({uid, roomName, role, displayName, ttl}) {
  return issueLiveKitToken({
    apiKey: liveKitApiKey.value(),
    apiSecret: liveKitApiSecret.value(),
    uid,
    roomName,
    role,
    displayName,
    ttl,
  });
}

const handler = createLiveKitTokenHandler({
  verifyIdToken: (token) => getAuth().verifyIdToken(token, true),
  findRoom,
  issueToken,
  consumeRateLimit,
});

exports.liveKitToken = onRequest(
    {
      region: 'asia-south1',
      secrets: [liveKitApiKey, liveKitApiSecret],
      timeoutSeconds: 15,
      memory: '256MiB',
      cors: false,
    },
    handler,
);

exports.notifyDirectMessage = onDocumentCreated(
    {
      document: 'conversations/{conversationId}/messages/{messageId}',
      region: 'asia-south1',
      retry: true,
    },
    async (event) => {
      try {
        const result = await processChatMessage({
          db: getFirestore(),
          messaging: getMessaging(),
          conversationId: event.params.conversationId,
          messageId: event.params.messageId,
          message: event.data?.data(),
        });
        logger.info('Direct-message notification handled', {
          conversationId: event.params.conversationId,
          messageId: event.params.messageId,
          recipients: result.recipients,
          sent: result.sent,
        });
      } catch (error) {
        logger.error('Direct-message notification failed', {
          conversationId: event.params.conversationId,
          messageId: event.params.messageId,
          code: error?.code ?? 'unknown',
        });
        throw error;
      }
    },
);

exports.notifyCreatorPost = onDocumentCreated(
    {
      document: 'posts/{postId}',
      region: 'asia-south1',
      retry: true,
    },
    async (event) => {
      try {
        const result = await processPublishedPost({
          db: getFirestore(),
          messaging: getMessaging(),
          postId: event.params.postId,
          post: event.data?.data(),
        });
        logger.info('Creator-content notification handled', {
          postId: event.params.postId,
          recipients: result.recipients,
          sent: result.sent,
        });
      } catch (error) {
        logger.error('Creator-content notification failed', {
          postId: event.params.postId,
          code: error?.code ?? 'unknown',
        });
        throw error;
      }
    },
);
