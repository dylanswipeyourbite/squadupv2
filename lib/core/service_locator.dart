import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';

final GetIt locator = GetIt.instance;

/// Initialize all services and dependencies
Future<void> setupServiceLocator() async {
  // Register FeedbackService with interface for testing
  locator.registerLazySingleton<IFeedbackService>(() => FeedbackServiceImpl());
}

/// Extension for easier access in widgets (optional but convenient)
extension ServiceLocatorX on BuildContext {
  T getService<T extends Object>() => locator<T>();

  /// Get a parameterized factory
  T getFactory<T extends Object>(dynamic param1, [dynamic param2]) =>
      locator<T>(param1: param1, param2: param2);
}
