import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/data/models/video_item.dart';

void main() {
  group('HomeFeedState', () {
    test('defaults', () {
      const state = HomeFeedState();
      expect(state.items, isEmpty);
      expect(state.nextPage, 1);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
    });

    test('copyWith preserves unspecified fields', () {
      const state = HomeFeedState(
        items: [VideoItem(id: '1', title: 'A')],
        nextPage: 2,
        hasMore: false,
      );
      final updated = state.copyWith(error: 'failed');
      expect(updated.items, state.items);
      expect(updated.nextPage, 2);
      expect(updated.hasMore, false);
      expect(updated.error, 'failed');
    });

    test('copyWith error to null clears error', () {
      const state = HomeFeedState(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('HomeFeedNotifier', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(homeFeedProvider);
      expect(state.items, isEmpty);
      expect(state.nextPage, 1);
      expect(state.isLoading, false);
      expect(state.hasMore, true);
    });

    test('loadInitial with mock API sets loading then loads empty feed', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();

      final state = container.read(homeFeedProvider);
      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.nextPage, 2);
    });

    test('loadInitial does not run again if already has items', () async {
      final mockClient = _MockClient((_) async {
        return http.Response(
          jsonEncode({
            'videos': [{'id': 'v1', 'title': 'First'}],
            'page': 1,
            'limit': 20,
            'hasMore': true,
            'nextPage': 2,
          }),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();
      expect(container.read(homeFeedProvider).items.length, 1);

      await notifier.loadInitial();
      // Still 1 item (second loadInitial no-op)
      expect(container.read(homeFeedProvider).items.length, 1);
    });

    test('refresh resets state and loads page 1', () async {
      final mockClient = _MockClient((request) async {
        final uri = request.url;
        final page = int.parse(uri.queryParameters['page'] ?? '1');
        return http.Response(
          jsonEncode({
            'videos': [
              {'id': 'p$page', 'title': 'Page $page'}
            ],
            'page': page,
            'limit': 20,
            'hasMore': page < 2,
            'nextPage': page + 1,
          }),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();
      expect(container.read(homeFeedProvider).items.first.id, 'p1');

      await notifier.refresh();
      final state = container.read(homeFeedProvider);
      expect(state.items.length, 1);
      expect(state.items.first.id, 'p1');
      expect(state.isLoading, false);
    });

    test('loadMore appends next page', () async {
      var callCount = 0;
      final mockClient = _MockClient((request) async {
        callCount++;
        final page = callCount;
        return http.Response(
          jsonEncode({
            'videos': [
              {'id': 'v$page', 'title': 'Video $page'}
            ],
            'page': page,
            'limit': 20,
            'hasMore': page < 2,
            'nextPage': page + 1,
          }),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();
      expect(container.read(homeFeedProvider).items.length, 1);
      expect(container.read(homeFeedProvider).items.first.id, 'v1');

      await notifier.loadMore();
      final state = container.read(homeFeedProvider);
      expect(state.items.length, 2);
      expect(state.items[0].id, 'v1');
      expect(state.items[1].id, 'v2');
      expect(state.nextPage, 3);
      expect(state.hasMore, false);
    });

    test('loadMore when hasMore false does not call API', () async {
      var getCount = 0;
      final mockClient = _MockClient((_) async {
        getCount++;
        return http.Response(
          jsonEncode({
            'videos': [{'id': 'only', 'title': 'Only'}],
            'page': 1,
            'limit': 20,
            'hasMore': false,
            'nextPage': null,
          }),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();
      expect(getCount, 1);
      await notifier.loadMore();
      await notifier.loadMore();
      expect(getCount, 1);
    });

    test('loadInitial on API error sets error in state', () async {
      final mockClient = _MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Server error'}),
          500,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();

      final state = container.read(homeFeedProvider);
      expect(state.error, isNotNull);
      expect(state.error, contains('500'));
      expect(state.isLoading, false);
    });

    test('clearError clears error', () async {
      final mockClient = _MockClient((_) async {
        return http.Response('', 500);
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              config: ApiConfig(baseUrl: 'https://test'),
              client: mockClient,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadInitial();
      expect(container.read(homeFeedProvider).error, isNotNull);

      notifier.clearError();
      expect(container.read(homeFeedProvider).error, isNull);
    });
  });
}

class _MockClient extends http.BaseClient {
  _MockClient(this._fn);
  final Future<http.Response> Function(http.BaseRequest) _fn;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _fn(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}
