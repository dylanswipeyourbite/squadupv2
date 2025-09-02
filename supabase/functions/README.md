# SquadUp Supabase Edge Functions

## Overview

This directory contains Supabase Edge Functions that power server-side functionality for SquadUp.

## Functions

### bridge-firebase-session

Bridges Firebase Authentication sessions to Supabase, creating user profiles and sessions.

**Important**: The current implementation is a template. In production:
1. You MUST verify the Firebase ID token using Firebase Admin SDK
2. Generate proper JWT tokens for Supabase sessions
3. Implement proper session management

## Deployment

To deploy these functions:

1. Install Supabase CLI:
```bash
brew install supabase/tap/supabase
```

2. Link your project:
```bash
supabase link --project-ref littutaepiipvfbzxxpg
```

3. Deploy functions:
```bash
supabase functions deploy bridge-firebase-session
```

## Environment Variables

The following environment variables are automatically available in Edge Functions:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for admin operations

## Local Development

To run functions locally:

```bash
supabase functions serve bridge-firebase-session --env-file ./supabase/.env.local
```

## Security Notes

1. Always verify Firebase ID tokens before creating sessions
2. Use Row Level Security (RLS) policies on all tables
3. Never expose service role keys to client applications
4. Implement rate limiting for authentication endpoints
