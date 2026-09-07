# CieDaily — Technical Architecture Specification

## 1. System Overview

**CieDaily** is a mobile-first campus discovery and real-time social networking application engineered using **Flutter (Dart)** for cross-platform clients, **Cloud Firestore** for real-time document storage, **Firebase Authentication** for user identity, and **LiveKit WebRTC** for real-time audio rooms ("Spaces").

```
+-------------------------------------------------------------------------+
|                              FLUTTER UI                                 |
| (MainSwipeShell / GoRouter 14.8.1 / AMOLED Dark Glassmorphism Theme)    |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                           RIVERPOD PROVIDERS                            |
| (AuthProvider / FeedProvider / SocialProvider / LiveKitProvider / Chat) |
+------------------+-----------------+-------------------+----------------+
                   |                 |                   |
                   v                 v                   v
+--------------------+   +-------------------+   +------------------------+
| FIREBASE AUTH      |   | CLOUD FIRESTORE   |   | LIVEKIT WEBRTC ENGINE  |
| (Google & Email)   |   | (Security Rules)  |   | (Real-time Live Audio) |
+--------------------+   +-------------------+   +------------------------+
```

---

## 2. Frontend Layer (Flutter Client)

- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: `flutter_riverpod` (v2.6.1) utilizing declarative `StreamProvider`, `StateNotifierProvider`, and `FutureProvider` paradigms.
- **Routing**: `go_router` (v14.8.1) with `ShellRoute` tab preservation, custom swipe gesture recognition (`GestureDetector` horizontal drag velocity detection), and `AnimatedSwitcher` page transitions.
- **Typography & Theme**: Custom AMOLED dark design system (`#000000` canvas, `#0D0D14` & `#13131C` elevation surfaces, `#FF5A1F` brand accent) powered by `google_fonts` (`Outfit` headlines & `Inter` body text).

---

## 3. Backend & Storage Layer (Firebase)

- **Authentication**: Firebase Authentication supporting Email/Password sign-in, account creation, and Google Sign-In (`google_sign_in: ^6.3.0`) configured with `serverClientId`.
- **Database**: Cloud Firestore in Datastore mode. Data operations enforce optimistic UI updates paired with reactive `StreamProvider` listeners.
- **Rules & Governance**: Declarative `firestore.rules` enforcing document-level ownership, Role-Based Access Control (RBAC), and immutability of system records.

---

## 4. Security & Role-Based Access Control (RBAC)

CieDaily enforces three explicit user roles:
1. **Main Admin** (`manasvig43@gmail.com`): Full system read/write/moderation authority, post deletion, role assignment, and live broadcasting permissions.
2. **Creators**: Authorized student and faculty content publishers verified by Main Admin. Granted content post creation (Articles & Reels) and Live Space hosting privileges.
3. **Students**: Standard campus users. Granted connection code generation, 1-to-1 connection messaging, content bookmarks/upvotes, and Live Space listening permissions.

### Firestore Security Rule Implementation (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isMainAdmin() {
      return isAuthenticated() && request.auth.token.email == 'manasvig43@gmail.com';
    }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isMainAdmin() || request.auth.uid == userId;
    }

    match /posts/{postId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isMainAdmin() || request.auth.uid == resource.data.authorId;
    }

    match /follows/{followId} {
      allow read: if isAuthenticated();
      allow create, delete: if isAuthenticated() && request.auth.uid == request.resource.data.followerId;
    }
  }
}
```

---

## 5. Database Schema Architecture

### `/users/{userId}` Document Model
```json
{
  "uid": "STRING (Primary Key)",
  "email": "STRING",
  "name": "STRING",
  "bio": "STRING",
  "department": "STRING",
  "yearOfStudy": "NUMBER",
  "photoUrl": "STRING (Nullable)",
  "connectionCode": "STRING (Unique 6-char alpha-numeric)",
  "followersCount": "NUMBER",
  "followingCount": "NUMBER",
  "following": "ARRAY<STRING>",
  "autoAcceptRequests": "BOOLEAN"
}
```

### `/posts/{postId}` Document Model
```json
{
  "id": "STRING",
  "title": "STRING",
  "content": "STRING",
  "category": "STRING ('article' | 'reel')",
  "imageUrl": "STRING (Nullable)",
  "videoUrl": "STRING (Nullable)",
  "authorId": "STRING",
  "authorName": "STRING",
  "authorAvatar": "STRING (Nullable)",
  "authorEmail": "STRING",
  "estimatedReadTime": "NUMBER",
  "upvotesCount": "NUMBER",
  "commentsCount": "NUMBER",
  "createdAt": "TIMESTAMP"
}
```

### `/conversations/{conversationId}` Document Model
```json
{
  "id": "STRING",
  "participants": "ARRAY<STRING> [uid1, uid2]",
  "participantDetails": "MAP<uid, {name, photoUrl}>",
  "lastMessage": "STRING",
  "lastMessageTimestamp": "TIMESTAMP"
}
```

---

## 6. Android Build & Release Pipeline

- **Application ID**: `com.ciedaily.app`
- **Compile SDK**: 36 | **Min SDK**: 24 | **Target SDK**: 36
- **Gradle Build System**: Kotlin DSL (`build.gradle.kts` & `settings.gradle.kts`)
- **Release Signing**: Production 2048-bit RSA Keystore (`android/app/upload-keystore.jks`) managed via `android/key.properties`.
- **Packaging Format**: Android App Bundle (`app-release.aab`) compiled with version configuration `versionCode: 10` / `versionName: 1.0.9`.
