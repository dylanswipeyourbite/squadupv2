# SquadUp Development Guidelines

## 🏗️ Architecture & Project Structure

### Clean Architecture Layers
SquadUp follows clean architecture principles with clear separation of concerns:

```
lib/
├── core/                          # Core utilities and shared code
│   ├── theme/                     # App theme and styling
│   ├── router/                    # Navigation routing
│   ├── constants/                 # App constants
│   ├── event_bus.dart            # Event-driven communication
│   └── service_locator.dart      # Dependency injection setup
│
├── data/                         # Data layer - Models only
│   └── models/                   # Pure data models (DTOs)
│       ├── message.dart
│       ├── knowledge_entry.dart
│       └── squad_pattern.dart
│
├── domain/                       # Domain layer - Business logic
│   ├── repositories/             # Repository interfaces (contracts)
│   │   ├── knowledge_repository.dart
│   │   ├── pattern_repository.dart
│   │   └── chat_repository.dart
│   │
│   ├── services/                 # Domain services (business rules)
│   │   ├── knowledge_extraction_service.dart
│   │   ├── pattern_detection_service.dart
│   │   └── knowledge_search_service.dart
│   │
│   └── events/                   # Domain events
│       ├── knowledge_events.dart
│       └── chat_events.dart
│
├── infrastructure/               # Infrastructure layer - External services
│   ├── supabase/                # Supabase implementations
│   │   ├── supabase_knowledge_repository.dart
│   │   ├── supabase_pattern_repository.dart
│   │   └── supabase_chat_repository.dart
│   │
│   └── firebase/                # Firebase implementations
│       └── firebase_storage_service.dart
│
├── application/                  # Application layer - Use cases
│   ├── facades/                 # Simplified interfaces for UI
│   │   ├── knowledge_facade_service.dart
│   │   └── chat_facade_service.dart
│   │
│   └── coordinators/            # Event coordination
│       └── knowledge_event_coordinator.dart
│
├── services/                     # Legacy/Simple services
│   ├── auth_service.dart        # Authentication
│   ├── activity_service.dart    # Activity tracking
│   └── feedback_service.dart    # UI feedback
│
└── presentation/                 # Presentation layer - UI
    ├── screens/                 # App screens
    └── widgets/                 # Reusable widgets
```

### Architecture Principles

1. **Dependency Rule**: Dependencies point inward. Inner layers don't know about outer layers.
   ```
   presentation → application → domain ← infrastructure
   ```

2. **Repository Pattern**: All data access goes through repository interfaces
   ```dart
   // Domain layer defines the contract
   abstract class KnowledgeRepository {
     Future<String?> create(KnowledgeEntry entry);
   }
   
   // Infrastructure layer implements it
   class SupabaseKnowledgeRepository implements KnowledgeRepository {
     Future<String?> create(KnowledgeEntry entry) {
       // Supabase-specific implementation
     }
   }
   ```

3. **Domain Services**: Business logic lives in domain services
   ```dart
   class KnowledgeExtractionService {
     // Pure business logic, no external dependencies
     bool shouldAnalyze(Message message) {
       return message.length > 20 && message.type == MessageType.text;
     }
   }
   ```

4. **Facades**: Simplify complex operations for the UI
   ```dart
   class KnowledgeFacadeService {
     // Coordinates multiple domain services
     // Provides simple API for UI
   }
   ```

## 🔧 Dependency Injection with GetIt

### Setup
SquadUp uses GetIt for dependency injection. All services are registered in `service_locator.dart`:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(...);
  
  // Setup dependency injection
  await setupServiceLocator();
  
  runApp(MyApp());
}
```

### Service Registration
```dart
// core/service_locator.dart
final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Singletons - one instance for entire app
  locator.registerLazySingleton(() => EventBus());
  locator.registerLazySingleton(() => AuthService());
  
  // Repositories
  locator.registerLazySingleton<KnowledgeRepository>(
    () => SupabaseKnowledgeRepository(supabase: locator<SupabaseClient>()),
  );
  
  // Domain Services
  locator.registerLazySingleton(() => KnowledgeExtractionService(
    queueRepository: locator<AnalysisQueueRepository>(),
    eventBus: locator<EventBus>(),
  ));
  
  // Factories - new instance each time
  locator.registerFactory(() => ChatService(
    supabase: locator<SupabaseClient>(),
    eventBus: locator<EventBus>(),
  ));
}
```

### Using Services
```dart
// In ViewModels or Widgets
class ChatViewModel extends ChangeNotifier {
  // Get services from locator
  final AuthService _authService = locator<AuthService>();
  final KnowledgeFacadeService _knowledgeFacade = locator<KnowledgeFacadeService>();
  
