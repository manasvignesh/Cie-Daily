# CIE Daily trusted notification backend

## Architecture

CIE Daily continues to use Firebase Authentication, Cloud Firestore and Firebase Cloud Messaging. Supabase is only the trusted Edge Function runtime; no application data or user accounts are migrated to Supabase.

```text
Flutter app -> Firebase ID token -> Supabase Edge Function
            -> Firebase Admin verification -> Firestore + FCM HTTP v1
```

The Firebase project remains `cie-connect` on the Spark plan. The notification Firebase Cloud Functions in `app/functions` are retained only as rollback/reference code and must not be deployed after the Edge Functions are active.

## Functions

- `send-message` validates a fresh Firebase ID token, atomically verifies conversation membership, derives the recipient, creates a deterministic message, updates unread metadata, and sends the existing chat payload to every active recipient device.
- `publish-content` validates the publisher, writes the existing post schema, resolves existing Firestore followers and preferences, and sends deduplicated article/reel notifications. Drafts never notify.

Both functions have Supabase gateway JWT validation disabled because the bearer token is a Firebase ID token. Each function performs explicit Firebase Admin verification, including revoked-token checks.

## Required Supabase secrets

Set these only through Supabase secrets. Never prefix them with `VITE_`, add them to Flutter, or commit values.

- `FIREBASE_PROJECT_ID` (`cie-connect`)
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `CREATOR_EMAILS` (comma-separated allowlist, excluding the built-in primary admin if desired)

The service account needs only the Firebase Admin permissions required to verify users, read/write the listed Firestore collections, and send Firebase Cloud Messaging HTTP v1 requests. Rotate it if its private key is ever exposed.

## Deploy

Authenticate the Supabase CLI, link the existing project, set secrets, and deploy:

```powershell
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase secrets set FIREBASE_PROJECT_ID=cie-connect FIREBASE_SERVICE_ACCOUNT_JSON=... CREATOR_EMAILS=...
npx supabase functions deploy send-message --no-verify-jwt
npx supabase functions deploy publish-content --no-verify-jwt
```

Do not put secret values in shell history in shared environments; prefer the Supabase dashboard secret editor or a temporary, ignored environment file.

Build the app with the public function base URL:

```powershell
flutter build appbundle --release --dart-define=CIE_TRUSTED_BACKEND_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1
```

The URL is not privileged. Firebase credentials remain exclusively in Supabase.

## Security and retry behavior

- Sender/publisher UIDs come only from verified Firebase tokens.
- Conversation recipients come only from Firestore membership; the client cannot select a push recipient.
- Message document IDs hash `verified UID + clientMessageId`. HTTP retries reuse the same client ID and cannot create a second message or unread increment.
- Notification documents use `messageId + recipientUid` or `postId + recipientUid`, with a Firestore lease and terminal state, preventing normal request retries from issuing a second push.
- Direct client writes to direct-message documents and new posts are denied by Firestore rules after this backend is deployed.
- Message bodies are never written to server logs.
- Message requests are capped at 4,000 characters and rate-limited through Firestore.
- Unregistered device tokens are deleted after FCM reports them invalid.

FCM is an external at-least-once system. A process crash in the tiny interval after FCM accepts a push but before Firestore records `sent` can theoretically redeliver; notification IDs and Android handling minimize this unavoidable distributed-system edge case.

## Local validation

```powershell
npx -y deno test --allow-env --allow-net supabase/functions/tests/contracts_test.ts
npx -y deno check supabase/functions/send-message/index.ts supabase/functions/publish-content/index.ts
cd app
flutter test
firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
flutter analyze
```

For local function invocation, use a real short-lived Firebase ID token from a test account and local Firebase Admin credentials. Never save either in fixtures.

## Production verification

1. On device A, send `Hi` to device B while B is using another app. Confirm the system notification shows A's current display name and `Hi`.
2. Tap it and confirm the exact conversation opens.
3. Terminate CIE Daily on B, repeat, then tap the new notification.
4. Publish approved content from a creator followed by B. Confirm its notification opens the exact article or reel.
5. Confirm a draft creates no notification, duplicate requests create no duplicate messages/push records, and invalid tokens disappear from `users/{uid}/fcmTokens`.

Do not mark delivery production-verified until these physical-device checks pass.

## Debugging

Supabase logs intentionally contain only operation IDs, safe error codes, and delivery counts. For a failed request, correlate the function invocation with Firestore notification `pushStatus` and `pushUpdatedAt`. Never add ID tokens, service accounts, FCM tokens, message bodies, or private content to logs.
