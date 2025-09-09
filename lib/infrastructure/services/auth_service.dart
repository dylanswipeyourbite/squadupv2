import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Authentication events
class AuthStateChangedEvent extends AppEvent {
  final Session? session;
  AuthStateChangedEvent(this.session);
}

class AuthErrorEvent extends AppEvent {
  final String message;
  AuthErrorEvent(this.message);
}

/// Authentication service handling Supabase Auth
class AuthService {
  final SupabaseClient _supabase = locator<SupabaseClient>();
  final EventBus _eventBus = locator<EventBus>();

  StreamSubscription<AuthState>? _authStateSubscription;

  /// Current Supabase session
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Initialize auth service and set up listeners
  void initialize() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) async {
        _eventBus.fire(AuthStateChangedEvent(data.session));
        if (data.session != null) {
          await ensureProfile().catchError((_) => null);
        } else {
          _currentProfileId = null;
        }
      },
      onError: (error) {
        _eventBus.fire(AuthErrorEvent(error.toString()));
        return null;
      },
    );
  }

  /// Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      // If signup didn't create a session (e.g., email confirmation disabled), sign in immediately
      if (_supabase.auth.currentSession == null) {
        final signInRes = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (signInRes.user == null) {
          throw AuthException('Sign in after signup failed');
        }
      }

      // Ensure profile now that we have a session/user
      await ensureProfile().catchError((_) => null);

      return _supabase.auth.currentUser;
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await ensureProfile().catchError((_) => null);
      }
      return res.user;
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapSupabaseAuthException(e);
    }
  }

  /// Current profile ID from Supabase
  String? _currentProfileId;
  String? get currentProfileId => _currentProfileId;

  /// Fetch and cache current profile id
  Future<String?> ensureProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // First try by user_id (preferred)
      try {
        final existing = await _supabase
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (existing != null) {
          _currentProfileId = existing['id'] as String?;
          return _currentProfileId;
        }

        final inserted = await _supabase
            .from('profiles')
            .insert({
              'user_id': user.id,
              'email': user.email,
              'display_name':
                  user.userMetadata?['display_name'] ??
                  user.email?.split('@').first ??
                  'Runner',
            })
            .select('id')
            .single();

        _currentProfileId = inserted['id'] as String?;
        return _currentProfileId;
      } catch (e) {
        // If user_id column does not exist on remote yet, fall back to email
        final existingByEmail = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', user.email as Object)
            .maybeSingle();

        if (existingByEmail != null) {
          _currentProfileId = existingByEmail['id'] as String?;
          return _currentProfileId;
        }

        final insertedByEmail = await _supabase
            .from('profiles')
            .insert({
              'email': user.email,
              'display_name':
                  user.userMetadata?['display_name'] ??
                  user.email?.split('@').first ??
                  'Runner',
            })
            .select('id')
            .single();

        _currentProfileId = insertedByEmail['id'] as String?;
        return _currentProfileId;
      }
    } catch (e) {
      logger.error('Failed to ensure profile', e);
      rethrow;
    }
  }

  String _mapSupabaseAuthException(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password';
      case 'invalid_email':
        return 'Please enter a valid email address';
      case 'user_already_exists':
        return 'An account already exists with this email';
      case 'weak_password':
        return 'Password should be at least 6 characters';
      case 'over_request_rate_limit':
        return 'Too many attempts. Please try again later';
      default:
        return e.message;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
  }
}
