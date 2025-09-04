# SquadUp Implementation Guide

## ✅ Completed Implementation

### 1. Database Schema (PostgreSQL/Supabase)

#### Tables Created:
- **profiles**: User profiles linked to Firebase Auth
- **squads**: Squad information with invite codes
- **squad_members**: Membership and roles
- **squad_messages**: Real-time chat messages
- **message_reactions**: Emoji reactions
- **message_read_receipts**: Read tracking
- **activities**: Activity summaries (Layer 1)
- **activity_details**: Structured activity data (Layer 2)
- **activity_raw_archive**: Compressed raw data (Layer 3)
- **activity_checkins**: Links activities to squad messages
- **races**: User races and goals
- **race_squads**: Race-squad associations

#### Security:
- Row Level Security (RLS) policies for all tables
- Squad data isolation between squads
- User can only modify their own data
- Service role for privileged operations

#### Migration Files:
- `supabase/migrations/001_initial_schema.sql`
- `supabase/migrations/002_row_level_security.sql`
- `supabase/migrations/003_realtime_subscriptions.sql`

### 2. Authentication Flow

#### Features Implemented:
- **Firebase Auth** for user authentication
- **Supabase session bridging** via Edge Function
- **Profile creation** in Supabase after signup
- **Enhanced UI/UX**:
  - Modern, dark theme following house style
  - Proper form validation with helpful error messages
  - Loading states and animations
  - Password strength requirements
  - Email validation with regex
  - Forgot password flow

#### Files Updated:
- `lib/presentation/screens/auth/login_screen.dart`
- `lib/presentation/screens/auth/signup_screen.dart`
- `lib/infrastructure/services/auth_service.dart`
- `lib/presentation/view_models/login_view_model.dart`
- `lib/presentation/view_models/signup_view_model.dart`
- `supabase/functions/bridge-firebase-session/index.ts`

### 3. Architecture Patterns

#### Clean Architecture:
```
Presentation Layer (UI)
    ↓
Application Layer (ViewModels)
    ↓
Domain Layer (Services, Models)
    ↓
Infrastructure Layer (Firebase, Supabase, Terra)
```

#### Dependency Injection:
- GetIt for service locator
- Provider for UI state management
- Clear separation of concerns

#### Error Handling:
- FeedbackService for all user feedback
- No direct SnackBars in UI
- Mapped Firebase errors to user-friendly messages

## 🚧 Next Steps - Priority Order

### 4. Conversational Onboarding (Next)
Create an AI-led onboarding flow that:
- Understands user's running goals and experience
- Helps create or join first squad
- Suggests connecting fitness devices
- Proposes initial training focus

**Files to create:**
- `lib/presentation/screens/onboarding/onboarding_chat_screen.dart`
- `lib/infrastructure/services/onboarding_service.dart`
- `supabase/functions/onboarding-assistant/index.ts`

### 5. Squad Creation/Joining
Implement squad management:
- Create squad with auto-generated invite code
- Join squad via invite code
- Squad member management
- Captain privileges

**Files to create:**
- `lib/presentation/screens/squads/create_squad_screen.dart`
- `lib/presentation/screens/squads/join_squad_screen.dart`
- `lib/infrastructure/services/squad_service.dart`
- `supabase/functions/create-squad/index.ts`
- `supabase/functions/join-squad/index.ts`

### 6. Squad Chat
Real-time messaging with:
- Text messages
- Activity check-ins
- Message reactions
- Read receipts
- Typing indicators
- @mentions

**Files to update:**
- `lib/presentation/screens/squads/squad_main_screen.dart`
- `lib/infrastructure/services/chat_service.dart`

### 7. Activity Check-ins
Manual activity logging:
- Quick check-in form
- Suffer score (1-10)
- Distance, duration, type
- Share to squad chat

**Files to create:**
- `lib/presentation/screens/activities/activity_checkin_screen.dart`
- `lib/infrastructure/services/activity_service.dart`

### 8. Expert Integration
AI assistants in chat:
- Sage, Alex, Nova, Aria, Pace, Koa
- Context-aware responses
- Grounded in squad data
- €1/squad/month budget

**Files to create:**
- `lib/presentation/widgets/expert_selector.dart`
- `supabase/functions/expert-assistant/index.ts`

## 📝 Database Setup Instructions

1. **Run migrations in Supabase Dashboard:**
   ```sql
   -- Run each migration file in order:
   -- 001_initial_schema.sql
   -- 002_row_level_security.sql  
   -- 003_realtime_subscriptions.sql
   ```

2. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy bridge-firebase-session
   ```

3. **Set environment variables in Supabase:**
   - `FIREBASE_SERVICE_ACCOUNT`: Firebase service account JSON
   - `SUPABASE_JWT_SECRET`: Your Supabase JWT secret

## 🎨 UI/UX Guidelines

### Theme Usage:
```dart
// Always use theme colors
context.colors.primary
context.colors.surface
context.squadUpTheme.sufferColor

// Never hardcode colors
Colors.blue // ❌
Color(0xFF667EEA) // ❌
```

### Feedback Pattern:
```dart
// Always use FeedbackService
FeedbackService.success(context, 'Message');
FeedbackService.error(context, 'Error');

// Never use SnackBar directly
ScaffoldMessenger.of(context).showSnackBar(...); // ❌
```

### Form Validation:
- Email: Regex validation
- Password: Min 6 chars, letters + numbers
- Display name: Min 2 chars
- Always trim() input values

## 🏗️ Architecture Rules

1. **No direct Supabase calls in UI** - Use services/repositories
2. **Pure domain logic** - No external dependencies in domain layer
3. **Event-driven communication** - Use EventBus for cross-cutting concerns
4. **RLS for security** - All data access through RLS policies
5. **Small squads** - 5-8 person limit enforced in database
6. **Conversational tone** - Like talking to running friends

## 🔐 Security Considerations

1. **Dual Auth System:**
   - Firebase handles authentication
   - Supabase uses bridged sessions
   - Profile IDs link the systems

2. **Data Isolation:**
   - RLS policies ensure squad isolation
   - Users can only see their squads' data
   - Captains have additional privileges

3. **Edge Functions:**
   - Service role for privileged operations
   - Input validation and sanitization
   - Rate limiting (to be implemented)

## 🎯 Vision Alignment

Remember: We're building a **home for obsessed endurance athletes**, not just another fitness app. Every interaction should feel like you're among your closest running friends who understand why you check weather apps 73 times before a long run.

Key principles:
- **Intimate**: 5-8 person squads max
- **Private**: No public discovery
- **Obsession-friendly**: No apologizing for 4:30 AM alarms
- **Evidence-based**: Experts ground answers in squad data
- **Budget-conscious**: €1/squad/month for AI features
