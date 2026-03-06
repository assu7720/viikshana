import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/data/models/api_user_profile.dart';

/// Fetches GET /auth/api/me when user is signed in (session token or Firebase). Returns null when not signed in or 401.
final currentUserProfileProvider = FutureProvider.autoDispose<ApiUserProfile?>((ref) async {
  final isSignedIn = ref.watch(isSignedInProvider);
  if (kDebugMode) debugPrint('[UserProfile] currentUserProfileProvider future: isSignedIn=$isSignedIn');
  if (!isSignedIn) return null;
  try {
    if (kDebugMode) debugPrint('[UserProfile] Calling apiClient.getMe()...');
    final profile = await ref.read(apiClientProvider).getMe();
    if (kDebugMode) debugPrint('[UserProfile] getMe() done: hasProfile=${profile != null}');
    return profile;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[UserProfile] getMe() error: $e');
      debugPrint(st.toString());
    }
    return null;
  }
});
