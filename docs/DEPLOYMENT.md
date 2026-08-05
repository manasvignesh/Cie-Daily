# Deployment Guide

## Mobile App (Flutter)
1. Generate keystores and provisioning profiles.
2. Update `.env.production`.
3. `flutter build appbundle --release`
4. Upload to Google Play Console / App Store Connect.

## Admin Dashboard (Next.js)
1. Push to the `main` branch.
2. Connect Vercel to your GitHub repository.
3. Add the Supabase and LiveKit environment variables to the Vercel dashboard.
4. Deploy!

## Backend (Supabase)
1. Apply the latest migration via `supabase db push`.
2. Ensure RLS policies are active.
