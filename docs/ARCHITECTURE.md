# System Architecture

## Client (Flutter)
- **State Management**: Riverpod (StreamProviders for realtime, StateNotifiers for mutations)
- **Routing**: GoRouter (ShellRoutes for bottom nav, nested redirects for auth states)
- **Offline Storage**: Hive/Isar
- **WebRTC**: LiveKit Client

## Admin Dashboard (Next.js)
- **Framework**: Next.js (App Router, Server Components)
- **Styling**: Tailwind CSS
- **Deployment**: Vercel

## Backend (Supabase)
- **Database**: PostgreSQL
- **Auth**: Supabase Auth (Email/OTP)
- **Realtime**: Postgres CDC via WebSockets
- **Storage**: Supabase Storage

## Realtime Audio/Video (LiveKit)
- **Signaling**: LiveKit Server (Cloud or Self-hosted)
- **Ingress/Egress**: LiveKit Agents

## CI/CD
- **GitHub Actions**: Automated APK Builds, Next.js type checking.
