import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/search_provider.dart';
import 'package:viikshana/core/search_history/search_history_repository.dart';
import 'package:viikshana/screens/search/search_screen.dart';
import 'package:viikshana/shared/theme/viikshana_theme.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('shows AppBar title Search and search field with hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Search'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search videos...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('when no history shows placeholder text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Search history will appear here'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('when has history shows Recent and Clear', (WidgetTester tester) async {
      final fakeRepo = _FakeSearchHistoryRepository();
      await fakeRepo.addQuery('past query');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
            searchHistoryRepositoryProvider.overrideWith((ref) => fakeRepo),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('past query'), findsOneWidget);
    });

    testWidgets('typing and waiting debounce shows no results when API returns empty', (WidgetTester tester) async {
      final mockClient = _MockClient((_) async {
        return http.Response(jsonEncode([]), 200);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: mockClient,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('No results for "test"'), findsOneWidget);
    });

    testWidgets('when API returns suggestions shows list of suggestions', (WidgetTester tester) async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode(['Video One', 'Video Two']),
          200,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: mockClient,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'query');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('Video One'), findsOneWidget);
      expect(find.text('Video Two'), findsOneWidget);
    });

    testWidgets('when API errors shows message and Retry button', (WidgetTester tester) async {
      final mockClient = _MockClient((request) async {
        return http.Response('Server error', 500);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: mockClient,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'fail');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('on submit shows video grid when API returns videos', (WidgetTester tester) async {
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
          return http.Response(jsonEncode(['query']), 200);
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: mockClient,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'query');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'query'));
      await tester.pumpAndSettle();

      expect(find.text('Video One'), findsOneWidget);
      expect(find.text('Video Two'), findsOneWidget);
    });

    testWidgets('tap Clear removes history list', (WidgetTester tester) async {
      final fakeRepo = _FakeSearchHistoryRepository();
      await fakeRepo.addQuery('old');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
            searchHistoryRepositoryProvider.overrideWith((ref) => fakeRepo),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('old'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Recent'), findsNothing);
      expect(find.text('Search history will appear here'), findsOneWidget);
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
