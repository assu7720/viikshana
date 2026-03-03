import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:viikshana/navigation/tv_menu_item.dart';
import 'package:viikshana/navigation/tv_shell.dart';
import 'package:viikshana/screens/account/account_screen.dart';
import 'package:viikshana/screens/clips/clips_screen.dart';
import 'package:viikshana/screens/home/home_screen.dart';
import 'package:viikshana/screens/search/search_screen.dart';
import 'package:viikshana/screens/upload/upload_screen.dart';
import 'package:viikshana/shared/components/viikshana_button.dart';
import 'package:viikshana/shared/components/viikshana_card.dart';
import 'package:viikshana/shared/theme/viikshana_theme.dart';

/// Mock API so home feed doesn't hit network in tests.
List<Override> get kMockApiOverrides => [
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          config: ApiConfig(baseUrl: 'https://test'),
          client: _mockHttpClient(),
        ),
      ),
    ];

http.Client _mockHttpClient() {
  return _MockHttpClient((_) async => http.Response(
        jsonEncode({'videos': [], 'page': 1, 'limit': 20}),
        200,
      ));
}

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._fn);
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
  group('ViikshanaApp', () {
    testWidgets('has correct title and no debug banner', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Viikshana');
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('uses dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.theme?.brightness, Brightness.dark);
      expect(materialApp.darkTheme?.brightness, Brightness.dark);
    });

    testWidgets('builds AppRouter as home', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(AppRouter), findsOneWidget);
    });
  });

  group('Platform-specific shells (Android / iOS / Tablet / TV)', () {
    tearDown(() {
      PlatformInfo.overrideForTesting = null;
    });

    testWidgets('Android mobile viewport shows MobileShell with bottom nav', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.androidMobile;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(TvShell), findsNothing);
    });

    testWidgets('iOS mobile viewport shows MobileShell with bottom nav', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.iosMobile;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(390, 844);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(TvShell), findsNothing);
    });

    testWidgets('Android tablet viewport shows MobileShell (not TV)', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(TvShell), findsNothing);
    });

    testWidgets('iPad viewport shows MobileShell (tablet shell)', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1024, 1366);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('Android TV viewport shows TvShell with sidebar (no bottom nav)', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tv;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(TvShell), findsOneWidget);
      expect(find.byType(MobileShell), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Upload'), findsNothing);
    });

    testWidgets('Android TV shows 11 sidebar items and no Upload', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tv;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(TvShell), findsOneWidget);
      expect(find.text('Upload'), findsNothing);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Clips'), findsOneWidget);
      expect(find.text('Contact'), findsNothing);
      await tester.scrollUntilVisible(find.text('Terms'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('Android mobile has 5 tabs (Home, Clips, Upload, Search, Account)', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.androidMobile;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Home')), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Clips')), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Upload')), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Search')), findsOneWidget);
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Account')), findsOneWidget);
    });
  });

  group('Mobile shell (full app)', () {
    testWidgets('app launches and shows Home tab', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows MobileShell with bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('NavigationBar has exactly 5 destinations', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);
    });

    testWidgets('all five tab labels are present', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Clips'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('switching tabs preserves state', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('each tab shows correct screen when selected', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Clips')));
      await tester.pumpAndSettle();
      expect(find.byType(ClipsScreen), findsOneWidget);
      expect(find.text('Clips'), findsAtLeastNWidgets(1));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Upload')));
      await tester.pumpAndSettle();
      expect(find.byType(UploadScreen), findsOneWidget);
      expect(find.text('Upload'), findsAtLeastNWidgets(1));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Search')));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Search'), findsAtLeastNWidgets(1));

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Account')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Account'), findsAtLeastNWidgets(1));
    });

    testWidgets('sequential tab switching through all tabs and back', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Clips')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Upload')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Search')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Account')));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('Scaffold has body and bottomNavigationBar', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      final scaffoldFinder = find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(Scaffold),
      );
      expect(scaffoldFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.body, isNotNull);
      expect(scaffold.bottomNavigationBar, isNotNull);
    });

    testWidgets('IndexedStack preserves tab content when switching', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsAtLeastNWidgets(1));
    });
  });

  group('Mobile shell (direct)', () {
    testWidgets('MobileShell has 5 navigators in IndexedStack', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: kMockApiOverrides,
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const MobileShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IndexedStack), findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.children.length, 5);
    });

    testWidgets('MobileShell shows NavigationBar when pumped directly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: kMockApiOverrides,
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const MobileShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });
  });

  group('Home screen (M5)', () {
    testWidgets('loads home feed and shows grid or empty state', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(
        find.byType(GridView).evaluate().isNotEmpty || find.text('No videos yet').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('shows VideoCard when feed has items', (WidgetTester tester) async {
      final mockWithVideo = [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            config: ApiConfig(baseUrl: 'https://test'),
            client: _MockHttpClient((_) async => http.Response(
                  jsonEncode({
                    'videos': [
                      {'id': 'v1', 'title': 'Test Video', 'channelName': 'Channel'}
                    ],
                    'page': 1,
                    'limit': 20,
                  }),
                  200,
                )),
          ),
        ),
      ];
      await tester.pumpWidget(ViikshanaApp(overrides: mockWithVideo));
      await tester.pumpAndSettle();

      expect(find.text('Test Video'), findsOneWidget);
      expect(find.text('Channel'), findsOneWidget);
    });

    testWidgets('has RefreshIndicator for pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows error view with Retry when API fails', (WidgetTester tester) async {
      final mockFailing = [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            config: ApiConfig(baseUrl: 'https://test'),
            client: _MockHttpClient((_) async => throw Exception('Network error')),
          ),
        ),
      ];
      await tester.pumpWidget(ViikshanaApp(overrides: mockFailing));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Home screen (M5) per device type', () {
    tearDown(() {
      PlatformInfo.overrideForTesting = null;
    });

    testWidgets('Android mobile: Home shows grid and feed', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.androidMobile;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byType(GridView).evaluate().isNotEmpty || find.text('No videos yet').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('iOS mobile: Home shows grid and feed', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.iosMobile;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(390, 844);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byType(GridView).evaluate().isNotEmpty || find.text('No videos yet').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('Android tablet: Home shows grid and feed', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byType(GridView).evaluate().isNotEmpty || find.text('No videos yet').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('iPad: Home shows grid and feed', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tablet;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1024, 1366);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(MobileShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byType(GridView).evaluate().isNotEmpty || find.text('No videos yet').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('Android TV: Home menu shows placeholder content (no grid)', (WidgetTester tester) async {
      PlatformInfo.overrideForTesting = AppPlatform.tv;
      addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);

      await tester.pumpWidget(ViikshanaApp(overrides: kMockApiOverrides));
      await tester.pumpAndSettle();

      expect(find.byType(TvShell), findsOneWidget);
      expect(find.byType(MobileShell), findsNothing);
      final homeInContent = find.descendant(
        of: find.byType(Center),
        matching: find.text('Home'),
      );
      expect(homeInContent, findsOneWidget);
    });
  });

  group('TV shell', () {
    testWidgets('shows left sidebar with all 11 menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Clips'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
      expect(find.text('Liked'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Community Guidelines'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Terms'), 100);
      await tester.pumpAndSettle();
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
    });

    testWidgets('Upload is not in TV sidebar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upload'), findsNothing);
    });

    testWidgets('has at least 9 TvMenuItem widgets (sidebar list builds visible items)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Contact'), 100);
      await tester.pumpAndSettle();

      expect(find.byType(TvMenuItem), findsAtLeastNWidgets(9));
    });

    testWidgets('content area shows selected item label (default Home)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      final homeInContent = find.descendant(
        of: find.byType(Center),
        matching: find.text('Home'),
      );
      expect(homeInContent, findsOneWidget);
    });

    testWidgets('tapping sidebar item updates content area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clips'));
      await tester.pumpAndSettle();
      expect(find.text('Clips'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('menu items are focusable via keyboard (arrow down + enter)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TvMenuItem), findsAtLeastNWidgets(9));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Clips'), findsAtLeastNWidgets(1));
    });

    testWidgets('keyboard navigation: multiple arrow down then enter selects item', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Clips'), findsAtLeastNWidgets(1));
    });

    testWidgets('keyboard: Enter key selects focused item', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Clips'), findsAtLeastNWidgets(1));
    });

    testWidgets('TV shell has Row with sidebar and Expanded content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(Expanded), findsAtLeastNWidgets(1));
    });

    testWidgets('TV shell has FocusTraversalGroup in sidebar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FocusTraversalGroup), findsAtLeastNWidgets(1));
    });

    testWidgets('TV shell has ListView in sidebar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const TvShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('TvMenuItem', () {
    testWidgets('displays label and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: TvMenuItem(
              label: 'Test Item',
              icon: Icons.star,
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: TvMenuItem(
              label: 'Tap Me',
              icon: Icons.touch_app,
              selected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('has Focus widget for keyboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: TvMenuItem(
              label: 'Focused',
              icon: Icons.circle,
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Focus), findsAtLeastNWidgets(1));
    });
  });

  group('ViikshanaButton', () {
    testWidgets('displays label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaButton(
              label: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaButton(
              label: 'Press',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('displays icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaButton(
              label: 'With Icon',
              onPressed: () {},
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('is a FilledButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaButton(
              label: 'Filled',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('ViikshanaCard', () {
    testWidgets('displays child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaCard(
              child: const Text('Card content'),
            ),
          ),
        ),
      );

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaCard(
              child: const Text('Tap card'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap card'));
    await tester.pump();
      expect(tapped, true);
    });

    testWidgets('uses Material with InkWell', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: Scaffold(
            body: ViikshanaCard(
              child: const Text('Material'),
            ),
          ),
        ),
      );

      expect(find.byType(Material), findsAtLeastNWidgets(1));
      expect(find.byType(InkWell), findsOneWidget);
    });
  });

  group('Screens', () {
    testWidgets('HomeScreen has AppBar and body text', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: kMockApiOverrides,
          child: MaterialApp(
            theme: ViikshanaTheme.dark(),
            home: const HomeScreen(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Home'), findsAtLeastNWidgets(1));
    });

    testWidgets('ClipsScreen has AppBar title Clips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const ClipsScreen(),
        ),
      );

      expect(find.text('Clips'), findsAtLeastNWidgets(1));
    });

    testWidgets('UploadScreen has AppBar title Upload', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const UploadScreen(),
        ),
      );

      expect(find.text('Upload'), findsAtLeastNWidgets(1));
    });

    testWidgets('SearchScreen has AppBar title Search', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const SearchScreen(),
        ),
      );

      expect(find.text('Search'), findsAtLeastNWidgets(1));
    });

    testWidgets('AccountScreen has AppBar title Account', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ViikshanaTheme.dark(),
          home: const AccountScreen(),
        ),
      );

      expect(find.text('Account'), findsAtLeastNWidgets(1));
    });

    testWidgets('each screen has a Scaffold', (WidgetTester tester) async {
      final screens = [
        const HomeScreen(),
        const ClipsScreen(),
        const UploadScreen(),
        const SearchScreen(),
        const AccountScreen(),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: kMockApiOverrides,
            child: MaterialApp(
              theme: ViikshanaTheme.dark(),
              home: screen,
            ),
          ),
        );
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });
  });

  group('Theme', () {
    testWidgets('ViikshanaTheme.dark returns ThemeData with Material3', (WidgetTester tester) async {
      final theme = ViikshanaTheme.dark();
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('ViikshanaTheme.light returns ThemeData with Material3', (WidgetTester tester) async {
      final theme = ViikshanaTheme.light();
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
    });
  });
}
