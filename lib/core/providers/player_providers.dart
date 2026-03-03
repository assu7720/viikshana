import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:viikshana/core/watch_history/watch_history_repository.dart';

/// True when the video player is in fullscreen; shell hides bottom nav when true.
final fullScreenPlayerProvider = StateProvider<bool>((ref) => false);

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  return WatchHistoryRepository();
});
