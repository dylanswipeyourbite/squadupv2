import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/constants/environment.dart';
import 'core/router/app_router.dart';
import 'infrastructure/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first
  logger.init(isProduction: const bool.fromEnvironment('dart.vm.product'));

  // Initialize all services
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    ),
  ]);

  // Setup dependency injection
  await setupServiceLocator();

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
