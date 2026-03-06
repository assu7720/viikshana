import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/api/api_exception.dart';
import 'package:viikshana/data/models/api_user_profile.dart';
import 'package:viikshana/data/models/login_response.dart';
import 'package:viikshana/data/models/home_feed_response.dart';
import 'package:viikshana/data/models/video_detail.dart';
import 'package:viikshana/data/models/comment.dart';

/// HTTP client for ClipsNow API with base URL config, retries, and error handling.
class ApiClient {
  ApiClient({
    ApiConfig? config,
    http.Client? client,
    this.getAccessToken,
  })  : _config = config ?? ApiConfig(),
        _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// When set, used for `Authorization: Bearer <token>` on GET /auth/api/me and other authenticated calls.
  final String? Function()? getAccessToken;

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// GET /api/home/videos with pagination.
  /// Non-blocking: throws [ApiException] on failure.
  /// When [ApiConfig.isMock] is true (e.g. VIIKSHANA_API_BASE_URL=), returns empty feed without network.
  Future<HomeFeedResponse> getHomeFeed({
    int page = 1,
    int limit = 20,
  }) async {
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getHomeFeed (mock): no network call');
      return HomeFeedResponse(videos: const [], page: page, limit: limit);
    }
    final uri = _config.homeFeedUrl(page: page, limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final result = _parseJson(response, HomeFeedResponse.fromJson);
    if (kDebugMode) debugPrint('[API] getHomeFeed returned: ${result.videos.length} videos (page=$page)');
    return result;
  }

