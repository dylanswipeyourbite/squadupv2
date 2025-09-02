# SquadUp Foundation Setup

This document describes the foundation that has been set up for the SquadUp project, following the architectural guidelines and SRS requirements.

## ✅ What Has Been Implemented

### 1. **Core Initialization**
- ✅ Firebase initialization in `main.dart`
- ✅ Supabase client initialization with environment configuration
- ✅ Service locator pattern using GetIt for dependency injection
- ✅ Event bus for decoupled communication

### 2. **Services Architecture**
All services follow clean architecture principles with proper separation:

#### **AuthService** (`lib/infrastructure/services/auth_service.dart`)
- ✅ Firebase Authentication integration
- ✅ Sign up, sign in, sign out functionality
- ✅ Password reset functionality
- ✅ Firebase to Supabase session bridging (template)
- ✅ Event-driven auth state changes
- ✅ User-friendly error mapping

#### **TerraService** (`lib/infrastructure/services/terra_service.dart`)
- ✅ Terra API integration for fitness devices
- ✅ Provider connection/disconnection
- ✅ Activity fetching
- ✅ Historical data import
- ✅ Deep link handling for auth callbacks
- ✅ Support for major providers (Garmin, Strava, Polar, etc.)

#### **Placeholder Services**
Basic structure created for:
- `ChatService` - Real-time messaging
- `ActivityService` - Workout and check-in management
- `SquadService` - Squad management
- `RaceService` - Race and training management
- `DeepLinkService` - App link handling

### 3. **Routing & Navigation**
- ✅ GoRouter configuration with all routes from SRS
- ✅ Auth guards and onboarding flow
- ✅ Deep link support
- ✅ Placeholder screens for all routes

### 4. **Theme System**
- ✅ Custom SquadUp theme with Material 3
- ✅ Dark theme following house style guide
- ✅ Theme extensions for SquadUp-specific properties
- ✅ Easy access extensions (`context.colors`, `context.squadUpTheme`)

### 5. **Configuration Files**
- ✅ Environment constants with API keys
- ✅ Firebase configuration (iOS: GoogleService-Info.plist)
- ✅ Firebase configuration template (Android: google-services.json)
- ✅ Supabase Edge Function for session bridging

## 🚧 What Needs to Be Done

### 1. **Firebase Setup**
- [ ] Run `flutterfire configure` to generate proper `firebase_options.dart`
- [ ] Update Android `google-services.json` with actual values
- [ ] Enable Authentication in Firebase Console

### 2. **Supabase Setup**
- [ ] Create database tables with RLS policies
- [ ] Deploy the session bridging Edge Function
- [ ] Implement proper JWT token generation in Edge Function
- [ ] Set up webhook endpoints for Terra integration

### 3. **Terra Integration**
- [ ] Register webhook endpoints with Terra
- [ ] Implement activity data processing pipeline
- [ ] Set up the 3-layer activity storage system

### 4. **Complete Service Implementations**
- [ ] Implement ChatService with real-time features
- [ ] Complete ActivityService with check-in functionality
- [ ] Implement SquadService with invite codes
- [ ] Complete RaceService with training phases

### 5. **UI Implementation**
- [ ] Replace placeholder screens with actual implementations
- [ ] Implement the conversational onboarding flow
- [ ] Create the squad chat interface
- [ ] Build activity check-in screens

## 🏗️ Architecture Overview

```
lib/
├── core/                     # Core utilities
│   ├── constants/           # Environment variables
│   ├── event_bus.dart      # Event-driven communication
│   ├── router/             # App routing
│   ├── service_locator.dart # Dependency injection
│   └── theme/              # App theming
│
├── infrastructure/          # External service implementations
│   └── services/           # All service implementations
│
├── presentation/           # UI layer
│   └── screens/           # All app screens
│
└── main.dart              # App entry point
```

## 🔐 Security Notes

1. **API Keys**: Current environment file contains real API keys. In production:
   - Use environment variables
   - Never commit sensitive keys
   - Rotate keys regularly

2. **Session Bridging**: The current Edge Function is a template:
   - Must verify Firebase ID tokens
   - Must generate proper Supabase JWT tokens
   - Must implement rate limiting

3. **RLS Policies**: Supabase tables need Row Level Security:
   - User can only access their squads
   - Squad data isolated between squads
   - Activities private to squad members

## 🚀 Getting Started

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:
   ```bash
   flutterfire configure
   ```

3. **Set up Supabase**:
   - Create project at supabase.com
   - Run database migrations
   - Deploy Edge Functions

4. **Run the app**:
   ```bash
   flutter run
   ```

## 📝 Development Guidelines

- Follow the clean architecture principles in `docs/squadup_architecture_guide.md`
- Use the development guidelines in `docs/squadup_development_guidelines.md`
- Maintain the house style from `docs/squadup_house_style.html`
- Always use the FeedbackService for user feedback
- Use dependency injection via service locator
- Keep domain logic pure (no external dependencies)

## 🧪 Testing

The foundation is set up to be easily testable:
- Services can be mocked via GetIt
- Event bus allows testing of event flows
- Clean architecture enables unit testing of business logic

---

The foundation provides a solid base following all architectural decisions and guidelines. The next step is to implement the actual functionality as defined in the SRS.
