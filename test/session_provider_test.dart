import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:viikshana/core/session/session_repository.dart';
import 'package:viikshana/core/session/session_provider.dart';

void main() {
  group('sessionVersionProvider', () {
    test('initial state is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(sessionVersionProvider), 0);
    });

    test('bumping version updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sessionVersionProvider.notifier).state++;
      expect(container.read(sessionVersionProvider), 1);
      container.read(sessionVersionProvider.notifier).state++;
      expect(container.read(sessionVersionProvider), 2);
    });
  });

  group('session providers (with box)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('session_provider_test');
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

    test('hasSessionTokenProvider is false when no tokens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(hasSessionTokenProvider), false);
      expect(container.read(sessionAccessTokenProvider), isNull);
    });

    test('after setTokens and bump sessionVersion, hasSessionTokenProvider is true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(sessionRepositoryProvider);
      await repo.setTokens('access-xyz', 'refresh-abc');
      container.read(sessionVersionProvider.notifier).state++;
      expect(container.read(hasSessionTokenProvider), true);
      expect(container.read(sessionAccessTokenProvider), 'access-xyz');
    });

    test('after clear and bump sessionVersion, hasSessionTokenProvider is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(sessionRepositoryProvider);
      await repo.setTokens('at', 'rt');
      container.read(sessionVersionProvider.notifier).state++;
      expect(container.read(hasSessionTokenProvider), true);
      await repo.clear();
      container.read(sessionVersionProvider.notifier).state++;
      expect(container.read(hasSessionTokenProvider), false);
      expect(container.read(sessionAccessTokenProvider), isNull);
    });
  });
}
