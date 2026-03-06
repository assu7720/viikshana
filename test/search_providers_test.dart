import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/search_provider.dart';
import 'package:viikshana/core/search_history/search_history_repository.dart';

void main() {
  group('searchHistoryRepositoryProvider', () {
    test('returns SearchHistoryRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(searchHistoryRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.getQueries(), isEmpty);
    });
  });

  group('searchHistoryProvider', () {
    test('initial state is empty when repo returns empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(searchHistoryProvider), isEmpty);
    });

    test('addQuery and clear update state when using fake repo', () async {
      final fakeRepo = _FakeSearchHistoryRepository();
      final container = ProviderContainer(
        overrides: [
          searchHistoryRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchHistoryProvider.notifier).addQuery('first');
      expect(container.read(searchHistoryProvider), ['first']);

      await container.read(searchHistoryProvider.notifier).addQuery('second');
      expect(container.read(searchHistoryProvider), ['second', 'first']);

      await container.read(searchHistoryProvider.notifier).clear();
      expect(container.read(searchHistoryProvider), isEmpty);
    });
  });

  group('searchProvider', () {
    test('initial state has empty query, empty suggestions, no submitted, empty videoResults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(searchProvider);
      expect(state.query, '');
      expect(state.suggestions.value, isEmpty);
      expect(state.isLoading, false);
      expect(state.submittedQuery, isNull);
      expect(state.videoResults.value, isEmpty);
      expect(state.isVideoSearching, false);
    });

    test('setQuery with empty string clears suggestions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(searchProvider.notifier).setQuery('x');
      expect(container.read(searchProvider).query, 'x');
      container.read(searchProvider.notifier).setQuery('');
      expect(container.read(searchProvider).query, '');
      expect(container.read(searchProvider).suggestions.value, isEmpty);
    });

    test('setQuery with non-empty triggers suggestions after debounce (mock API)', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(searchProvider.notifier).setQuery('test');
      expect(container.read(searchProvider).query, 'test');

      await Future.delayed(const Duration(milliseconds: 500));

      final state = container.read(searchProvider);
      expect(state.suggestions.value, isEmpty);
      expect(state.isLoading, false);
    });

    test('submitQuery runs video search and adds to history (mock API)', () async {
      final fakeRepo = _FakeSearchHistoryRepository();
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
          searchHistoryRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchProvider.notifier).submitQuery('query');

      expect(container.read(searchProvider).query, 'query');
      expect(container.read(searchProvider).submittedQuery, 'query');
      expect(container.read(searchProvider).videoResults.value, isEmpty);
      expect(container.read(searchHistoryProvider), ['query']);
    });

    test('submitQuery with API returning videos updates videoResults', () async {
      final mockClient = _MockClient((request) async {
        if (request.url.path.contains('videos')) {
          return http.Response(
            jsonEncode({
              'videos': [
                {'id': 'v1', 'title': 'Video One'},
                {'id': 'v2', 'title': 'Video Two'},
              ],
              'page': 1,
              'limit': 20,
              'hasMore': false,
            }),
            200,
          );
        }
        if (request.url.path.contains('suggestions')) {
          return http.Response(jsonEncode(['s1', 's2']), 200);
        }
        return http.Response(
          jsonEncode({
            'videos': [
              {'id': 'v1', 'title': 'Video One'},
              {'id': 'v2', 'title': 'Video Two'},
            ],
            'page': 1,
            'limit': 20,
            'hasMore': false,
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

      await container.read(searchProvider.notifier).submitQuery('hit');

      final state = container.read(searchProvider);
      expect(state.videoResults.value?.length, 2);
      expect(state.videoResults.value!.first.id, 'v1');
      expect(state.videoResults.value!.first.title, 'Video One');
    });

    test('clearError clears error state', () async {
      final mockClient = _MockClient((_) async => http.Response('', 500));
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

      await container.read(searchProvider.notifier).submitQuery('fail');
      expect(container.read(searchProvider).videoResults.hasError, true);

      container.read(searchProvider.notifier).clearError();
      expect(container.read(searchProvider).videoResults.hasError, false);
      expect(container.read(searchProvider).videoResults.value, isEmpty);
    });
  });
}

class _FakeSearchHistoryRepository extends SearchHistoryRepository {
  final List<String> _queries = [];

  @override
  List<String> getQueries() => List.unmodifiable(_queries);

  @override
  Future<void> addQuery(String query) async {
    final t = query.trim();
    if (t.isEmpty) return;
    _queries.remove(t);
    _queries.insert(0, t);
    while (_queries.length > 10) {
      _queries.removeLast();
    }
  }

  @override
  Future<void> clear() async => _queries.clear();
}

class _MockClient extends http.BaseClient {
  _MockClient(this._fn);
  final Future<http.Response> Function(http.BaseRequest) _fn;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _fn(request);
    return http.StreamedResponse(
      Stream.value(r.bodyBytes),
      r.statusCode,
      headers: r.headers,
    );
  }
}
