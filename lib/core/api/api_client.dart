import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/api/api_exception.dart';
import 'package:viikshana/data/models/home_feed_response.dart';
import 'package:viikshana/data/models/video_detail.dart';

/// HTTP client for ClipsNow API with base URL config, retries, and error handling.
class ApiClient {
  ApiClient({
    ApiConfig? config,
    http.Client? client,
  })  : _config = config ?? ApiConfig(),
        _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

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
    return _parseJson(response, VideoDetail.fromJson);
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
