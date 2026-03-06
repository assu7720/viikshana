import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/auth/auth_service.dart';
import 'package:viikshana/core/session/session_provider.dart';

/// Lazily creates AuthService. If Firebase is not initialized, returns a no-op service (null user, stream of null).
final authServiceProvider = Provider<AuthService>((ref) {
  try {
    Firebase.app();
    return AuthService(auth: FirebaseAuth.instance);
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('AuthService: Firebase not initialized, using no-op auth: $e');
      debugPrint(stack.toString());
    }
    return AuthService(auth: null);
  }
});

/// Current Firebase user; null when anonymous or not signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Synchronous read of current user (e.g. for gating). Use [authStateProvider] when you need rebuilds.
final currentUserProvider = Provider<User?>((ref) {
  final async = ref.watch(authStateProvider);
  return async.when(data: (v) => v, loading: () => null, error: (_, __) => null);
});

/// True when user is signed in: has API session token OR Firebase user. When true, don't show login.
final isSignedInProvider = Provider<bool>((ref) {
  final hasToken = ref.watch(hasSessionTokenProvider);
  final firebaseUser = ref.watch(currentUserProvider);
  final result = hasToken || firebaseUser != null;
  if (kDebugMode) debugPrint('[Auth] isSignedInProvider evaluated: hasToken=$hasToken, firebaseUser=${firebaseUser != null}, isSignedIn=$result');
  return result;
});
