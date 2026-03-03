import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/api/api_exception.dart';

void main() {
  group('ApiConfig', () {
    test('homeFeedUrl includes page and limit', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.homeFeedUrl(page: 2, limit: 10);
      expect(uri.toString(), contains('page=2'));
      expect(uri.toString(), contains('limit=10'));
      expect(uri.path, '/api/home/videos');
    });

    test('limit is clamped to 100', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.homeFeedUrl(page: 1, limit: 200);
      expect(uri.toString(), contains('limit=100'));
    });

    test('videoUrl builds correct path', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.videoUrl('vid-123');
      expect(uri.path, '/videos/vid-123');
    });
  });

  group('ApiClient', () {
    test('getVideo throws for empty id', () async {
      final client = ApiClient();
      expect(
        () => client.getVideo(''),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('required'))),
      );
    });

    test('getHomeFeed parses success response', () async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode({
            'videos': [
              {'id': 'v1', 'title': 'Home Video'}
            ],
            'page': 1,
            'limit': 20,
          }),
          200,
        );
      });
      final client = ApiClient(client: mockClient);
      final feed = await client.getHomeFeed();
      expect(feed.videos.length, 1);
      expect(feed.videos.first.id, 'v1');
      expect(feed.videos.first.title, 'Home Video');
    });

    test('getVideo parses success response', () async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'vd1',
            'title': 'Detail',
            'hlsUrl': 'https://hls.example.com/master.m3u8',
          }),
          200,
        );
      });
      final client = ApiClient(client: mockClient);
      final detail = await client.getVideo('vd1');
      expect(detail.id, 'vd1');
      expect(detail.title, 'Detail');
      expect(detail.hlsUrl, 'https://hls.example.com/master.m3u8');
    });

    test('non-2xx throws ApiException with requiresLogin when present', () async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode({'requiresLogin': true, 'message': 'Please sign in'}),
          401,
        );
      });
      final client = ApiClient(client: mockClient);
      expect(
        () => client.getHomeFeed(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.requiresLogin, 'requiresLogin', true)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('invalid JSON throws ApiException', () async {
      final mockClient = _MockClient((request) async {
        return http.Response('not json', 200);
      });
      final client = ApiClient(client: mockClient);
      expect(
        () => client.getHomeFeed(),
        throwsA(isA<ApiException>()),
      );
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
