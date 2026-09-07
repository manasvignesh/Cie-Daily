import {
  canPublish,
  chunked,
  deterministicId,
  directRecipient,
  followerAllowsNotification,
  rejectsSenderClaim,
  sharedContentPreview,
} from "../_shared/contracts.ts";

function assert(condition: unknown, message = "assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("message id is stable per authenticated sender and client id", () => {
  const first = deterministicId("message", "user-a", "request-123");
  assert(first === deterministicId("message", "user-a", "request-123"));
  assert(first !== deterministicId("message", "user-b", "request-123"));
});

Deno.test("conversation derives recipient and rejects a non-participant", () => {
  assert(directRecipient(["user-a", "user-b"], "user-a") === "user-b");
  let rejected = false;
  try {
    directRecipient(["user-a", "user-b"], "attacker");
  } catch {
    rejected = true;
  }
  assert(rejected);
});

Deno.test("forged sender claim is rejected", () => {
  assert(rejectsSenderClaim("attacker", "real-user"));
  assert(!rejectsSenderClaim("real-user", "real-user"));
  assert(!rejectsSenderClaim(undefined, "real-user"));
});

Deno.test("publisher authorization and follower preferences are enforced", () => {
  assert(canPublish("creator@example.com", null, new Set(["creator@example.com"])));
  assert(canPublish("person@example.com", "creator", new Set()));
  assert(!canPublish("student@example.com", "student", new Set()));
  assert(followerAllowsNotification(undefined));
  assert(!followerAllowsNotification({ creatorContent: false }));
  assert(!followerAllowsNotification({ enabled: false }));
});

Deno.test("large follower sets are split into bounded batches", () => {
  const input = Array.from({ length: 1001 }, (_, index) => index);
  const output = chunked(input, 20);
  assert(output.length === 51);
  assert(output[50].length === 1);
});

Deno.test("shared-content conversation previews preserve the mobile contract", () => {
  assert(
    sharedContentPreview("[SHARED_POST|post-1|Article|A useful story|img]") ===
      "Shared an article · A useful story",
  );
  assert(sharedContentPreview("Hello") === "Hello");
});
