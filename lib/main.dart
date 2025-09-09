import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/infrastructure/services/terra_service.dart';
import 'package:squadupv2/infrastructure/services/chat_service.dart';
import 'package:squadupv2/infrastructure/services/activity_service.dart';
import 'package:squadupv2/infrastructure/services/squad_service.dart';
import 'package:squadupv2/infrastructure/services/race_service.dart';
import 'package:squadupv2/infrastructure/services/deep_link_service.dart';
import 'package:squadupv2/infrastructure/services/onboarding_service.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:squadupv2/presentation/view_models/login_view_model.dart';
import 'package:squadupv2/presentation/view_models/signup_view_model.dart';
import 'package:squadupv2/presentation/view_models/onboarding_chat_view_model.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'core/constants/environment.dart';
import 'core/router/app_router.dart';
import 'infrastructure/services/logger_service.dart';

final GetIt locator = GetIt.instance;

/// Initialize all services and dependencies
Future<void> setupServiceLocator() async {
  // Core services
  locator.registerLazySingleton(() => EventBus());
  locator.registerLazySingleton(() => Supabase.instance.client);

  // Authentication service - singleton
  locator.registerLazySingleton(() => AuthService());

  // Infrastructure services
  locator.registerLazySingleton(() => TerraService());
  locator.registerLazySingleton(() => DeepLinkService());
  locator.registerLazySingleton(() => OnboardingService());

  // Domain services
  locator.registerLazySingleton(() => ActivityService());
  locator.registerLazySingleton(() => SquadService());
  locator.registerLazySingleton(() => RaceService());

  // Register FeedbackService with interface for testing
  locator.registerLazySingleton<IFeedbackService>(() => FeedbackServiceImpl());

  // Chat Service - Factory because each chat needs its own instance
  locator.registerFactory(
    () => ChatService(
      supabase: locator<SupabaseClient>(),
      eventBus: locator<EventBus>(),
    ),
  );

  // ViewModels - Register as factories with parameters
  locator.registerFactory(() => LoginViewModel(locator<AuthService>()));
  locator.registerFactory(() => SignupViewModel(locator<AuthService>()));
  locator.registerFactory(
    () => OnboardingChatViewModel(locator<OnboardingService>()),
  );

  // Logger service - singleton
  locator.registerLazySingleton<LoggerService>(() => LoggerService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first
  logger.init(isProduction: const bool.fromEnvironment('dart.vm.product'));

  // TEMPORARY: Force logout and cleanup for testing
  await _forceLogoutAndCleanup();

  // Initialize Supabase
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );

  // Setup dependency injection
  await setupServiceLocator();

  // Initialize auth service (no profile creation since we're logged out)
  final auth = locator<AuthService>();
  auth.initialize();

  runApp(const SquadUpApp());
}

/// TEMPORARY: Force logout and cleanup all stored data for testing
Future<void> _forceLogoutAndCleanup() async {
  try {
    // Clear shared preferences (onboarding flags, etc.)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    logger.info('Cleared shared preferences');

    // If Supabase is already initialized, sign out
    try {
      if (Supabase.instance.client.auth.currentUser != null) {
        await Supabase.instance.client.auth.signOut();
        logger.info('Signed out from Supabase');
      }
    } catch (e) {
      // Supabase might not be initialized yet, that's fine
      logger.info('Supabase not initialized yet, skipping signout');
    }
  } catch (e) {
    logger.error('Error during force cleanup', e);
  }
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
