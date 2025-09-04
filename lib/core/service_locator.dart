import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'package:squadupv2/infrastructure/services/logger_service.dart';

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

/// Extension for easier access in widgets (optional but convenient)
extension ServiceLocatorX on BuildContext {
  T getService<T extends Object>() => locator<T>();

  /// Get a parameterized factory
  T getFactory<T extends Object>(dynamic param1, [dynamic param2]) =>
      locator<T>(param1: param1, param2: param2);
}
