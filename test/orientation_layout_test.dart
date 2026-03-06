import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/misc.dart' show Override;
import 'package:viikshana/app/viikshana_app.dart';
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/platform/platform_info.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/navigation/app_router.dart';
import 'package:viikshana/navigation/mobile_shell.dart';
import 'package:viikshana/screens/home/home_screen.dart';
import 'package:viikshana/shared/components/video_card.dart';

/// Mock that returns [videoCount] videos for home feed and search.
List<Override> _mockFeedOverrides(int videoCount) {
  return [
    apiClientProvider.overrideWith(
      (ref) => ApiClient(
        config: ApiConfig(baseUrl: 'https://test'),
        client: _MockClient((request) async {
          final path = request.url.path;
          if (path.contains('/api/home/videos')) {
            final list = List.generate(
              videoCount,
              (i) => {
                'id': 'v$i',
                'title': 'Video $i',
                'thumbnailHome': 'https://example.com/t$i.jpg',
                'views': 0,
                'channel': {'id': 1, 'name': 'Channel'},
              },
            );
            return http.Response(
              jsonEncode({'videos': list, 'page': 1, 'limit': 20, 'hasMore': false}),
              200,
            );
          }
          if (path.contains('/api/search/videos')) {
            final list = List.generate(
              videoCount,
              (i) => {
                'id': 's$i',
                'title': 'Search Video $i',
                'thumbnailHome': 'https://example.com/s$i.jpg',
                'views': 0,
                'channel': {'id': 1, 'name': 'Channel'},
              },
            );
            return http.Response(
              jsonEncode({'data': list, 'videos': list, 'page': 1, 'limit': 20, 'hasMore': false}),
              200,
            );
          }
          if (path.contains('/search/suggestions')) {
            return http.Response(jsonEncode(['suggestion1']), 200);
          }
          return http.Response(jsonEncode({'videos': []}), 200);
        }),
      ),
    ),
  ];
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

void main() {
  group('Orientation and layout', () {
    tearDown(() {
      PlatformInfo.overrideForTesting = null;
    });

    testWidgets('Home portrait (narrow): single column grid', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(3)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      final feedListView = find.descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(ListView),
      );
      expect(feedListView, findsOneWidget);
      final rows = find.descendant(of: feedListView, matching: find.byType(Row));
      expect(rows, findsWidgets);
      final firstRow = tester.widget<Row>(rows.first);
      expect(firstRow.children.length, 1);
    });

    testWidgets('Home landscape (wider): no overflow and feed loads', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(3)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home tablet portrait (600dp): grid shows video cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 800);
      addTearDown(() => tester.view.resetPhysicalSize());
      PlatformInfo.overrideForTesting = AppPlatform.tablet;

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(3)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(VideoCard), findsAtLeast(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home wide (1200+): grid shows video cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(() => tester.view.resetPhysicalSize());
      PlatformInfo.overrideForTesting = AppPlatform.tablet;

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(5)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(VideoCard), findsAtLeast(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppRouter shows MobileShell in portrait and landscape (non-TV)', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(0)));
      await tester.pumpAndSettle();
      expect(find.byType(AppRouter), findsOneWidget);
      expect(find.byType(MobileShell), findsOneWidget);

      tester.view.physicalSize = const Size(640, 360);
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpAndSettle();
      expect(find.byType(MobileShell), findsOneWidget);
    });

    testWidgets('Portrait layout does not overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(5)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Landscape layout does not overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(640, 360);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(ViikshanaApp(overrides: _mockFeedOverrides(5)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
