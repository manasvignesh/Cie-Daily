import { FieldValue, Timestamp } from "npm:firebase-admin@13.4.0/firestore";
import { firebase } from "./firebase.ts";
import { HttpError } from "./http.ts";
import { directRecipient } from "./contracts.ts";

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function tokenSuffix(token: string): string {
  return token.length > 6 ? token.slice(-6) : "short";
}

export function cleanText(value: unknown, fallback: string, max: number): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) return fallback;
  return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

export { directRecipient };

export async function enforceRateLimit(uid: string, limit = 30): Promise<void> {
  const db = firebase.db();
  const ref = db.collection("backendRateLimits").doc(`message_${uid}`);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const now = Timestamp.now();
    const previous = snapshot.data();
    const started = previous?.windowStartedAt instanceof Timestamp
      ? previous.windowStartedAt.toMillis()
      : 0;
    const withinWindow = now.toMillis() - started < 60_000;
    const count = withinWindow ? Number(previous?.count ?? 0) : 0;
    if (count >= limit) throw new HttpError(429, "rate_limited", "Too many messages. Please wait a moment.");
    transaction.set(ref, {
      count: count + 1,
      windowStartedAt: withinWindow ? previous!.windowStartedAt : now,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

type Delivery = {
  uid: string;
  notificationId: string;
  title: string;
  body: string;
  data: Record<string, string>;
  record: Record<string, unknown>;
};

export async function deliverToUser(input: Delivery): Promise<{ sent: number; duplicate: boolean }> {
  const db = firebase.db();
  const ref = db.collection("notifications").doc(input.notificationId);
  const claimed = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const existing = snapshot.data();
    if (existing?.pushStatus === "sent" || existing?.pushStatus === "no_devices") return false;
    const lease = existing?.pushLeaseAt instanceof Timestamp ? existing.pushLeaseAt.toMillis() : 0;
    if (existing?.pushStatus === "sending" && Date.now() - lease < 90_000) return false;
    transaction.set(ref, {
      ...input.record,
      userId: input.uid,
      isRead: existing?.isRead === true,
      pushStatus: "sending",
      pushLeaseAt: FieldValue.serverTimestamp(),
      createdAt: existing?.createdAt ?? FieldValue.serverTimestamp(),
      pushUpdatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  });
  if (!claimed) return { sent: 0, duplicate: true };

  const tokens = await db.collection("users").doc(input.uid).collection("fcmTokens").get();
  const docs = tokens.docs.filter((doc) => {
    const data = doc.data();
    // The owning uid is established by the parent Firestore path. Keep legacy
    // token records (created before the uid field was added) deliverable.
    return typeof data.token === "string" && data.token.length > 0;
  });
  console.log("FCM recipient tokens resolved", {
    uid: input.uid,
    tokenDocumentCount: tokens.size,
    eligibleTokenCount: docs.length,
    tokenSuffixes: docs.map((doc) => tokenSuffix(doc.data().token)),
  });
  if (!docs.length) {
    await ref.set({ pushStatus: "no_devices", pushUpdatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { sent: 0, duplicate: false };
  }

  let sent = 0;
  try {
    for (let index = 0; index < docs.length; index += 500) {
      const chunk = docs.slice(index, index + 500);
      let pending = chunk;
      // Retry only tokens that FCM explicitly reported as failed. Successful
      // devices are never included in the retry, avoiding duplicate pushes.
      for (let attempt = 0; attempt < 2 && pending.length; attempt++) {
        const response = await firebase.messaging().sendEachForMulticast({
          tokens: pending.map((doc) => doc.data().token),
          notification: { title: input.title, body: input.body },
          data: input.data,
          android: {
            priority: "high",
            notification: { channelId: "cie_daily_messages", sound: "default", color: "#FF5A1F" },
          },
          apns: { payload: { aps: { sound: "default" } } },
        });
        sent += response.successCount;
        const retryable: typeof pending = [];
        const removals: Promise<unknown>[] = [];
        response.responses.forEach((result, resultIndex) => {
          if (result.success) return;
          const tokenDoc = pending[resultIndex];
          if (invalidTokenCodes.has(result.error?.code ?? "")) {
            removals.push(tokenDoc.ref.delete());
          } else if (attempt === 0) {
            retryable.push(tokenDoc);
          }
        });
        await Promise.allSettled(removals);
        pending = retryable;
        if (pending.length) await new Promise((resolve) => setTimeout(resolve, 200));
      }
    }
    await ref.set({
      pushStatus: sent > 0 ? "sent" : "failed",
      pushRetryable: sent === 0,
      pushUpdatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log("FCM delivery completed", {
      uid: input.uid,
      tokenDocumentCount: docs.length,
      successCount: sent,
      failureCount: Math.max(0, docs.length - sent),
    });
    return { sent, duplicate: false };
  } catch (error) {
    await ref.set({ pushStatus: "failed", pushRetryable: true, pushUpdatedAt: FieldValue.serverTimestamp() }, { merge: true });
    console.error("FCM delivery failed", { notificationId: input.notificationId, code: (error as { code?: string })?.code ?? "unknown" });
    return { sent: 0, duplicate: false };
  }
}
