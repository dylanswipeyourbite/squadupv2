## SquadUp Software Requirements Specification (SRS)

### 1. Introduction

- **Purpose**: Define the currently implemented behavior of the SquadUp mobile app to guide a potential rebuild with a clean foundation.
- **Scope**: Cross-platform Flutter app integrating Firebase (auth), Supabase (DB/realtime/Edge Functions), and Terra (fitness device integrations). This SRS documents implemented flows only.

### 2. Product Overview

- **Vision**: A private, squad-centric training space where small groups share runs, track races, and coordinate via an obsession-focused chat.
- **Primary Users**:
  - Authenticated athletes (members/captains) using the mobile app
  - No anonymous usage

### 3. Tech Stack (implemented)

- Flutter, Dart 3, Provider for state
- Navigation via `go_router`
- **Supabase Auth** for sign in/up (migrated from Firebase Auth)
- Supabase: PostgreSQL, Realtime, RLS, Edge Functions
- Firebase Storage for media (images/voice/video) [present in deps; UI supports send hooks]
- Local: `shared_preferences` for onboarding flags and cached values
- Notifications: `flutter_local_notifications`
- Deep links: `uni_links` handled via `DeepLinkService`
- Device data: Terra integrations
- AI: Expert Ask flow powered by GPT (LLM) via secure Supabase Edge Functions; responses are grounded in activity data (Terra + app check-ins), recent squad conversation context, and upcoming race goals.

### 4. Navigation Map (implemented routes)

- `/` → `SplashScreen` (auth + onboarding gate)
- `/login` → `LoginScreen`
- `/signup` → `SignupScreen`
- `/welcome` → `WelcomeScreen`
- `/onboarding/why-run` → `WhyRunScreen`
- `/onboarding/squad-choice` → `SquadChoiceScreen`
- `/home` → `HomeScreen`
- `/squads/create` → `CreateSquadScreen` (query: `?onboarding=true` optional)
- `/squads/join` → `JoinSquadScreen` (query: `?onboarding=true` optional)
- `/squads/details/:squadId` → `SquadDetailScreen`
- `/squads/chat/:squadId` → `SquadMainScreen` → `ObsessionStreamScreen`
- `/races/add` → `AddRaceScreen`
- `/settings` → `SettingsScreen`
- `/settings/connect-device` → `ConnectDeviceScreen`
- `/settings/notifications` → `NotificationSettingsScreen`
- `/activities/checkin` → `ActivityCheckInScreen` (expects `extra` with Terra data)

Auth guard and onboarding gating are enforced in `app_router.dart` using **Supabase Auth** and `SharedPreferences` flags: `hasCompletedOnboarding`, `hasSquad`.

### 5. Functional Requirements

5.1 Authentication & Account
- As a new user, I want to sign up with email and password, so I can create a secure account. (**Supabase Authentication**)
- As a returning user, I want to sign in with my credentials, so I can access my squads and data. (**Supabase Authentication**)
- As a user, I want to reset my password, so I can regain access if I forget it. (**Supabase Authentication**)
- As a user, I want my identity linked to my profile in the database, so my activities, squads, and messages remain consistent across sessions. (Supabase user profile linked via `auth.users.id`)

5.2 Conversational Onboarding (AI-led)
- As a new user, I want a short conversational onboarding with an AI assistant, so the app quickly understands my goals, experience, and constraints (e.g., weekly time, injury history).
- As a new user, I want the AI to help me create or join a squad during onboarding, so I can start collaborating immediately.
- As a new user, I want the AI to propose connecting my fitness device, so my activities can sync automatically. (Terra)
- As a new user, I want the AI to suggest a near-term training focus (e.g., base building or recovery), so I understand how to get value from the app on day one.

5.3 Squads
- As a user, I want to create a private squad that uses an invite code, so I can bring my friends together without public discovery. (Supabase)
- As a user, I want to join a squad by entering an invite code, so I can collaborate with my crew. (Supabase)
- As a captain, I want to view and share the invite code, so I can grow my squad easily.
- As a user, I want to view members and basic weekly activity stats, so I can gauge squad engagement.
- As a captain, I want the option to delete the squad, so I can wind down when needed; as a member, I want to leave a squad, so I control my participation.

