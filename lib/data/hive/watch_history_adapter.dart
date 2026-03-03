import 'package:hive/hive.dart';
import 'package:viikshana/data/models/watch_history_entry.dart';

class WatchHistoryEntryAdapter extends TypeAdapter<WatchHistoryEntry> {
  @override
  int get typeId => 0;

  @override
  WatchHistoryEntry read(BinaryReader reader) {
    final videoId = reader.readString();
    final positionSeconds = reader.readInt();
    final lastWatchedAtMs = reader.readInt();
    return WatchHistoryEntry(
      videoId: videoId,
      positionSeconds: positionSeconds,
      lastWatchedAtMs: lastWatchedAtMs,
    );
  }

  @override
  void write(BinaryWriter writer, WatchHistoryEntry obj) {
    writer.writeString(obj.videoId);
    writer.writeInt(obj.positionSeconds);
    writer.writeInt(obj.lastWatchedAtMs);
  }
}
