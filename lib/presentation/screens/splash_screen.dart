import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';

/// Splash screen that handles initial routing logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // Add a small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not authenticated, go to login
      if (mounted) {
        context.go(AppRoutes.login);
      }
      return;
    }

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;

    if (!hasCompletedOnboarding) {
      // Go to onboarding
      if (mounted) {
        context.go(AppRoutes.welcome);
      }
      return;
    }

    // Check if user has a squad
    if (!mounted) return;
    final hasSquad = prefs.getBool('hasSquad') ?? false;

    if (!hasSquad) {
      // No squad, go to squad choice
      if (mounted) {
        context.go(AppRoutes.squadChoice);
      }
      return;
    }

    // All set, go to home
    if (mounted) {
      context.go(AppRoutes.home);
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
