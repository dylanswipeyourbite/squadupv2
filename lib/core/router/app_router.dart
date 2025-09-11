import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/presentation/screens/splash_screen.dart';
import 'package:squadupv2/presentation/screens/auth/login_screen.dart';
import 'package:squadupv2/presentation/screens/auth/signup_screen.dart';
import 'package:squadupv2/presentation/screens/onboarding/welcome_screen.dart';
import 'package:squadupv2/presentation/screens/onboarding/onboarding_chat_screen.dart';
// import 'package:squadupv2/presentation/screens/onboarding/why_run_screen.dart';
import 'package:squadupv2/presentation/screens/onboarding/squad_choice_screen.dart';
import 'package:squadupv2/presentation/screens/home_screen.dart';
import 'package:squadupv2/presentation/screens/squads/create_squad_screen.dart';
import 'package:squadupv2/presentation/screens/squads/join_squad_screen.dart';
import 'package:squadupv2/presentation/screens/squads/squad_detail_screen.dart';
import 'package:squadupv2/presentation/screens/squads/squad_main_screen.dart';
import 'package:squadupv2/presentation/screens/races/add_race_screen.dart';
import 'package:squadupv2/presentation/screens/settings/settings_screen.dart';
import 'package:squadupv2/presentation/screens/settings/connect_device_screen.dart';
import 'package:squadupv2/presentation/screens/settings/notification_settings_screen.dart';
import 'package:squadupv2/presentation/screens/activities/activity_checkin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App routes constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const welcome = '/welcome';
  static const onboardingChat = '/onboarding/chat';
  static const whyRun = '/onboarding/why-run';
  static const squadChoice = '/onboarding/squad-choice';
  static const home = '/home';
  static const createSquad = '/squads/create';
  static const joinSquad = '/squads/join';
  static const squadDetail = '/squads/details/:squadId';
  static const squadChat = '/squads/chat/:squadId';
  static const addRace = '/races/add';
  static const settings = '/settings';
  static const connectDevice = '/settings/connect-device';
  static const notificationSettings = '/settings/notifications';
  static const activityCheckin = '/activities/checkin';
}

/// Global navigator key
final navigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboardingChat,
      builder: (context, state) => const OnboardingChatScreen(),
      redirect: _authGuard,
    ),
    // GoRoute(
    //   path: AppRoutes.whyRun,
    //   builder: (context, state) => const WhyRunScreen(),
    // ),
    GoRoute(
      path: AppRoutes.squadChoice,
      builder: (context, state) => const SquadChoiceScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.createSquad,
      builder: (context, state) {
        final isOnboarding = state.uri.queryParameters['onboarding'] == 'true';
        return CreateSquadScreen(isOnboarding: isOnboarding);
      },
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.joinSquad,
      builder: (context, state) {
        final isOnboarding = state.uri.queryParameters['onboarding'] == 'true';
        return JoinSquadScreen(isOnboarding: isOnboarding);
      },
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.squadDetail,
      builder: (context, state) {
        final squadId = state.pathParameters['squadId']!;
        return SquadDetailScreen(squadId: squadId);
      },
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.squadChat,
      builder: (context, state) {
        final squadId = state.pathParameters['squadId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final squadName = extra?['squadName'] ?? '';
        return SquadMainScreen(squadId: squadId, squadName: squadName);
      },
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.addRace,
      builder: (context, state) => const AddRaceScreen(),
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.connectDevice,
      builder: (context, state) => const ConnectDeviceScreen(),
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
      redirect: _authGuard,
    ),
    GoRoute(
      path: AppRoutes.activityCheckin,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          // Manual check-in
          return const ActivityCheckInScreen();
        }
        // Terra data check-in
        return ActivityCheckInScreen(terraData: extra);
      },
      redirect: _authGuard,
    ),
  ],
);

/// Auth guard redirect function
Future<String?> _authGuard(BuildContext context, GoRouterState state) async {
  final session = Supabase.instance.client.auth.currentSession;

  if (session == null) {
    // Not authenticated, redirect to login
    return AppRoutes.login;
  }

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      prefs.getBool('hasCompletedOnboarding') ?? false;

  if (!hasCompletedOnboarding) {
    // Allow onboarding-related routes
    if (state.matchedLocation == AppRoutes.welcome ||
        state.matchedLocation == AppRoutes.onboardingChat) {
      return null;
    }
    // Not completed onboarding, redirect to welcome
    return AppRoutes.welcome;
  }

  // Check if user has a squad
  final hasSquad = prefs.getBool('hasSquad') ?? false;

  if (!hasSquad &&
      state.matchedLocation != AppRoutes.createSquad &&
      state.matchedLocation != AppRoutes.joinSquad &&
      state.matchedLocation != AppRoutes.squadChoice) {
    // No squad and not on squad creation/join/choice pages
    return AppRoutes.squadChoice;
  }

  // All checks passed
  return null;
}
