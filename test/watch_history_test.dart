import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:viikshana/core/watch_history/watch_history_repository.dart';
import 'package:viikshana/data/hive/watch_history_adapter.dart';
import 'package:viikshana/data/models/watch_history_entry.dart';

void main() {
  group('WatchHistoryEntry', () {
    test('equality and hashCode', () {
      const a = WatchHistoryEntry(
        videoId: 'v1',
        positionSeconds: 30,
        lastWatchedAtMs: 1000,
      );
      const b = WatchHistoryEntry(
        videoId: 'v1',
        positionSeconds: 30,
        lastWatchedAtMs: 1000,
      );
      const c = WatchHistoryEntry(
        videoId: 'v1',
        positionSeconds: 45,
        lastWatchedAtMs: 1000,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a == c, false);
    });
  });

  group('WatchHistoryRepository (no box)', () {
    test('getPosition returns 0 when box not opened', () {
      final repo = WatchHistoryRepository();
      expect(repo.getPosition('v1'), 0);
      expect(repo.getPosition('any'), 0);
    });

    test('setPosition does not throw when box not opened', () async {
      final repo = WatchHistoryRepository();
      await expectLater(
        repo.setPosition('v1', 60),
        completes,
      );
    });
  });

  group('WatchHistoryEntryAdapter', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('watch_history_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WatchHistoryEntryAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('round-trip write and read', () async {
      final box = await Hive.openBox<WatchHistoryEntry>('test_adapter');
      addTearDown(() => box.close());

      const entry = WatchHistoryEntry(
        videoId: 'vid-123',
        positionSeconds: 90,
        lastWatchedAtMs: 1700000000000,
      );
      await box.put(entry.videoId, entry);
      final read = box.get(entry.videoId);
      expect(read, isNotNull);
      expect(read!.videoId, entry.videoId);
      expect(read.positionSeconds, entry.positionSeconds);
      expect(read.lastWatchedAtMs, entry.lastWatchedAtMs);
    });

    test('multiple entries persist by videoId', () async {
      final box = await Hive.openBox<WatchHistoryEntry>('test_multi');
      addTearDown(() => box.close());

      await box.put('a', const WatchHistoryEntry(videoId: 'a', positionSeconds: 10, lastWatchedAtMs: 1));
      await box.put('b', const WatchHistoryEntry(videoId: 'b', positionSeconds: 20, lastWatchedAtMs: 2));

      final a = box.get('a');
      final b = box.get('b');
      expect(a?.positionSeconds, 10);
      expect(b?.positionSeconds, 20);
    });
  });

  group('WatchHistoryRepository (with box)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('watch_repo_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WatchHistoryEntryAdapter());
      }
      await initWatchHistoryBox();
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('setPosition and getPosition round-trip', () async {
      final repo = WatchHistoryRepository();
      await repo.setPosition('video-1', 120);
      expect(repo.getPosition('video-1'), 120);
    });

    test('getPosition returns 0 for unknown videoId', () {
      final repo = WatchHistoryRepository();
      expect(repo.getPosition('unknown'), 0);
    });

    test('setPosition overwrites previous position', () async {
      final repo = WatchHistoryRepository();
      await repo.setPosition('v2', 10);
      await repo.setPosition('v2', 25);
      expect(repo.getPosition('v2'), 25);
    });
  });
}