5.4 Chat
- As a user, I want a real-time squad conversation space, so we can coordinate and share training updates. (Supabase realtime)
- As a user, I want to send text, images, voice, and video, so I can communicate in the most effective format for the moment.
- As a user, I want activity check-ins to appear as structured messages, so my squad quickly understands distance, duration, and effort.
 - As a user, I want to mention/tag squad members with autocomplete (e.g., @alice), so I can get someone’s attention quickly.
 - As a user, I want to create polls with options and deadlines, so the squad can decide on plans (e.g., long run time) and view results.
 - As a user, I want to react to messages with emojis, so I can respond quickly without cluttering the chat.
 - As a user, I want to reply to a specific message (quote reply), so conversations remain clear even in busy chats.
 - As a user, I want to edit or delete my own messages (within a grace period), so I can correct mistakes.
 - As a user, I want read receipts and delivery status, so I know who has seen critical updates.
 - As a user, I want typing indicators, so conversations feel responsive and real-time.
 - As a user, I want link previews and multi-attachment sending (photos/videos/voice), so shared content is rich and scannable.
 - As a user, I want in-chat search and member filtering, so I can find messages and context quickly.
 - As a user, I expect feature parity with modern chat apps (e.g., WhatsApp) in everyday interactions, so chat feels easy and familiar.

5.5 Activities & Check-ins
- As a user, I want to manually share a check-in with activity type and effort, so my squad sees how training is going.
- As a user, I want auto-synced activities from my device to be available for quick sharing, so I can post with one tap after workouts. (Terra)
- As a user, I want check-ins to include structured metadata (e.g., distance, duration, pace, HR, elevation, suffer score), so context is clear at a glance.
- As a user, I want the option to remove my activities and related messages, so I can reset my data when needed.
 - As a user, I want synced activities to capture richer fields when available (e.g., cadence, splits/laps, elevation gain, average/max HR, device source), so analysis is more accurate. (Terra)
 - As a user, I want to optionally classify runs (e.g., easy, tempo, long, intervals), so the squad understands intent and training load.
 - As a user, I want each activity to be automatically summarized by AI (e.g., detect workout structure like 10×400m intervals, classify workout type, surface key splits and effort), so expert assistants and my squad can understand sessions at a glance and downstream analysis is simpler.

Activity data layers (architecture):
- Layer 1 — Summary: a normalized activity record (type/run type, duration, distance, pace, elevation, average HR, suffer score, timestamps, external ID) optimized for UI, lists, and quick analytics.
- Layer 2 — Details: structured metrics and series (e.g., splits/laps, cadence, effort segments) suitable for deeper analysis and expert reasoning.
- Layer 3 — Raw Archive: compressed provider payload(s) (full Terra JSON) for provenance/rehydration; not used directly for UI or expert reasoning.

5.6 Device Integrations (Terra)
- As a user, I want to connect my fitness provider (e.g., Garmin, Strava, Polar, Fitbit), so my activities sync automatically. (Terra)
- As a user, I want to disconnect a provider, so I control my data sources. (Terra)
- As a user, I want to import recent or historical activities with progress feedback, so I can backfill my training history. (Terra)
- As a user, I want a timely nudge when a new activity is available, so I can share it with my squad while it’s fresh.

5.7 Races
- As a user, I want to add upcoming races with date/distance and context, so I can plan training toward specific goals.
- As a user, I want to share a race with one or more squads and set a primary squad, so my team can rally around the goal.
- As a user, I want the system to recognize when I’m in a training window (e.g., 16 weeks out), so guidance and expert suggestions adapt automatically.
 - As a squad member, I want a race-mode SquadPulse that intensifies as race day approaches (countdown-driven), so hype and focus increase for the team.
 - As a user, I want the pulse to reflect collective training momentum (e.g., recent check-ins, streaks, goal completion), so the squad’s energy is visible.
 - As a captain, I want race-mode visuals surfaced in chat headers/sections, so the team is constantly reminded of the target event.

5.8 Notifications
- As a user, I want to enable/disable notifications and specific categories (e.g., activity sync), so I receive only what I value.
- As a user, I want the app to respect system-level notification permissions, so my preferences are honored.