  // No need to pass dependencies through constructors
  ChatViewModel({
    required this.squadId,
    required this.squadName,
  });
}
```

### Testing with GetIt
```dart
// In tests, you can override registrations
setUp(() {
  locator.reset();
  locator.registerSingleton<AuthService>(MockAuthService());
});
```

## 🎨 UI/UX Guidelines

### Theme Usage
- **Always use theme colors** via `Theme.of(context).colorScheme` or `context.colors`
- **Use custom theme extension** for SquadUp-specific properties: `context.squadUpTheme`
- **Never hardcode colors** - All colors should come from the theme
- **Use semantic color names** (e.g., `colors.primary`, not `Color(0xFF667EEA)`)

```dart
// ✅ Good
final colors = Theme.of(context).colorScheme;
Container(color: colors.surface)

// ✅ Good - Using extension
final squadTheme = context.squadUpTheme;
Container(color: squadTheme.sufferColor)

// ❌ Bad
Container(color: Color(0xFF667EEA))
Container(color: Colors.blue)
```

### Material Widgets
- **Prefer Material 3 widgets** over custom containers
- **Use Card instead of Container** with decoration for elevated surfaces
- **Use Chip widgets** for tags, selections, and badges
- **Use FilledButton/OutlinedButton** instead of custom button containers
- **Use ListTile** for list items instead of custom Row layouts

```dart
// ✅ Good
Card(
  child: ListTile(
    leading: Icon(Icons.run),
    title: Text('Morning Run'),
  ),
)

// ❌ Bad
Container(
  decoration: BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(children: [...]),
)
```

### User Feedback
- **Use FeedbackService for all user feedback** - Never use SnackBars directly
- **Handle errors consistently** with appropriate messages
- **Keep feedback messages concise** and action-oriented

```dart
// ✅ Good - Simple feedback
FeedbackService.success(context, 'Check-in shared! 💪');
FeedbackService.error(context, 'Connection failed');
FeedbackService.info(context, 'Voice notes coming soon!');

// ❌ Bad - Never use SnackBars directly
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
);
```

### Custom Widgets
- **Use existing SquadUp widgets** from `presentation/widgets/widgets.dart`
- **Create reusable widgets** for repeated patterns
- **Keep widgets focused** - one widget, one responsibility

## 📊 State Management

### Provider Pattern
- **Use Provider for dependency injection** (services)
- **Keep providers at appropriate scope** - not everything needs to be global
- **Services should be stateless** when possible

```dart
// ✅ Good - Service injection
final authService = context.read<AuthService>();

// ✅ Good - Scoped provider
ChangeNotifierProvider(
  create: (_) => SquadChatViewModel(squadId),
  child: SquadChatScreen(),
)
```

### Local State
- **Use StatefulWidget for UI state** (form inputs, animations)
- **Use setState for simple local state** - don't over-engineer
- **Consider ValueNotifier** for single value state

## 🏗️ Architecture Guidelines

### Models
- **Always use typed models** - Never pass raw `Map<String, dynamic>`
- **Include fromJson/toJson** for all models
- **Use copyWith** for immutable updates
- **Handle null values gracefully** in fromJson

```dart
// ✅ Good
final squad = SquadModel.fromJson(response);
final updated = squad.copyWith(name: 'New Name');

// ❌ Bad
final squad = response as Map<String, dynamic>;
squad['name'] = 'New Name';
```

### Services
- **One service per domain** (AuthService, ChatService, ActivityService)
- **Services handle Supabase/Firebase interaction**
- **Services return domain models**, not raw responses
- **Handle errors at service level** with meaningful messages

```dart
// ✅ Good
class SquadService {
  Future<SquadModel> getSquad(String id) async {
    try {
      final response = await _supabase
          .from('squads')
          .select('*, captain:captain_id(*)')
          .eq('id', id)
          .single();
      
      return SquadModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load squad: $e');
    }
  }
}
```

### Error Handling
- **Use FeedbackService for user-facing errors** 
- **Log errors for debugging** but show user-friendly messages
- **Always check mounted** before showing UI feedback in async operations

```dart
// ✅ Good
try {
  await someOperation();
  if (mounted) {
    FeedbackService.success(context, 'Success!');
  }
} catch (e) {
  if (mounted) {
    FeedbackService.error(context, 'Operation failed');
  }
  // Log for debugging
  print('Error details: $e');
}

// ❌ Bad - Using SnackBar directly
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Feedback Service Usage Patterns

```dart
// Success feedback
FeedbackService.success(context, 'Workout saved!');

// Error feedback
FeedbackService.error(context, 'Upload failed');

// Info feedback
FeedbackService.info(context, 'Syncing with Garmin...');

// Warning feedback
FeedbackService.warning(context, 'Unsaved changes');
```

## 🚦 Navigation

### GoRouter Usage
- **Use GoRouter for all navigation**
- **Pass complex data via `extra`** parameter
- **Use path parameters** for IDs
- **Handle deep links properly**

```dart
// ✅ Good
context.go('/squads/chat/${squad.id}', extra: {'squadName': squad.name});

// ❌ Bad
Navigator.push(context, MaterialPageRoute(...));
```

## 🔒 Security & Privacy

### Data Access
- **Never bypass Row Level Security** - Let Supabase handle it
- **Validate user permissions** in UI (e.g., captain-only features)
- **Don't expose sensitive data** in logs