  /// GET /videos/{id}.
  /// Non-blocking: throws [ApiException] on failure.
  /// When [ApiConfig.isMock] is true, returns a stub detail with a sample HLS URL for playback testing.
  Future<VideoDetail> getVideo(String id) async {
    if (id.isEmpty) throw ApiException('Video id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getVideo (mock): no network call');
      return VideoDetail(
        id: id,
        title: 'Sample (mock)',
        hlsUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      );
    }
    final uri = _config.videoUrl(id);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final map = _parseJson(response, (m) => m);
    final data = map['data'];
    final videoMap = data is Map<String, dynamic> ? data : map;
    return VideoDetail.fromJson(videoMap);
  }

  /// GET /search/suggestions?q=...&limit=8
  /// Returns list of suggestion strings. Parses array or { suggestions: [] } or { data: [] }.
  Future<List<String>> getSearchSuggestions(String q, {int limit = 8}) async {
    if (q.trim().isEmpty) return [];
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getSearchSuggestions (mock): no network call');
      return [];
    }
    final uri = _config.searchSuggestionsUrl(q.trim(), limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final list = _parseSuggestionsResponse(response);
    if (kDebugMode) debugPrint('[API] getSearchSuggestions returned: ${list.length}');
    return list;
  }

  List<String> _parseSuggestionsResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return [];
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final raw = decoded['suggestions'] ?? decoded['data'] ?? decoded['results'];
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim())
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
      }
    }
    return [];
  }

  /// GET /api/search/videos?q=...
  /// Returns same shape as home feed (regularVideos / videos, hasMore, nextPage).
  /// When [ApiConfig.isMock] is true, returns empty results without network.
  Future<HomeFeedResponse> searchVideos(String q, {int page = 1, int limit = 20}) async {
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] searchVideos (mock): no network call');
      return HomeFeedResponse(videos: const [], page: page, limit: limit);
    }
    final uri = _config.searchVideosUrl(q, page: page, limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final result = _parseJson(response, HomeFeedResponse.fromJson);
    if (kDebugMode) debugPrint('[API] searchVideos returned: ${result.videos.length} (page=$page)');
    return result;
  }

  /// GET /api/videos/{id}/comments (paginated).
  /// When [ApiConfig.isMock] is true, returns empty comments without network.
  Future<VideoCommentsResponse> getVideoComments(
    String videoId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (videoId.isEmpty) return const VideoCommentsResponse();
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getVideoComments (mock): no network call');
      return const VideoCommentsResponse();
    }
    final uri = _config.videoCommentsUrl(videoId, page: page, limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final result = _parseJson(response, VideoCommentsResponse.fromJson);
    if (kDebugMode) debugPrint('[API] getVideoComments returned: ${result.comments.length}');
    return result;
  }

  /// GET /api/video/{id}/related. Returns same shape as home feed.
  /// When [ApiConfig.isMock] is true, returns empty list without network.
  Future<HomeFeedResponse> getRelatedVideos(String videoId) async {
    if (videoId.isEmpty) return const HomeFeedResponse(videos: []);
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getRelatedVideos (mock): no network call');
      return const HomeFeedResponse(videos: []);
    }
    final uri = _config.relatedVideosUrl(videoId);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final response = await _request(() => _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final result = _parseJson(response, HomeFeedResponse.fromJson);
    if (kDebugMode) debugPrint('[API] getRelatedVideos returned: ${result.videos.length}');
    return result;
  }

  /// POST /auth/api/login. Sends { email, password }.
  /// On 200: returns [LoginResponse] with user and tokens. On 400/401/4xx: throws [ApiException].
  /// When [ApiConfig.isMock] is true, skips network and returns a stub.
  Future<LoginResponse> login(String email, String password) async {
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] login (mock): no network call');
      return const LoginResponse(success: true);
    }
    final uri = _config.authLoginUrl;
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri');
    final body = jsonEncode({'email': email, 'password': password});
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map != null) {
        if (kDebugMode) {
          final topKeys = map.keys.toList().join(', ');
          final data = map['data'];
          final dataKeys = data is Map ? data.keys.toList().join(', ') : null;
          debugPrint('[API] login response keys: {$topKeys}${dataKeys != null ? ' data: {$dataKeys}' : ''}');
        }
        final loginResponse = LoginResponse.fromJson(map);
        if (kDebugMode) {
          debugPrint('[API] login: ${loginResponse.accessToken != null ? "tokens parsed" : "no tokens in response"}');
        }
        return loginResponse;
      }
      return const LoginResponse(success: true);
    }
    final requiresLogin = _parseRequiresLogin(response.body);
    throw ApiException(
      'Login failed: ${response.statusCode}',
      statusCode: response.statusCode,
      requiresLogin: requiresLogin,
    );
  }

  /// Clears stored session (call on sign-out). No-op for token-based auth; tokens are cleared via [SessionRepository].
  void clearSession() {}

  /// GET /auth/api/me. Returns current user profile when session is valid.
  /// Uses `Authorization: Bearer <token>` when [getAccessToken] is set. Returns null on 401 or when mock.
  Future<ApiUserProfile?> getMe() async {
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getMe (mock): no network call');
      return null;
    }
    final uri = _config.authMeUrl;
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final headers = <String, String>{};
    final token = getAccessToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _client.get(uri, headers: headers.isEmpty ? null : headers);
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    if (response.statusCode == 401) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Profile request failed: ${response.statusCode}', statusCode: response.statusCode);
    }
    final map = _parseJson(response, (m) => m);
    final data = map['data'];
    final profileMap = data is Map<String, dynamic> ? data : map;
    return ApiUserProfile.fromJson(profileMap);
  }

  Future<http.Response> _request(Future<http.Response> Function() call) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await call();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        final requiresLogin = _parseRequiresLogin(response.body);
        throw ApiException(
          'Request failed: ${response.statusCode}',
          statusCode: response.statusCode,
          requiresLogin: requiresLogin,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[API] ERROR: $e');
        if (e is ApiException) rethrow;
        final isRetryable = _isRetryable(e);
        if (isRetryable && attempt < _maxRetries) {
          attempt++;
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        throw ApiException(e.toString());
      }
    }
  }

  bool _isRetryable(Object e) {
    if (e is http.ClientException) return true;
    if (e is FormatException) return false;
    return false;
  }

  bool _parseRequiresLogin(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      return map?['requiresLogin'] == true;
    } catch (_) {
      return false;
    }
  }

  T _parseJson<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) throw const FormatException('Empty or invalid JSON');
      return fromJson(map);
    } on FormatException catch (e) {
      throw ApiException('Invalid response: $e');
    }
  }
}
