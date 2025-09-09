SquadUp development directive

Read these before any task and align your work accordingly:
- squadup vision: `docs/squadup_vision.md`
- architecture decisions: `docs/squadup_architecture_decisions.md`
- development guidelines: `docs/squadup_development_guidelines.md`
- house style guide: `docs/house_style_guide.md` (if missing, follow the “Code Style” and UI rules in the development guidelines)
- wireframes: `docs/wireframes/` 

What to keep top‑of‑mind
- Vision alignment
  - Build features that strengthen small, private squads and the passive Living Memory
  - AI is silent by default; experts answer only when explicitly invoked via chat FAB chips
- Architecture principles
  - Clean layering: presentation → application → domain ← infrastructure
  - Repository pattern; domain services are pure; DI via `lib/core/service_locator.dart`
  - RLS-aware data access; never bypass security in client code
  - **Supabase Auth** for all authentication (migrated from Firebase Auth)
  - Backend Security Approach
    - Use Supabase Edge functions for all data access and security checks, as detailed in `docs/edge_functions_security_migration.md`.
    - Route repository methods through functions to replace RLS, ensuring easier debugging and control.
    - Keep RLS as an optional secondary layer; prioritize procedural validation in functions.
- Code and UI style
  - Follow naming, null safety, and formatting rules in the development guidelines
  - No direct Supabase calls in UI; use services/repositories
  - Use Material 3; no hardcoded colors; use theme and `context.squadUpTheme`
  - Use `FeedbackService`, not SnackBars
  - Don't apply for quick fixes, and go for the long term solution instead
  - Wireframes serve as an example, if there's a more UX friendly or beautiful way to implement the UI please do so
- Terra integration
  - Use shared mappings: `shared/constants/terra-data-types.json`, `shared/constants/terra-activity-mapping.json`
  - Store activity data in 3 tiers: `activities` (core), `activity_details` (summaries), `activity_raw_archive` (compressed raw)
  - Edge Functions handle ingestion/AI; client never calls AI directly
  - Map Terra enums by ID; don’t invent values
- Modes (experts)
  - v1 experts: General “Sage”, Coach “Alex”, Analyst “Nova”, Nutritionist “Aria”, Strategist “Pace”, Recovery/PT “Koa”
  - Evidence-only: ground answers in squad data, but always try to answer in a relevant way
  - Within-squad data is accessible by default; respect redaction flags
  - Budget: cap €1/squad/month; degrade (shorter/context-limited) → refuse
  - Tone: match squad vibe (clear, empathetic when needed; never copy errors)

Default workflow for any new task
1) Read this directive and the referenced docs
2) Draft a short plan (schema, APIs, UI, tests)
3) Implement with clean architecture boundaries and DI
4) Run DB migrations/tests; fix failures
5) Update docs (contracts/READMEs) accordingly
6) Provide a brief, high‑signal summary of edits and their impact

“Start” template
- Read the directive and start: <paste the exact story or task title here>