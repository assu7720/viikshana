import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:viikshana/core/search_history/search_history_repository.dart';

void main() {
  group('SearchHistoryRepository (no box)', () {
    test('getQueries returns empty when box not opened', () {
      final repo = SearchHistoryRepository();
      expect(repo.getQueries(), isEmpty);
    });

    test('addQuery does not throw when box not opened', () async {
      final repo = SearchHistoryRepository();
      await expectLater(repo.addQuery('test'), completes);
    });

    test('clear does not throw when box not opened', () async {
      final repo = SearchHistoryRepository();
      await expectLater(repo.clear(), completes);
    });
  });

  group('SearchHistoryRepository (with box)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('search_history_test');
      Hive.init(tempDir.path);
      await initSearchHistoryBox();
    });

    setUp(() async {
      await SearchHistoryRepository().clear();
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('addQuery and getQueries round-trip', () async {
      final repo = SearchHistoryRepository();
      await repo.addQuery('first');
      expect(repo.getQueries(), ['first']);
      await repo.addQuery('second');
      expect(repo.getQueries(), ['second', 'first']);
    });

    test('repeated query moves to front (max 10)', () async {
      final repo = SearchHistoryRepository();
      for (var i = 0; i < 12; i++) {
        await repo.addQuery('q$i');
      }
      final q = repo.getQueries();
      expect(q.length, 10);
      expect(q.first, 'q11');
      expect(q.last, 'q2');
    });

    test('addQuery moves existing to front', () async {
      final repo = SearchHistoryRepository();
      await repo.addQuery('a');
      await repo.addQuery('b');
      await repo.addQuery('a');
      expect(repo.getQueries(), ['a', 'b']);
    });

    test('clear empties history', () async {
      final repo = SearchHistoryRepository();
      await repo.addQuery('x');
      expect(repo.getQueries(), isNotEmpty);
      await repo.clear();
      expect(repo.getQueries(), isEmpty);
    });

    test('empty or whitespace addQuery does not add', () async {
      final repo = SearchHistoryRepository();
      await repo.addQuery('');
      await repo.addQuery('   ');
      expect(repo.getQueries(), isEmpty);
    });
  });
}
