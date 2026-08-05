# API Documentation

The backend relies on Supabase Postgres. We do not use a standard REST API middleware; instead we use PostgREST (provided by Supabase).

## Core Tables
- `users`: Core profile data (`id`, `email`, `department`, `year`)
- `admin_users`: Authorization table denoting which user IDs have admin dashboard access.
- `posts`: The Drops. Contains JSONB `content`, `author_id`, and computed `engagement_score`.
- `post_engagements`: Tracks analytical view times (`user_id`, `post_id`, `view_duration_seconds`).
- `conversations`: Chat sessions.
- `messages`: Chat messages with realtime subscriptions enabled.
- `notifications`: Push payload history.

## Edge Functions
- `sync_livekit_token`: Issues JWTs for users joining a LiveKit Space based on their authorization level.
