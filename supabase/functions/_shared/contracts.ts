import { createHash } from "node:crypto";
import { HttpError } from "./http.ts";

export function deterministicId(scope: string, uid: string, clientId: string): string {
  return createHash("sha256").update(`${scope}:${uid}:${clientId}`).digest("hex");
}

export function chunked<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

export function directRecipient(participants: unknown, senderUid: string): string {
  if (!Array.isArray(participants)) {
    throw new HttpError(403, "not_a_participant", "You cannot send to this conversation.");
  }
  const members = participants.filter((value): value is string =>
    typeof value === "string" && value.length > 0
  );
  if (members.length !== 2 || !members.includes(senderUid)) {
    throw new HttpError(403, "not_a_participant", "You cannot send to this conversation.");
  }
  return members.find((uid) => uid !== senderUid)!;
}

export function rejectsSenderClaim(claimedSender: unknown, verifiedUid: string): boolean {
  return claimedSender != null && claimedSender !== verifiedUid;
}

export function canPublish(
  email: unknown,
  profileRole: unknown,
  configuredCreatorEmails: Set<string>,
): boolean {
  const normalized = typeof email === "string" ? email.toLowerCase() : "";
  return normalized === "manasvig43@gmail.com" ||
    configuredCreatorEmails.has(normalized) ||
    ["admin", "creator"].includes(String(profileRole ?? "").toLowerCase());
}

export function followerAllowsNotification(preferences: unknown): boolean {
  if (!preferences || Array.isArray(preferences) || typeof preferences !== "object") return true;
  const value = preferences as Record<string, unknown>;
  return value.enabled !== false && value.creatorContent !== false;
}

export function sharedContentPreview(content: string): string {
  const value = content.trim();
  if (value.startsWith("[SHARED_POST|")) {
    const parts = value.split("|");
    const category = (parts[2] ?? "").trim().toLowerCase();
    const title = (parts[3] ?? "").replace(/\s+/g, " ").trim();
    const label = category.includes("reel") ? "Shared a reel" : "Shared an article";
    return title ? `${label} · ${title}` : label;
  }
  const legacy = /Shared\s+(Reel|Article):\s*"([^"]*)"/i.exec(value);
  if (legacy) {
    const label = legacy[1].toLowerCase() === "reel" ? "Shared a reel" : "Shared an article";
    return legacy[2] ? `${label} · ${legacy[2].trim()}` : label;
  }
  return value;
}
