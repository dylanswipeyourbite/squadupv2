import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'core/constants/environment.dart';
import 'core/router/app_router.dart';
import 'infrastructure/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first
  logger.init(isProduction: const bool.fromEnvironment('dart.vm.product'));

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

class SquadUpApp extends StatelessWidget {
  const SquadUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide SquadListViewModel at the root level
    return ChangeNotifierProvider<SquadListViewModel>(
      create: (_) => locator<SquadListViewModel>(),
      child: MaterialApp.router(
        title: 'SquadUp',
        theme: SquadUpTheme.darkTheme,
        darkTheme: SquadUpTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
