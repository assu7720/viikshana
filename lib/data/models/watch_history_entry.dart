/// Local watch history entry for resume playback (Hive).
class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.videoId,
    required this.positionSeconds,
    required this.lastWatchedAtMs,
  });

  final String videoId;
  final int positionSeconds;
  final int lastWatchedAtMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchHistoryEntry &&
          videoId == other.videoId &&
          positionSeconds == other.positionSeconds &&
          lastWatchedAtMs == other.lastWatchedAtMs;

  @override
  int get hashCode => Object.hash(videoId, positionSeconds, lastWatchedAtMs);
}
