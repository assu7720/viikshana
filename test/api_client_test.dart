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

    test('searchVideosUrl includes q, page, limit', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.searchVideosUrl('hello', page: 1, limit: 20);
      expect(uri.path, '/api/search/videos');
      expect(uri.queryParameters['q'], 'hello');
      expect(uri.queryParameters['page'], '1');
      expect(uri.queryParameters['limit'], '20');
    });

    test('searchSuggestionsUrl includes q and limit', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.searchSuggestionsUrl('tel', limit: 8);
      expect(uri.path, '/search/suggestions');
      expect(uri.queryParameters['q'], 'tel');
      expect(uri.queryParameters['limit'], '8');
    });

    test('resolveMediaUrl returns full URL unchanged', () {
      const full = 'https://videoprocess.viikshana.com/processed/abc/thumb.jpg';
      expect(ApiConfig.resolveMediaUrl(full), full);
      expect(ApiConfig.resolveMediaUrl('http://other.com/x'), 'http://other.com/x');
    });

    test('resolveMediaUrl prepends mediaBaseUrl for relative path', () {
      expect(
        ApiConfig.resolveMediaUrl('/processed/xyz/thumb.jpg'),
        'https://videoprocess.viikshana.com/processed/xyz/thumb.jpg',
      );
      expect(
        ApiConfig.resolveMediaUrl('processed/rel.jpg'),
        'https://videoprocess.viikshana.com/processed/rel.jpg',
      );
    });

    test('resolveMediaUrl returns empty for null or empty', () {
      expect(ApiConfig.resolveMediaUrl(null), '');
      expect(ApiConfig.resolveMediaUrl(''), '');
    });

    test('resolveApiAssetUrl returns full URL unchanged', () {
      const full = 'https://example.com/processed/channels/logo.jpg';
      expect(ApiConfig.resolveApiAssetUrl(full, 'http://api.test'), full);
      expect(ApiConfig.resolveApiAssetUrl('http://other.com/x', 'http://api.test'), 'http://other.com/x');
    });

    test('resolveApiAssetUrl prepends baseUrl for relative path', () {
      expect(
        ApiConfig.resolveApiAssetUrl('/processed/channels/logo-123.jpg', 'http://10.0.2.2:3000'),
        'http://10.0.2.2:3000/processed/channels/logo-123.jpg',
      );
      expect(
        ApiConfig.resolveApiAssetUrl('processed/rel.jpg', 'https://api.test'),
        'https://api.test/processed/rel.jpg',
      );
    });

    test('resolveApiAssetUrl with empty baseUrl returns path unchanged', () {
      expect(
        ApiConfig.resolveApiAssetUrl('/processed/channels/logo.jpg', ''),
        '/processed/channels/logo.jpg',
      );
    });

    test('resolveApiAssetUrl returns empty for null or empty urlOrPath', () {
      expect(ApiConfig.resolveApiAssetUrl(null, 'http://api.test'), '');
      expect(ApiConfig.resolveApiAssetUrl('', 'http://api.test'), '');
    });

    test('videoCommentsUrl builds path with videoId and page', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.videoCommentsUrl('vid-1', page: 2, limit: 10);
      expect(uri.path, '/api/videos/vid-1/comments');
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['limit'], '10');
    });

    test('relatedVideosUrl builds path', () {
      final config = ApiConfig(baseUrl: 'https://api.test');
      final uri = config.relatedVideosUrl('vid-2');
      expect(uri.path, '/api/video/vid-2/related');
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

    test('getVideo in mock mode returns stub with sample HLS URL', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: ''));
      final detail = await client.getVideo('any-id');
      expect(detail.id, 'any-id');
      expect(detail.title, 'Sample (mock)');
      expect(detail.hlsUrl, isNotNull);
      expect(detail.hlsUrl, contains('m3u8'));
    });

    test('getVideo unwraps success/data wrapper and uses hlsPath', () async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'ZqY5Tz',
              'title': 'Bhojpuri Song',
              'hlsPath': 'https://videoprocess.viikshana.com/processed/ZqY5Tz/master.m3u8',
              'views': 1,
              'duration': '213.000',
            },
          }),
          200,
        );
      });
      final client = ApiClient(client: mockClient);
      final detail = await client.getVideo('ZqY5Tz');
      expect(detail.id, 'ZqY5Tz');
      expect(detail.title, 'Bhojpuri Song');
      expect(detail.hlsUrl, 'https://videoprocess.viikshana.com/processed/ZqY5Tz/master.m3u8');
      expect(detail.viewCount, 1);
      expect(detail.durationSeconds, 213);
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

    test('searchVideos in mock mode returns empty list', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: ''));
      final result = await client.searchVideos('test');
      expect(result.videos, isEmpty);
      expect(result.page, 1);
    });

    test('getSearchSuggestions returns empty for empty query', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: 'https://test'));
      final result = await client.getSearchSuggestions('');
      expect(result, isEmpty);
    });

    test('getSearchSuggestions in mock mode returns empty', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: ''));
      final result = await client.getSearchSuggestions('tel');
      expect(result, isEmpty);
    });

    test('getSearchSuggestions parses array response', () async {
      final mockClient = _MockClient((request) async {
        expect(request.url.queryParameters['q'], 'tel');
        return http.Response(jsonEncode(['telugu', 'telugu songs', 'telugu movies']), 200);
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://test'),
        client: mockClient,
      );
      final result = await client.getSearchSuggestions('tel', limit: 8);
      expect(result, ['telugu', 'telugu songs', 'telugu movies']);
    });

    test('getSearchSuggestions parses object with suggestions key', () async {
      final mockClient = _MockClient((_) async {
        return http.Response(
          jsonEncode({'suggestions': ['a', 'b']}),
          200,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://test'),
        client: mockClient,
      );
      final result = await client.getSearchSuggestions('x');
      expect(result, ['a', 'b']);
    });

    test('searchVideos parses success response', () async {
      final mockClient = _MockClient((request) async {
        expect(request.url.queryParameters['q'], 'query');
        return http.Response(
          jsonEncode({
            'videos': [
              {'id': 's1', 'title': 'Search Result'}
            ],
            'page': 1,
            'limit': 20,
            'hasMore': false,
          }),
          200,
        );
      });
      final client = ApiClient(client: mockClient);
      final result = await client.searchVideos('query');
      expect(result.videos.length, 1);
      expect(result.videos.first.id, 's1');
      expect(result.videos.first.title, 'Search Result');
    });

    test('searchVideos parses SearchVideosResponse with data array (new API)', () async {
      final mockClient = _MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 'v1', 'title': 'Video One', 'views': 100},
              {'id': 'v2', 'title': 'Video Two', 'views': 200},
            ],
            'hasMore': false,
            'nextPage': null,
          }),
          200,
        );
      });
      final client = ApiClient(client: mockClient);
      final result = await client.searchVideos('q');
      expect(result.videos.length, 2);
      expect(result.videos[0].id, 'v1');
      expect(result.videos[0].title, 'Video One');
      expect(result.videos[1].id, 'v2');
      expect(result.hasMore, false);
    });

    test('login parses success response with data.tokens', () async {
      final mockClient = _MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/api/login');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'user': {'id': 1, 'email': 'u@test.com', 'username': 'u1'},
              'tokens': {
                'accessToken': 'access-123',
                'refreshToken': 'refresh-456',
              },
            },
          }),
          200,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
      );
      final res = await client.login('u@test.com', 'pass');
      expect(res.success, true);
      expect(res.accessToken, 'access-123');
      expect(res.refreshToken, 'refresh-456');
      expect(res.user?.email, 'u@test.com');
      expect(res.user?.username, 'u1');
    });

    test('login throws ApiException on 401', () async {
      final mockClient = _MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Invalid credentials', 'requiresLogin': true}),
          401,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
      );
      expect(
        () => client.login('a@b.com', 'wrong'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.requiresLogin, 'requiresLogin', true),
        ),
      );
    });

    test('login throws ApiException on 400', () async {
      final mockClient = _MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Bad request'}),
          400,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
      );
      expect(
        () => client.login('a@b.com', 'p'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('login 200 with null body returns stub success', () async {
      final mockClient = _MockClient((_) async => http.Response('null', 200));
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
      );
      final res = await client.login('a@b.com', 'p');
      expect(res.success, true);
      expect(res.accessToken, isNull);
      expect(res.refreshToken, isNull);
    });

    test('login in mock mode returns stub without tokens', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: ''));
      final res = await client.login('any@x.com', 'any');
      expect(res.success, true);
      expect(res.accessToken, isNull);
      expect(res.refreshToken, isNull);
    });

    test('getMe returns profile when 200 with Bearer token', () async {
      final mockClient = _MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/auth/api/me');
        expect(request.headers['Authorization'], 'Bearer token-xyz');
        return http.Response(
          jsonEncode({
            'data': {
              'id': 10,
              'email': 'me@test.com',
              'username': 'me',
              'name': 'Me User',
            },
          }),
          200,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
        getAccessToken: () => 'token-xyz',
      );
      final profile = await client.getMe();
      expect(profile, isNotNull);
      expect(profile!.id, 10);
      expect(profile.email, 'me@test.com');
      expect(profile.username, 'me');
      expect(profile.name, 'Me User');
    });

    test('getMe returns null on 401', () async {
      final mockClient = _MockClient((_) async => http.Response('', 401));
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
        getAccessToken: () => 'token',
      );
      final profile = await client.getMe();
      expect(profile, isNull);
    });

    test('getMe parses profile at top level when no data wrapper', () async {
      final mockClient = _MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer t');
        return http.Response(
          jsonEncode({'id': 7, 'email': 'top@test.com', 'username': 'top'}),
          200,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
        getAccessToken: () => 't',
      );
      final profile = await client.getMe();
      expect(profile, isNotNull);
      expect(profile!.id, 7);
      expect(profile.email, 'top@test.com');
      expect(profile.username, 'top');
    });

    test('getMe sends no Authorization header when getAccessToken is null', () async {
      final mockClient = _MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response(
          jsonEncode({'data': {'id': 1, 'email': 'n@x.com'}}),
          200,
        );
      });
      final client = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.test'),
        client: mockClient,
      );
      final profile = await client.getMe();
      expect(profile, isNotNull);
      expect(profile!.id, 1);
    });

    test('getMe in mock mode returns null', () async {
      final client = ApiClient(config: ApiConfig(baseUrl: ''));
      final profile = await client.getMe();
      expect(profile, isNull);
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
