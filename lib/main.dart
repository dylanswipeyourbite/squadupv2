import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'core/constants/environment.dart';
import 'core/router/app_router.dart';
import 'infrastructure/services/logger_service.dart';

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

  // Initialize auth service
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
