import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Authentication events
class AuthStateChangedEvent extends AppEvent {
  final firebase_auth.User? user;
  AuthStateChangedEvent(this.user);
}

class AuthErrorEvent extends AppEvent {
  final String message;
  AuthErrorEvent(this.message);
}

/// Authentication service handling Firebase Auth and Supabase session bridging
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = locator<SupabaseClient>();
  final EventBus _eventBus = locator<EventBus>();

  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  /// Current Firebase user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Initialize auth service and set up listeners
  void initialize() {
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(
      (user) async {
        _eventBus.fire(AuthStateChangedEvent(user));

        if (user != null) {
          // Bridge Firebase session to Supabase
          await _bridgeToSupabase(user);
        } else {
          // Sign out from Supabase as well
          await _supabase.auth.signOut();
        }
      },
      onError: (error) {
        _eventBus.fire(AuthErrorEvent(error.toString()));
      },
    );
  }

  /// Sign up with email and password
  Future<firebase_auth.User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();

        // Bridge to Supabase
        await _bridgeToSupabase(credential.user!);
      }

      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<firebase_auth.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Bridge to Supabase
        await _bridgeToSupabase(credential.user!);
      }

      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _supabase.auth.signOut()]);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Bridge Firebase session to Supabase
  Future<void> _bridgeToSupabase(firebase_auth.User user) async {
    try {
      final idToken = await user.getIdToken();

      // Call Supabase Edge Function to bridge the session
      final response = await _supabase.functions.invoke(
        'bridge-firebase-session',
        body: {
          'idToken': idToken,
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to bridge session: ${response.data}');
      }

      // The Edge Function should return a Supabase session
      final sessionData = response.data as Map<String, dynamic>;

      // Set the Supabase session
      await _supabase.auth.recoverSession(sessionData['session']);
    } catch (e) {
      logger.error('Error bridging to Supabase', e);
      _eventBus.fire(AuthErrorEvent('Failed to sync with server'));
    }
  }

  /// Map Firebase exceptions to user-friendly messages
  String _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'An error occurred. Please try again';
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
  }
}
