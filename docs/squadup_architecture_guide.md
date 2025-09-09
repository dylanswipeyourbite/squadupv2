# SquadUp Architecture Guide - Service Locator & State Management

## Architecture Decision

**Use GetIt for all dependency injection and Provider only for UI state propagation.**

## Authentication Migration

**SquadUp has migrated from Firebase Auth to Supabase Auth for unified authentication.**
- All authentication flows now use `Supabase.instance.client.auth`
- User profiles linked via `auth.users.id` instead of Firebase UID
- Session management handled directly by Supabase Auth
- RLS policies updated to use `auth.uid()` function

### Why This Approach?

1. **Single Source of Truth**: GetIt manages all dependencies
2. **Testability**: Easy to mock services in tests
3. **Performance**: Provider handles UI updates efficiently with Selector
4. **Clarity**: Clear separation between DI and state management

## Implementation Guide

### 1. Update Service Locator

```dart
// lib/core/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core services
  locator.registerLazySingleton(() => EventBus());
  locator.registerLazySingleton(() => Supabase.instance.client);
  
  // Register AuthService as singleton (not in Provider anymore)
  locator.registerLazySingleton(() => AuthService());
  
  // Domain services
  locator.registerLazySingleton(() => ActivityService());
  locator.registerLazySingleton(() => RaceService());
  locator.registerLazySingleton(() => FeedbackService());
  
  // Repositories
  locator.registerLazySingleton<KnowledgeRepository>(
    () => SupabaseKnowledgeRepository(supabase: locator<SupabaseClient>()),
  );
  
  // Application services
  locator.registerLazySingleton(() => KnowledgeFacadeService(
    extractionService: locator<KnowledgeExtractionService>(),
    patternService: locator<PatternDetectionService>(),
    searchService: locator<KnowledgeSearchService>(),
    knowledgeRepository: locator<KnowledgeRepository>(),
    eventBus: locator<EventBus>(),
  ));
  
  // ViewModels - Register as factories
  locator.registerFactoryParam<ChatViewModel, String, String>(
    (squadId, squadName) => ChatViewModel(
      squadId: squadId,
      squadName: squadName,
    ),
  );
  
  // Chat Service - Factory because each chat needs its own instance
  locator.registerFactory(() => ChatService(
    supabase: locator<SupabaseClient>(),
    eventBus: locator<EventBus>(),
  ));
}
```

### 2. Update Main App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:squadup/core/service_locator.dart';
import 'package:squadup/core/theme/squadup_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/environment.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (now handles auth directly)
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );
  
  // Setup dependency injection
  await setupServiceLocator();
  
  // Initialize auth service
  final auth = locator<AuthService>();
  auth.initialize();
  
  runApp(const SquadUpApp());
}

class SquadUpApp extends StatelessWidget {
  const SquadUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No more MultiProvider needed at root level
    return MaterialApp.router(
      title: 'SquadUp',
      theme: SquadUpTheme.darkTheme,
      darkTheme: SquadUpTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 3. Update SquadMainScreen

```dart
// lib/presentation/screens/squads/squad_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squadup/core/service_locator.dart';
import 'package:squadup/presentation/screens/squads/view_models.dart/chat_view_model.dart';

class SquadMainScreen extends StatefulWidget {
  final String squadId;
  final String squadName;

  const SquadMainScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  @override
  State<SquadMainScreen> createState() => _SquadMainScreenState();
}

class _SquadMainScreenState extends State<SquadMainScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  late ChatViewModel _chatViewModel;
  
  @override
  void initState() {
    super.initState();
    // Get ViewModel from service locator
    _chatViewModel = locator<ChatViewModel>(
      param1: widget.squadId,
      param2: widget.squadName,
    );
    // Initialize the chat
    _chatViewModel.initializeChat();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _chatViewModel.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _chatViewModel,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            ObsessionStreamScreen(
              squadId: widget.squadId,
              squadName: widget.squadName,
            ),
            KnowledgeVaultScreen(
              squadId: widget.squadId,
              squadName: widget.squadName,
            ),
          ],
        ),
        // ... rest of the UI
      ),
    );
  }
}
```

### 4. Accessing Services in Widgets

```dart
// In any widget or ViewModel
class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get services from locator
    final authService = locator<AuthService>();
    
    // Get ViewModels from Provider (for UI state)
    final chatViewModel = context.watch<ChatViewModel>();
    
    // Use Selector for performance
    return Selector<ChatViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return CircularProgressIndicator();
        }
        return YourContent();
      },
    );
  }
}
```

### 5. Testing Strategy

```dart
// test/view_models/chat_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {}
class MockChatService extends Mock implements ChatService {}

void main() {
  setUpAll(() {
    // Reset and setup test dependencies
    locator.reset();
    locator.registerSingleton<AuthService>(MockAuthService());
    locator.registerFactory<ChatService>(() => MockChatService());
  });
  
  test('ChatViewModel sends message correctly', () async {
    final viewModel = ChatViewModel(
      squadId: 'test-squad',
      squadName: 'Test Squad',
    );
    
    // Test your view model
    await viewModel.sendTextMessage('Hello');
    
    // Verify behavior
    verify(mockChatService.sendMessage(any)).called(1);
  });
}
```

## Architecture Rules

### 1. Dependency Injection Rules
- ✅ All services registered in GetIt
- ✅ ViewModels created via GetIt factories
- ✅ No services in Provider
- ✅ Use `locator<T>()` to access services

### 2. State Management Rules
- ✅ Provider only for ViewModel → UI communication
- ✅ Use `ChangeNotifier` for ViewModels
- ✅ Use `Selector` for performance
- ✅ Keep Provider scope as narrow as possible

### 3. Service Rules
- ✅ Services are stateless when possible
- ✅ Services handle external integrations
- ✅ Services return domain models
- ✅ Services use EventBus for cross-cutting concerns

### 4. ViewModel Rules
- ✅ ViewModels contain screen/feature logic
- ✅ ViewModels use services from locator
- ✅ ViewModels expose UI state
- ✅ ViewModels handle user interactions

## Migration Checklist

- [ ] Remove AuthService from Provider in main.dart
- [ ] Register all ViewModels in service_locator.dart
- [ ] Update all screens to get ViewModels from locator
- [ ] Remove any remaining `context.read<Service>()` calls
- [ ] Update tests to use GetIt mocking
- [ ] Ensure all services are registered before use

## Benefits of This Architecture

1. **Testability**: Mock any service easily
2. **Consistency**: One pattern for all dependencies
3. **Performance**: Efficient UI updates with Selector
4. **Scalability**: Easy to add new services/features
5. **Maintainability**: Clear separation of concerns

## Common Patterns

### Creating a New Feature

1. Create domain service (if needed)
2. Register in service_locator
3. Create ViewModel using services
4. Register ViewModel factory
5. Use Provider to connect ViewModel to UI

### Handling Complex State

For complex features with multiple ViewModels:

```dart
class SquadDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => locator<SquadViewModel>(param1: squadId),
        ),
        ChangeNotifierProvider(
          create: (_) => locator<ActivityViewModel>(param1: squadId),
        ),
      ],
      child: SquadDashboardContent(),
    );
  }
}
```

This architecture provides a solid foundation that scales well and maintains clarity as your app grows.