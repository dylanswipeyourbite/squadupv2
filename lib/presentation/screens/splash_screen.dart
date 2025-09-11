import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Splash screen that handles initial routing logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _squadRepository = locator<SquadRepository>();
  final _logger = locator<LoggerService>();

  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // Add a small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // Not authenticated, go to login
      if (mounted) {
        context.go(AppRoutes.login);
      }
      return;
    }

    // Check onboarding status from database/preferences
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // For existing users, check database for onboarding status and squads
    try {
      // Get user's squads from database
      final squads = await _squadRepository.getUserSquads();
      final hasSquads = squads.isNotEmpty;

      // Update SharedPreferences to match database state
      await prefs.setBool('hasSquad', hasSquads);

      // Check if user has completed onboarding
      // If they have squads, they must have completed onboarding
      final hasCompletedOnboarding =
          prefs.getBool('hasCompletedOnboarding') ?? hasSquads;

      if (!hasCompletedOnboarding) {
        // New user - go to onboarding
        if (mounted) {
          context.go(AppRoutes.welcome);
        }
        return;
      }

      // User has completed onboarding
      if (!hasSquads) {
        // No squad yet, go to squad choice
        if (mounted) {
          context.go(AppRoutes.squadChoice);
        }
        return;
      }

      // User has squads - navigate to squads overview
      if (mounted) {
        context.go('/squads');
      }
    } catch (e) {
      _logger.error('Error checking user status', e);
      // On error, fall back to default behavior
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app name
            Text(
              'SquadUp',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Where obsession finds its tribe',
              style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
