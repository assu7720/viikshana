import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/player_providers.dart';
import 'package:viikshana/core/providers/video_detail_provider.dart';

void main() {
  group('fullScreenPlayerProvider', () {
    test('initial state is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(fullScreenPlayerProvider), false);
    });

    test('notifier updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(fullScreenPlayerProvider.notifier).state = true;
      expect(container.read(fullScreenPlayerProvider), true);
      container.read(fullScreenPlayerProvider.notifier).state = false;
      expect(container.read(fullScreenPlayerProvider), false);
    });
  });

  group('watchHistoryRepositoryProvider', () {
    test('returns WatchHistoryRepository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(watchHistoryRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.getPosition('any'), 0);
    });
  });

  group('videoDetailProvider', () {
    test('loads VideoDetail from API', () async {
      final mockClient = _MockClient((_) async => http.Response(
            jsonEncode({
              'id': 'vd1',
              'title': 'Test Video',
              'hlsUrl': 'https://example.com/play.m3u8',
            }),
            200,
          ));
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: 'https://test'), client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detailAsync = container.read(videoDetailProvider('vd1'));
      expect(detailAsync.hasValue, false);
      expect(detailAsync.isLoading, true);

      final detail = await container.read(videoDetailProvider('vd1').future);
      expect(detail.id, 'vd1');
      expect(detail.title, 'Test Video');
      expect(detail.hlsUrl, 'https://example.com/play.m3u8');
    });

    test('mock config returns stub detail with HLS URL', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(videoDetailProvider('stub-id').future);
      expect(detail.id, 'stub-id');
      expect(detail.title, 'Sample (mock)');
      expect(detail.hlsUrl, isNotNull);
      expect(detail.hlsUrl!, contains('m3u8'));
    });

    test('family uses different videoId', () async {
      final mockClient = _MockClient((request) async {
        final id = request.url.pathSegments.last;
        return http.Response(
          jsonEncode({'id': id, 'title': 'Video $id', 'hlsUrl': 'https://hls/$id.m3u8'}),
          200,
        );
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: 'https://test'), client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final a = await container.read(videoDetailProvider('id-a').future);
      final b = await container.read(videoDetailProvider('id-b').future);
      expect(a.id, 'id-a');
      expect(b.id, 'id-b');
      expect(a.hlsUrl, 'https://hls/id-a.m3u8');
      expect(b.hlsUrl, 'https://hls/id-b.m3u8');
    });
  });

  group('relatedVideosProvider', () {
    test('loads related videos from API', () async {
      final mockClient = _MockClient((request) async {
        if (request.url.path.contains('related')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'relatedVideos': [
                {'id': 'r1', 'title': 'Related One', 'views': 1, 'channel': {'id': 1, 'name': 'Ch'}},
                {'id': 'r2', 'title': 'Related Two', 'views': 2, 'channel': {'id': 1, 'name': 'Ch'}},
              ],
              'hasMore': false,
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: 'https://test'), client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(relatedVideosProvider('vid1').future);
      expect(response.videos.length, 2);
      expect(response.videos[0].id, 'r1');
      expect(response.videos[0].title, 'Related One');
      expect(response.videos[1].id, 'r2');
    });

    test('mock config returns empty related', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(relatedVideosProvider('any').future);
      expect(response.videos, isEmpty);
    });
  });

  group('videoCommentsProvider', () {
    test('loads comments from API', () async {
      final mockClient = _MockClient((request) async {
        if (request.url.path.contains('comments')) {
          return http.Response(
            jsonEncode({
              'comments': [
                {'id': 1, 'videoId': 'v1', 'userId': 10, 'text': 'First comment', 'username': 'u1'},
                {'id': 2, 'videoId': 'v1', 'userId': 20, 'text': 'Second', 'username': 'u2'},
              ],
              'page': 1,
              'total': 2,
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: 'https://test'), client: mockClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(videoCommentsProvider('v1').future);
      expect(response.comments.length, 2);
      expect(response.comments[0].text, 'First comment');
      expect(response.comments[0].username, 'u1');
      expect(response.comments[1].text, 'Second');
      expect(response.page, 1);
      expect(response.total, 2);
    });

    test('mock config returns empty comments', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(config: ApiConfig(baseUrl: '')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(videoCommentsProvider('any').future);
      expect(response.comments, isEmpty);
      expect(response.page, 1);
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