### Null Safety
- **Use null-aware operators** (`?.`, `??`, `!`)
- **Validate nullable fields** in models
- **Provide sensible defaults** in fromJson

## 📝 Code Style

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `camelCase` (not SCREAMING_CASE)
- **Private members**: `_prefixWithUnderscore`

### Widget Structure
```dart
class MyWidget extends StatefulWidget {
  // 1. Constructor parameters (required first, optional after)
  final String requiredParam;
  final String? optionalParam;
  
  const MyWidget({
    super.key,
    required this.requiredParam,
    this.optionalParam,
  });

  // 2. Override methods
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 3. State variables
  bool _isLoading = false;
  
  // 4. Keys for contextual feedback
  final GlobalKey _submitButtonKey = GlobalKey();
  
  // 5. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // 6. Private methods
  Future<void> _loadData() async {
    try {
      // Implementation
      if (mounted) {
        FeedbackService.success(context, 'Data loaded');
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.error(context, 'Failed to load data');
      }
    }
  }
  
  // 7. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## 🧪 Testing Considerations

### Testable Code
- **Inject dependencies** rather than creating them
- **Keep widgets pure** when possible
- **Separate business logic** from UI
- **Mock FeedbackService** in tests

### Debug Helpers
- **Use meaningful print statements** during development
- **Remove debug prints** before committing
- **Use assert** for development-time checks

## 🚀 Performance

### Best Practices
- **Use const constructors** where possible
- **Dispose controllers** and subscriptions
- **Cache expensive computations**
- **Lazy load images** with CachedNetworkImage
- **Paginate large lists**
- **Keep event handlers lightweight** - delegate to services

### State Updates
- **Minimize rebuilds** - use targeted setState
- **Use keys** for list items that can reorder
- **Avoid rebuilding entire trees**
- **Use event-driven updates** via EventBus for cross-component communication

## 📱 Platform Considerations

### Responsive Design
- **Use MediaQuery** for responsive layouts
- **Test on multiple screen sizes**
- **Handle keyboard appearance**
- **Support both iOS and Android patterns**

### Offline Support
- **Queue operations** when offline
- **Show appropriate UI states**
- **Sync when connection returns**

## 🔄 Git Workflow

### Commit Messages
- **Use conventional commits**: `feat:`, `fix:`, `refactor:`, `docs:`
- **Be descriptive** but concise
- **Reference issues** when applicable

### Branch Strategy
- **Feature branches** from main
- **Descriptive branch names**: `feature/knowledge-vault`
- **Small, focused PRs**

## 📋 Checklist for New Features

Before submitting code:
- [ ] Uses theme colors exclusively
- [ ] Uses FeedbackService for all user feedback (no SnackBars)
- [ ] Uses Material widgets where applicable
- [ ] Follows error handling patterns
- [ ] Includes proper null safety
- [ ] Disposes resources properly
- [ ] Handles mounted checks in async operations
- [ ] Uses typed models
- [ ] Follows file naming conventions
- [ ] Includes meaningful error messages
- [ ] Tested on iOS and Android
- [ ] Follows clean architecture principles
- [ ] Uses dependency injection via GetIt
- [ ] Separates concerns properly (UI → Application → Domain → Infrastructure)
- [ ] Domain logic has no external dependencies
- [ ] Repository interfaces defined in domain layer
- [ ] Event-driven communication where appropriate

## 🚫 Anti-Patterns to Avoid

1. **Hardcoded values** - Use theme and constants
2. **SnackBars** - Use FeedbackService instead
3. **Inline styles** - Create reusable widgets
4. **Direct Supabase calls in widgets** - Use repositories
5. **Navigation.push** - Use GoRouter
6. **Generic containers** - Use semantic Material widgets
7. **V2/Enhanced naming** - Update existing code
8. **Commented code** - Remove or fix
9. **Print statements in production** - Use proper logging
10. **Ignoring null safety** - Handle edge cases
11. **Blocking UI with sync operations** - Keep UI responsive
12. **Not checking mounted after async** - Always check before UI updates
13. **Mixing business logic in UI** - Use domain services
14. **Direct dependencies in ViewModels** - Use service locator
15. **God classes** - Split by responsibility
16. **Circular dependencies** - Use events or facades

## 💡 Tips

- When in doubt, check existing patterns in the codebase
- Prioritize readability over cleverness
- Write code that's easy to delete/modify
- Think about the next developer (might be you in 6 months)
- If something feels complex, it probably is - simplify
- Use FeedbackService for consistent user experience
- Keep domain logic pure - no external dependencies
- Use events for decoupling components
- Test domain logic independently from infrastructure
- Let the architecture guide you - if it's hard to test, the design might be wrong

## 📚 Required Dependencies

Add these to your `pubspec.yaml`:
```yaml
dependencies:
  get_it: ^7.6.0  # Dependency injection
  # ... other dependencies
```

---

*These guidelines are living documentation. Update them as patterns evolve.*