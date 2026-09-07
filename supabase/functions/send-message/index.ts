import { FieldValue } from "npm:firebase-admin@13.4.0/firestore";
import {
  deterministicId,
  directRecipient,
  rejectsSenderClaim,
  sharedContentPreview,
} from "../_shared/contracts.ts";
import { firebase, verifyFirebaseUser } from "../_shared/firebase.ts";
import { errorResponse, HttpError, json, readJson, requiredString } from "../_shared/http.ts";
import { cleanText, deliverToUser, enforceRateLimit } from "../_shared/notifications.ts";

Deno.serve(async (request) => {
  try {
    const user = await verifyFirebaseUser(request);
    const body = await readJson(request);
    if (rejectsSenderClaim(body.senderId, user.uid)) {
      throw new HttpError(403, "sender_impersonation", "The sender does not match your account.");
    }
    const conversationId = requiredString(body, "conversationId", 200);
    const content = requiredString(body, "content", 4000);
    const clientMessageId = requiredString(body, "clientMessageId", 100);
    if (!/^[A-Za-z0-9_-]{8,100}$/.test(clientMessageId)) {
      throw new HttpError(400, "invalid_request", "clientMessageId is invalid.");
    }
    await enforceRateLimit(user.uid);

    const db = firebase.db();
    const conversationRef = db.collection("conversations").doc(conversationId);
    const senderRef = db.collection("users").doc(user.uid);
    const messageId = deterministicId("message", user.uid, clientMessageId);
    const messageRef = conversationRef.collection("messages").doc(messageId);
    const senderSnapshot = await senderRef.get();

    const transactionResult = await db.runTransaction(async (transaction) => {
      const [conversationSnapshot, existing] = await Promise.all([
        transaction.get(conversationRef),
        transaction.get(messageRef),
      ]);
      if (!conversationSnapshot.exists) {
        throw new HttpError(404, "conversation_not_found", "This conversation is no longer available.");
      }
      const conversation = conversationSnapshot.data()!;
      const recipientUid = directRecipient(conversation.participants, user.uid);
      if (existing.exists) {
        if (existing.data()?.senderId !== user.uid) throw new HttpError(409, "idempotency_conflict", "That message request conflicts with an existing message.");
        return { created: false, recipientUid, conversation };
      }
      transaction.create(messageRef, {
        senderId: user.uid,
        receiverId: recipientUid,
        content,
        timestamp: FieldValue.serverTimestamp(),
        isRead: false,
      });
      transaction.update(conversationRef, {
        lastMessage: cleanText(sharedContentPreview(content), "Sent a message", 160),
        lastMessageSenderId: user.uid,
        lastMessageTimestamp: FieldValue.serverTimestamp(),
        [`unreadCounts.${recipientUid}`]: FieldValue.increment(1),
      });
      return { created: true, recipientUid, conversation };
    });
    const { created, recipientUid, conversation } = transactionResult;

    const [senderData, recipientData] = await Promise.all([
      Promise.resolve(senderSnapshot.data() ?? {}),
      db.collection("users").doc(recipientUid).get().then((value) => value.data() ?? {}),
    ]);
    const participant = conversation.participantDetails?.[user.uid] ?? {};
    const senderName = cleanText(senderData.name ?? participant.name ?? user.name, "New message", 80);
    const previewsEnabled = recipientData.notificationPreferences?.messagePreviews !== false;
    const notification = await deliverToUser({
      uid: recipientUid,
      notificationId: `chat_${conversationId}_${messageId}_${recipientUid}`,
      title: senderName,
      body: previewsEnabled ? cleanText(content, "Sent you a message", 140) : "Sent you a message",
      data: {
        type: "chat", contentType: "chat", contentId: conversationId,
        conversationId, messageId, senderId: user.uid,
      },
      record: {
        actorId: user.uid, actorName: senderName, title: senderName,
        body: previewsEnabled ? cleanText(content, "Sent you a message", 140) : "Sent you a message",
        type: "chat", contentType: "chat", contentId: conversationId,
      },
    });

    return json({ ok: true, messageId, created, pushSent: notification.sent });
  } catch (error) {
    return errorResponse(error);
  }
});
