import 'package:hive_flutter/hive_flutter.dart';
import 'package:viikshana/data/models/watch_history_entry.dart';

const String _boxName = 'watch_history';

Box<dynamic>? _watchHistoryBox;

/// Call from main() after Hive.initFlutter() and adapter registration.
Future<void> initWatchHistoryBox() async {
  if (_watchHistoryBox != null && _watchHistoryBox!.isOpen) return;
  _watchHistoryBox = await Hive.openBox<dynamic>(_boxName);
}

/// Persists and retrieves watch position per video for resume playback.
class WatchHistoryRepository {
  Box<dynamic>? get _box => _watchHistoryBox;

  /// Returns saved position in seconds, or 0 if none. Safe when box is not opened (e.g. in tests).
  int getPosition(String videoId) {
    final b = _box;
    if (b == null || !b.isOpen) return 0;
    final entry = b.get(videoId);
    if (entry is WatchHistoryEntry) return entry.positionSeconds;
    return 0;
  }

  /// Saves watch position; call on pause or when leaving the player. No-op when box is not opened.
  Future<void> setPosition(String videoId, int positionSeconds) async {
    final b = _box;
    if (b == null || !b.isOpen) return;
    final entry = WatchHistoryEntry(
      videoId: videoId,
      positionSeconds: positionSeconds,
      lastWatchedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await b.put(videoId, entry);
  }
}
