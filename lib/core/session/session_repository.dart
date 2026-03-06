import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _defaultSessionBoxName = 'session';
const String _keyAccessToken = 'accessToken';
const String _keyRefreshToken = 'refreshToken';

Box<dynamic>? _sessionBox;

/// Call from main() after Hive.initFlutter().
Future<void> initSessionBox() async {
  if (_sessionBox != null && _sessionBox!.isOpen) return;
  _sessionBox = await Hive.openBox<dynamic>(_defaultSessionBoxName);
}

/// Persists API auth tokens (accessToken, refreshToken) in Hive.
class SessionRepository {
  SessionRepository();

  Box<dynamic>? get _store => _sessionBox?.isOpen == true ? _sessionBox : null;

  String? get accessToken {
    try {
      final b = _store;
      if (b == null) return null;
      final v = b.get(_keyAccessToken);
      return v?.toString();
    } catch (_) {
      return null;
    }
  }

  String? get refreshToken {
    try {
      final b = _store;
      if (b == null) return null;
      final v = b.get(_keyRefreshToken);
      return v?.toString();
    } catch (_) {
      return null;
    }
  }

  bool get hasToken => (accessToken ?? '').trim().isNotEmpty;

  Future<void> setTokens(String? access, String? refresh) async {
    final b = _store;
    if (kDebugMode) {
      debugPrint('[Session] setTokens: box=${b != null}, boxOpen=${_sessionBox?.isOpen}, accessLen=${access?.length ?? 0}, refreshLen=${refresh?.length ?? 0}');
    }
    if (b == null) return;
    if (access != null && access.isNotEmpty) {
      await b.put(_keyAccessToken, access);
    } else {
      await b.delete(_keyAccessToken);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await b.put(_keyRefreshToken, refresh);
    } else {
      await b.delete(_keyRefreshToken);
    }
    if (kDebugMode) debugPrint('[Session] Tokens ${access != null ? "stored" : "cleared"} (after write: hasToken=$hasToken)');
  }

  Future<void> clear() async {
    final b = _store;
    if (b == null) return;
    await b.delete(_keyAccessToken);
    await b.delete(_keyRefreshToken);
    if (kDebugMode) debugPrint('[Session] Cleared');
  }
}
