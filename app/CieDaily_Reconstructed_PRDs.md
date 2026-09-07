# CieDaily — Reconstructed Product Requirement Documents (PRDs)

## Document Note
The PRDs in this document represent formalized product requirement documentation reconstructed from actual codebase features, commit records, user specifications, and implementation decisions.

---

# PRD 1 — User Authentication & Role-Based Access Control (RBAC)

## Objective
Provide secure identity verification for campus students, faculty, and administrators, maintaining strict role boundaries between students, verified content creators, and the system administrator.

## User Flow
1. User launches the app and views a 2.5s splash screen.
2. Unauthenticated users are routed to `/login` (Email/Password or Google Sign-In).
3. First-time users complete profile registration (`Full Name`, `Department`, `Year of Study`).
4. System automatically generates a unique 6-character connection code upon registration.

## Functional Requirements
- Support Email/Password registration and Google OAuth sign-in.
- Restrict Live Space broadcasting to Main Admin (`manasvig43@gmail.com`) and verified Creators.
- Restrict post publishing to verified Creators and Main Admin.

## Implementation Details
- Handled in `lib/features/auth/data/auth_repository.dart` and `lib/core/utils/role_utils.dart`.
- Firestore security rules enforce write authorization on user profiles and administrative actions.

---

# PRD 2 — Campus Feed & Content Drops (Articles & Reels)

## Objective
Deliver real-time campus news, student achievements, and multimedia updates via short-form video reels and long-form articles.

## User Flow
1. User opens the **Home** tab to view the infinite scroll post stream.
2. User taps an article card to navigate to `ArticleDetailScreen` with dark theme reading contrast.
3. User swipes to **Discover** tab to watch full-screen vertical campus reels.
4. User taps upvote or bookmark to save content to their personal profile.

## Functional Requirements
- Display author profile avatar, verified badge, title, estimated read time, and media payload.
- Automatically populate author identity on upload (preventing "Anonymous" fallback).
- Maintain persistent upvote and bookmark counts across app launches.

## Implementation Details
- Implemented in `lib/features/feed/` with `FirebaseFeedRepository` and `PostModel`.

---

# PRD 3 — Live Spaces & Audio Rooms

## Objective
Enable real-time interactive audio discussions, campus Q&A sessions, and live podcasts.

## User Flow
1. Users navigate to the **Spaces** tab to see active and upcoming live audio rooms.
2. Main Admin or Creators tap **Go Live** to launch an audio space.
3. Students tap any active space card to join as listeners with real-time WebRTC audio streaming.

## Functional Requirements
- Block standard Student accounts from initiating live audio streams (displaying clear guidance).
- Stream low-latency multi-party audio via LiveKit WebRTC engine.

## Implementation Details
- Managed in `lib/features/spaces/` powered by `livekit_client: ^2.3.1+hotfix.1`.

---

# PRD 4 — Private Student Connections & Connection Codes

## Objective
Facilitate safe, verified 1-to-1 peer connections across departments without exposing personal phone numbers.

## User Flow
1. Student views their unique Connection Code on their profile (e.g. `CIE-89X2`).
2. Student taps **Copy Code** and shares it with a classmate.
3. Classmate enters the code in **Chat** to establish a direct connection link.

## Functional Requirements
- Generate non-colliding unique connection codes stored on user documents.
- Support auto-accept or manual review of connection requests.

## Implementation Details
- Logic embedded in `lib/features/user/data/firebase_user_repository.dart`.

---

# PRD 5 — Private In-App 1-to-1 Chat System

## Objective
Provide real-time end-to-end peer messaging between connected students.

## User Flow
1. Student opens **Chat** tab to view active peer conversations.
2. Student taps a conversation thread to enter `ChatScreen`.
3. Messages send instantly with real-time delivery status.

## Functional Requirements
- Real-time message synchronization via Firestore snapshot listeners.
- Display partner avatar, online status, and timestamp.

## Implementation Details
- Implemented in `lib/features/social/` with `conversations` collection mapping.

---

# PRD 6 — Main Swipe Shell & Navigation

## Objective
Deliver fluid gesture-driven navigation between all 5 primary application tabs (Home, Discover, Spaces, Chat, Profile).

## User Flow
1. User taps bottom navigation icons or swipes horizontally anywhere on the screen.
2. Page transitions smoothly in exact index order (Home -> Discover -> Spaces -> Chat -> Profile).

## Functional Requirements
- Swipe gesture direction must perfectly match bottom navigation tab order.
- Maintain screen state during navigation without rebuild crashes or layout overflows.

## Implementation Details
- Built using `MainSwipeShell` in `lib/core/router/app_router.dart` with `StackFit.expand` constraints.
