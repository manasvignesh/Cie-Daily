# Project Catalyst Engineering Constitution

## 1. Mobile First
Everything is designed for the phone first. Desktop exists only for admins.

## 2. Performance First
- Every screen should open in under **200ms**.
- Every animation should maintain **60 FPS** (120 FPS on supported devices).
- Every API should respond in under **300ms** under normal load.

## 3. Offline First
Users should always be able to:
- Open the app
- Read cached posts
- View saved posts
- Browse recent content
Even with no internet.

## 4. One Source of Truth
Never duplicate business logic. The Feed Orchestrator owns feed generation. No client-side feed logic.

## 5. Everything Is Versioned
Database migrations. API. Flutter models. Shared packages. Design tokens. Everything.

## 6. Feature Flags Before Features
No unfinished code reaches production without a feature flag.

## 7. Never Break Production
Every PR should pass:
- Static analysis
- Unit tests
- Widget tests
- Integration tests
before merging.

## 8. Consistency Over Cleverness
Readable code beats clever code. Simple architecture beats over-engineering.

## 9. Measure Before Optimizing
Don't optimize because it feels slow. Optimize because telemetry proves it.

## 10. Ship Weekly
A small improvement every week is better than one massive release every three months.

---

# Coding Standards

## Flutter
- Feature-first folder structure (not layer-first).
- Maximum widget length: ~200 lines before extracting smaller widgets.
- No business logic inside UI widgets.
- Repository pattern for data access.

## Backend (Supabase / Functions)
- Every endpoint documented.
- No direct SQL from the client except through approved Supabase policies.
- Every migration reversible.

## Admin (Next.js)
- Shared design tokens with the mobile app.
- Responsive layouts.
- Accessibility considered from the start.

---

# Success Metrics (North Star)
*Measure habits, not downloads.*

| Metric                 | Target                   |
| ---------------------- | ------------------------ |
| Daily Active Users     | >40% of registered users |
| Average Session Length | 6–10 minutes             |
| Posts Viewed / Session | 15–25                    |
| Daily Return Rate      | >35%                     |
| Space Attendance Rate  | >25% of invited users    |
| Save Rate              | >8% of posts viewed      |
| Share Rate             | >3% of posts viewed      |

---

# Version Roadmap

## v1.0 — Foundation (Current Focus)
- Authentication
- Feed
- Comments
- Reactions
- Bookmarks
- Inbox
- Spaces
- Admin Dashboard

## v1.1 — Refinement
- Better onboarding
- Search
- Notifications
- Feed tuning
- Performance improvements

## v1.2 — Intelligence
- AI summaries
- AI moderation
- Better recommendations
- Space reminders

## v2.0 — Multi-Campus
- Multiple colleges
- Organization management
- Campus switching
- Shared events
- Public conferences
