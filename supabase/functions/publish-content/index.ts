import { FieldValue } from "npm:firebase-admin@13.4.0/firestore";
import {
  canPublish,
  chunked,
  deterministicId,
  followerAllowsNotification,
} from "../_shared/contracts.ts";
import { firebase, verifyFirebaseUser } from "../_shared/firebase.ts";
import { errorResponse, HttpError, json, readJson, requiredString } from "../_shared/http.ts";
import { cleanText, deliverToUser } from "../_shared/notifications.ts";

const creatorEmails = new Set((Deno.env.get("CREATOR_EMAILS") ?? "")
  .split(",").map((email) => email.trim().toLowerCase()).filter(Boolean));

Deno.serve(async (request) => {
  try {
    const user = await verifyFirebaseUser(request);
    const body = await readJson(request);
    const post = body.post;
    if (!post || Array.isArray(post) || typeof post !== "object") {
      throw new HttpError(400, "invalid_request", "post is required.");
    }
    const input = post as Record<string, unknown>;
    const clientContentId = requiredString(body, "clientContentId", 100);
    const title = requiredString(input, "title", 300);
    const category = requiredString(input, "category", 40);
    const status = typeof input.status === "string" ? input.status : "approved";
    const db = firebase.db();
    const authorSnapshot = await db.collection("users").doc(user.uid).get();
    const author = authorSnapshot.data() ?? {};
    if (!canPublish(user.email, author.role, creatorEmails)) {
      throw new HttpError(403, "forbidden", "Your account cannot publish content.");
    }

    const authorName = cleanText(author.name ?? user.name, "CIE Daily creator", 80);
    const postRef = db.collection("posts").doc(
      deterministicId("content", user.uid, clientContentId),
    );
    const safePost = {
      ...input,
      authorId: user.uid,
      authorName,
      authorAvatar: author.photoUrl ?? null,
      authorEmail: user.email ?? null,
      author: {
        name: authorName, fullName: authorName,
        avatarUrl: author.photoUrl ?? null, email: user.email ?? null,
      },
      title, category, status,
      createdAt: FieldValue.serverTimestamp(),
      likesCount: 0, commentsCount: 0, likedBy: [], bookmarkedBy: [],
    };
    const created = await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(postRef);
      if (existing.exists) {
        if (existing.data()?.authorId !== user.uid) {
          throw new HttpError(409, "idempotency_conflict", "That publish request conflicts with existing content.");
        }
        return false;
      }
      transaction.create(postRef, safePost);
      return true;
    });

    if (status !== "approved") return json({ ok: true, postId: postRef.id, created, published: false, notified: 0 });
    const follows = await db.collection("follows").where("followingId", "==", user.uid).get();
    const followerIds = new Set<string>();
    follows.docs.forEach((doc) => {
      const uid = doc.data().followerId;
      if (typeof uid === "string" && uid !== user.uid) followerIds.add(uid);
    });
    if (Array.isArray(author.followers)) author.followers.forEach((uid) => {
      if (typeof uid === "string" && uid !== user.uid) followerIds.add(uid);
    });

    let notified = 0;
    const contentType = category.toLowerCase() === "reel" ? "reel" : "article";
    for (const chunk of chunked([...followerIds].slice(0, 5000), 20)) {
      const results = await Promise.all(chunk.map(async (uid) => {
        const follower = await db.collection("users").doc(uid).get();
        const preferences = follower.data()?.notificationPreferences ?? {};
        if (!followerAllowsNotification(preferences)) return 0;
        const result = await deliverToUser({
          uid,
          notificationId: `creator_${postRef.id}_${uid}`,
          title: `${authorName} published a new ${contentType}`,
          body: cleanText(title, "Tap to view the latest story.", 140),
          data: {
            type: contentType, contentType, contentId: postRef.id,
            articleId: contentType === "article" ? postRef.id : "",
          },
          record: {
            actorId: user.uid, actorName: authorName, actorAvatar: author.photoUrl ?? null,
            title: `${authorName} published a new ${contentType}`,
            body: cleanText(title, "Tap to view the latest story.", 140),
            type: "creator_content", contentType, contentId: postRef.id,
          },
        });
        return result.sent;
      }));
      notified += results.reduce((total, value) => total + value, 0);
    }
    return json({ ok: true, postId: postRef.id, created, published: true, notified });
  } catch (error) {
    return errorResponse(error);
  }
});
