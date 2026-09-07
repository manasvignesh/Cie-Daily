# CIE Daily production deployment

This document contains configuration names and deployment steps only. Never
commit credential values, signing files, or production `.env` files.

## 1. LiveKit token function

The HTTPS function is exported as `liveKitToken` in `functions/index.js`. It:

- requires a Firebase ID token in `Authorization: Bearer <token>`;
- verifies revocation through Firebase Admin;
- resolves an exact `liveStreams` document and verifies its stored room name;
- denies ended, missing, private, removed, or banned access;
- derives host/moderator/participant/listener status on the server;
- uses the verified Firebase UID as LiveKit identity;
- issues a room-scoped token with a five-minute TTL; and
- limits each user to ten issuance attempts per minute per warm instance.

Configure secrets interactively. Do not place their values in a file:

```bash
firebase functions:secrets:set LIVEKIT_API_KEY
firebase functions:secrets:set LIVEKIT_API_SECRET
```

Deploy the function only after verifying `.firebaserc` points to the intended
project:

```bash
firebase use cie-connect
firebase deploy --only functions:liveKitToken
```

Build the app with the deployed HTTPS function URL:

```bash
flutter build appbundle --release --dart-define=LIVEKIT_TOKEN_ENDPOINT=https://asia-south1-cie-connect.cloudfunctions.net/liveKitToken
```

Release startup deliberately stops with a safe configuration screen when
`LIVEKIT_TOKEN_ENDPOINT` is omitted.

## 2. Firebase rules and indexes

Run emulator tests before every rules deployment:

```bash
cd rules-tests
npm install
firebase emulators:exec --only firestore,storage --project demo-cie-daily "node --test security-rules.test.js"
```

Deploy rules and indexes only to the positively identified production project:

```bash
firebase use cie-connect
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 3. Firebase App Check

The app initializes the debug provider for debug builds and Play Integrity for
Android release builds. Apple release builds use App Attest with DeviceCheck
fallback. Before enforcement:

1. Register the Android app in Firebase App Check with Play Integrity.
2. Register release signing SHA-256 fingerprints.
3. Add local debug tokens shown by the SDK to the Firebase Console.
4. Monitor App Check metrics for valid production traffic.
5. Enforce App Check for Firestore, Authentication, Storage, and Functions only
   after valid traffic is confirmed.

The HTTPS token function does not yet set `enforceAppCheck: true`; enable that
option only after the console registration and metrics validation above.

## 4. Cloudinary unsigned preset

Client validation accepts JPG/JPEG/PNG/WebP images up to 10 MB and
MP4/MOV/M4V/WebM videos up to 100 MB. Uploads are streamed and request either
`cie-daily/image` or `cie-daily/video` as their folder.

In the Cloudinary Console, restrict unsigned preset `ety57u4p` to:

1. unsigned uploads only for the required application flow;
2. JPG, JPEG, PNG, WebP, MP4, MOV, M4V, and WebM formats;
3. a 10 MB image limit and 100 MB video limit;
4. fixed/allowed folders under `cie-daily/`;
5. no caller-controlled eager transformations;
6. only the transformations actually used by the product; and
7. overwrite and asset deletion disabled for unsigned callers.

Client checks are UX safeguards, not an abuse boundary. A future server-signed
upload endpoint should replace unsigned uploads when upload abuse becomes a
material risk.

## 5. Android release signing

`android/key.properties`, `*.jks`, and `*.keystore` are ignored by Git. Create
`android/key.properties` locally:

```properties
storeFile=C:\\secure\\path\\cie-daily-upload.jks
storePassword=SET_LOCALLY
keyAlias=SET_LOCALLY
keyPassword=SET_LOCALLY
```

The Gradle release build fails with a clear error when any value is absent.
# Notification backend prerequisite

Direct messages and creator-content publishing require the deployed Supabase
Edge Functions described in `SUPABASE_NOTIFICATION_BACKEND.md`. Configure
`CIE_TRUSTED_BACKEND_URL` as a Dart define when building. Do not deploy the
Firebase notification triggers or upgrade `cie-connect` from Spark for them.
