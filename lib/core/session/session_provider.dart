import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:viikshana/core/session/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) => SessionRepository());

/// Bump this after storing or clearing tokens so [hasSessionTokenProvider] re-evaluates.
final sessionVersionProvider = StateProvider<int>((ref) => 0);

/// Access token from session (persisted). When non-null, user is considered signed in for API.
final sessionAccessTokenProvider = Provider<String?>((ref) {
  ref.watch(sessionVersionProvider);
  final token = ref.read(sessionRepositoryProvider).accessToken;
  if (kDebugMode) debugPrint('[SessionProvider] sessionAccessTokenProvider evaluated: tokenLen=${token?.length ?? 0}');
  return token;
});

/// True when we have a stored API session token (don't show login).
final hasSessionTokenProvider = Provider<bool>((ref) {
  ref.watch(sessionVersionProvider);
  final hasToken = ref.read(sessionRepositoryProvider).hasToken;
  if (kDebugMode) debugPrint('[SessionProvider] hasSessionTokenProvider evaluated: hasToken=$hasToken');
  return hasToken;
});
