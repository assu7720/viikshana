import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:viikshana/core/session/session_repository.dart';

void main() {
  group('SessionRepository (no box)', () {
    test('accessToken and refreshToken are null when box not opened', () {
      final repo = SessionRepository();
      expect(repo.accessToken, isNull);
      expect(repo.refreshToken, isNull);
      expect(repo.hasToken, false);
    });

    test('setTokens does not throw when box not opened', () async {
      final repo = SessionRepository();
      await expectLater(repo.setTokens('at', 'rt'), completes);
    });

    test('clear does not throw when box not opened', () async {
      final repo = SessionRepository();
      await expectLater(repo.clear(), completes);
    });
  });

  group('SessionRepository (with box)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('session_test');
      Hive.init(tempDir.path);
      await initSessionBox();
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    tearDown(() async {
      await SessionRepository().clear();
    });

    test('setTokens stores and hasToken is true', () async {
      final repo = SessionRepository();
      expect(repo.hasToken, false);
      await repo.setTokens('access-abc', 'refresh-xyz');
      expect(repo.accessToken, 'access-abc');
      expect(repo.refreshToken, 'refresh-xyz');
      expect(repo.hasToken, true);
    });

    test('clear removes tokens', () async {
      final repo = SessionRepository();
      await repo.setTokens('at', 'rt');
      expect(repo.hasToken, true);
      await repo.clear();
      expect(repo.accessToken, isNull);
      expect(repo.refreshToken, isNull);
      expect(repo.hasToken, false);
    });

    test('setTokens with null clears access token', () async {
      final repo = SessionRepository();
      await repo.setTokens('at', 'rt');
      await repo.setTokens(null, 'rt');
      expect(repo.accessToken, isNull);
      expect(repo.refreshToken, 'rt');
      expect(repo.hasToken, false);
    });

    test('hasToken is false for whitespace-only access token', () async {
      final repo = SessionRepository();
      await repo.setTokens('  ', 'rt');
      expect(repo.hasToken, false);
    });

    test('setTokens with empty string access clears access token', () async {
      final repo = SessionRepository();
      await repo.setTokens('at', 'rt');
      expect(repo.hasToken, true);
      await repo.setTokens('', 'rt');
      expect(repo.accessToken, isNull);
      expect(repo.refreshToken, 'rt');
      expect(repo.hasToken, false);
    });

    test('setTokens with null refresh clears refresh token only', () async {
      final repo = SessionRepository();
      await repo.setTokens('at', 'rt');
      await repo.setTokens('at', null);
      expect(repo.accessToken, 'at');
      expect(repo.refreshToken, isNull);
      expect(repo.hasToken, true);
    });
  });
}
