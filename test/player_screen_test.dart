import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/screens/player/player_screen.dart';
import 'package:viikshana/shared/theme/viikshana_theme.dart';

void main() {
  group('PlayerScreen', () {
    testWidgets('shows AppBar with Video title and back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const PlayerScreen(videoId: 'test-id'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Video'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows loading then player content when detail loads', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const PlayerScreen(videoId: 'test-id'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No playable stream'), findsNothing);
      expect(find.textContaining('Could not load video'), findsNothing);
    });

    testWidgets('shows error view when video detail fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: _MockClient((_) async => http.Response('', 404)),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const PlayerScreen(videoId: 'missing'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.textContaining('Could not load video'), findsOneWidget);
    });

    testWidgets('Back button pops route', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerScreen(videoId: 'id'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('shows No playable stream when detail has empty hlsUrl', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                config: ApiConfig(baseUrl: 'https://test'),
                client: _MockClient((_) async => http.Response(
                      jsonEncode({'id': 'v1', 'title': 'No HLS', 'hlsUrl': ''}),
                      200,
                    )),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const PlayerScreen(videoId: 'v1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No playable stream'), findsOneWidget);
    });
  });
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
