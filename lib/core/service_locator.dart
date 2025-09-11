import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/infrastructure/repositories/squad_repository_impl.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/infrastructure/services/terra_service.dart';
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
import 'package:squadupv2/domain/repositories/chat_repository.dart';
import 'package:squadupv2/infrastructure/repositories/chat_repository_impl.dart';
import 'package:squadupv2/presentation/view_models/chat_view_model.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'package:squadupv2/domain/services/chat_service.dart' as domain;

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

  // Repositories
  locator.registerLazySingleton<SquadRepository>(() => SquadRepositoryImpl());
  locator.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());

  // Domain services
  locator.registerLazySingleton(() => ActivityService());
  locator.registerLazySingleton(() => SquadService());
  locator.registerLazySingleton(() => RaceService());
  locator.registerLazySingleton(
    () => domain.ChatService(
      repository: locator<ChatRepository>(),
      eventBus: locator<EventBus>(),
    ),
  );

  // Register FeedbackService with interface for testing
  locator.registerLazySingleton<IFeedbackService>(() => FeedbackServiceImpl());

  // ViewModels - Register as factories with parameters
  locator.registerFactory(() => LoginViewModel(locator<AuthService>()));
  locator.registerFactory(() => SignupViewModel(locator<AuthService>()));
  locator.registerFactory(
    () => OnboardingChatViewModel(locator<OnboardingService>()),
  );

  // Chat ViewModel - Factory with parameters
  locator.registerFactoryParam<ChatViewModel, String, String>(
    (squadId, squadName) => ChatViewModel(
      squadId: squadId,
      squadName: squadName,
      chatService: locator<domain.ChatService>(),
      authService: locator<AuthService>(),
      feedbackService: locator<IFeedbackService>(),
    ),
  );

  // Squad List ViewModel - Singleton to share across screens
  locator.registerLazySingleton(() => SquadListViewModel());

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
