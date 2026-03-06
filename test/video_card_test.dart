import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viikshana/data/models/video_item.dart';
import 'package:viikshana/shared/components/video_card.dart';
import 'package:viikshana/shared/theme/viikshana_theme.dart';

void main() {
  group('VideoCard', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: ViikshanaTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: child,
          ),
        ),
      );
    }

    testWidgets('displays video title', (tester) async {
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(id: 'v1', title: 'My Video Title'),
          ),
        ),
      );
      expect(find.text('My Video Title'), findsOneWidget);
    });

    testWidgets('displays channel name when present', (tester) async {
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(
              id: 'v1',
              title: 'Video',
              channelName: 'Channel One',
            ),
          ),
        ),
      );
      expect(find.text('Channel One'), findsOneWidget);
    });

    testWidgets('displays view count', (tester) async {
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(
              id: 'v1',
              title: 'Video',
              viewCount: 42,
            ),
          ),
        ),
      );
      expect(find.text('42 views'), findsOneWidget);
    });

    testWidgets('displays K and M for large view counts', (tester) async {
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(
              id: 'v1',
              title: 'Video',
              viewCount: 1500,
            ),
          ),
        ),
      );
      expect(find.text('1.5K views'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(id: 'v1', title: 'Video'),
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(VideoCard));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('has Card and InkWell', (tester) async {
      await tester.pumpWidget(
        wrap(
          VideoCard(
            video: const VideoItem(id: 'v1', title: 'Video'),
          ),
        ),
      );
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