5.9 Expert Assistants (AI Personas)
- As a user, I want to ask an expert assistant questions about training, recovery, pacing, or nutrition, so I get actionable, personalized guidance.
- As a user, I want expert responses to consider my activity history (synced via Terra and manual check-ins), so the advice is grounded in my actual training load and intensity.
- As a user, I want expert responses to consider my conversation history, so the advice aligns with ongoing context and goals.
- As a user, I want expert responses to consider my upcoming races and training phase, so recommendations align with my event date and current cycle.
- As a squad, I want to rename persona names, so the assistants feel like part of our team culture.
- As a user, I want to trigger experts via @mentions (e.g., @sage) or a dedicated action, so I can quickly route my question to the right expert.
- As a user, I want the AI to briefly cite which signals it used (e.g., time window of activities, next race), so I trust and understand its recommendations.

Persona roles (defaults; names are editable per squad):
- Sage: general strategy, mindset, and consistency.
- Alex: head coach for planning, periodization, and adapting training.
- Nova: data analyst for trends, load, and pacing insights.
- Aria: nutritionist for fueling, hydration, and recovery nutrition.
- Pace: race strategist for pacing, splits, and course strategy.
- Koa: recovery/PT for mobility, injury prevention, and return-to-run plans.

Expert flow (functional behavior):
- Inputs: user’s full activity history (Layers 1 & 2), latest check-ins/effort, the squad’s conversation history (with relevance-based retrieval), and upcoming races with training phase.
- Processing: orchestrate a prompt to GPT that retrieves and emphasizes the most relevant slices of history based on the user’s question and persona role; ensure safety, clarity, and brevity; align guidance to race timelines when present.
- Output: a chat message from the selected persona, optionally including concrete next steps (e.g., today’s guidance) and rationale.
- Scope note: for activity analysis the expert uses only Layers 1 and 2; the Raw Archive (Layer 3) is excluded from direct reasoning and is reserved for provenance/rehydration.


5.10 Settings & Data Management
- As a user, I want to manage connected devices and run imports, so my data stays current.
- As a user, I want to manage notification preferences, so I control interruptions.
- As a user, I want to delete my activities, so I can clean up my history when needed.

5.11 Deep Links
- As a user, I want deep links to complete device connection flows or return to the app with status, so connecting providers is seamless. (Terra, Deep links)


### 6. External Services and Integrations

- **Supabase Auth** for user identity (migrated from Firebase Auth)
- Supabase client configured via `GetIt` service locator
- Supabase Edge Functions: `create-squad`, `onboarding-assistant` (implemented)
- Terraforming service integration (Terra REST APIs via `TerraService` implementation)
 - GPT/LLM via Supabase Edge Functions for Expert Assistants and Conversational Onboarding (prompt orchestration, persona conditioning, retrieval of relevant activity/conversation/race context)

### 8. Security and Privacy (implemented behaviors)

- Supabase RLS enforced on tables; **profiles table linked via `auth.users.id`** (migrated from Firebase UID)
- Invite codes control access to private squads; no public discovery
- Terra privacy copy in UI; only essential activity fields are processed and shared

### 9. Non-Functional Requirements (observed)

- Performance: realtime chat streams, lazy loading, cache-first for some lists
- Reliability: retries/guards around RLS/Edge Function boundaries
- UX: dark theme, accessible defaults, haptics on critical actions
- Internationalization: dependencies present (`intl`), copy currently English-only
 - Security & data isolation: Supabase Row Level Security (RLS) enforces per-squad/ per-user isolation on all data tables; least-privilege policies are required for writes, and privileged operations run via Edge Functions with service-role keys. **Client uses Supabase Auth sessions directly** (migrated from Firebase bridging); unauthorized access attempts are denied by RLS.

### 10. Known Constraints / Legacy Notes

- **Migration completed**: Moved from Firebase Auth to Supabase Auth for unified authentication
- Some media/video playback flows are stubbed with toasts; storage uploads handled in ViewModel layer
- Vault AI features are present in services but largely disabled in UI by default (autocomplete off)

### 11. Out of Scope / Future Work

- Full privacy settings screen, help/FAQ destinations
- Robust race list and detail management UI
- Dedicated screen for synced activities review before sharing
- Presence/typing indicators in chat

### 12. Appendix

- Route helpers in `AppRoutes`
- Dependency registration in `core/service_locator.dart`
 - Activity Data Contract (Layers 1–3): see `docs/attachments/activity_data_contract.md`


