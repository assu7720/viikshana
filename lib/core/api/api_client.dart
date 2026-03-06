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
import 'package:viikshana/data/models/engagement_responses.dart';

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

  /// In debug mode, log response status and body (truncated).
  void _logResponse(String label, http.Response response, {String? extra}) {
    if (!kDebugMode) return;
    final body = response.body.trim();
    final truncated = body.length > 800 ? '${body.substring(0, 800)}... (${body.length} chars)' : body;
    debugPrint('[API] $label RESPONSE: ${response.statusCode}');
    debugPrint('[API] $label BODY: ${truncated.isEmpty ? "(empty)" : truncated}');
    if (extra != null) debugPrint('[API] $label $extra');
  }

  /// GET /api/home/videos with pagination.
  /// Non-blocking: throws [ApiException] on failure.
  /// When [ApiConfig.isMock] is true (e.g. VIIKSHANA_API_BASE_URL=), returns empty feed without network.
  /// Sends auth token when available so backend can personalize (e.g. likedByMe, subscribedToChannel).
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
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
    _logResponse('getHomeFeed', response);
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
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
    _logResponse('getVideo', response);
    final map = _parseJson(response, (m) => m);
    final data = map['data'];
    final videoMap = data is Map<String, dynamic> ? data : map;
    return VideoDetail.fromJson(videoMap);
  }

  /// GET /search/suggestions?q=...&limit=8
  /// Returns list of suggestion strings. Parses array or { suggestions: [] } or { data: [] }.
  /// Sends auth token when available.
  Future<List<String>> getSearchSuggestions(String q, {int limit = 8}) async {
    if (q.trim().isEmpty) return [];
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getSearchSuggestions (mock): no network call');
      return [];
    }
    final uri = _config.searchSuggestionsUrl(q.trim(), limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
    _logResponse('getSearchSuggestions', response);
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
  /// Sends auth token when available so backend can include likedByMe, subscribedToChannel on items.
  Future<HomeFeedResponse> searchVideos(String q, {int page = 1, int limit = 20}) async {
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] searchVideos (mock): no network call');
      return HomeFeedResponse(videos: const [], page: page, limit: limit);
    }
    final uri = _config.searchVideosUrl(q, page: page, limit: limit);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
    if (kDebugMode) debugPrint('[API] RESPONSE: ${response.statusCode} ${uri.path}');
    final result = _parseJson(response, HomeFeedResponse.fromJson);
    if (kDebugMode) debugPrint('[API] searchVideos returned: ${result.videos.length} (page=$page)');
    return result;
  }

  /// GET /api/videos/{id}/comments (paginated).
  /// When [ApiConfig.isMock] is true, returns empty comments without network.
  /// Sends auth token when available.
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
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
    _logResponse('getVideoComments', response);
    final result = _parseJson(response, VideoCommentsResponse.fromJson);
    if (kDebugMode) debugPrint('[API] getVideoComments returned: ${result.comments.length}');
    return result;
  }

  /// GET /api/video/{id}/related. Returns same shape as home feed.
  /// When [ApiConfig.isMock] is true, returns empty list without network.
  /// Sends auth token when available so backend can include likedByMe, subscribedToChannel on items.
  Future<HomeFeedResponse> getRelatedVideos(String videoId) async {
    if (videoId.isEmpty) return const HomeFeedResponse(videos: []);
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] getRelatedVideos (mock): no network call');
      return const HomeFeedResponse(videos: []);
    }
    final uri = _config.relatedVideosUrl(videoId);
    if (kDebugMode) debugPrint('[API] OUTGOING: GET $uri');
    final headers = _authHeaders();
    final response = await _request(() => headers != null ? _client.get(uri, headers: headers) : _client.get(uri));
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
    final body = jsonEncode({'email': email, 'password': password});
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    _logResponse('login', response);
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
          debugPrint('[API] login parsed: tokens=${loginResponse.accessToken != null}');
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
    final headers = _authHeaders();
    final response = headers != null
        ? await _client.get(uri, headers: headers)
        : await _client.get(uri);
    _logResponse('getMe', response);
    if (response.statusCode == 401) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Profile request failed: ${response.statusCode}', statusCode: response.statusCode);
    }
    final map = _parseJson(response, (m) => m);
    final data = map['data'];
    final profileMap = data is Map<String, dynamic> ? data : map;
    if (kDebugMode) debugPrint('[API] getMe parsed: id=${profileMap['id']}');
    return ApiUserProfile.fromJson(profileMap);
  }

  /// Returns Authorization Bearer header when [getAccessToken] supplies a token; null otherwise.
  Map<String, String>? _authHeaders() {
    final token = getAccessToken?.call();
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  /// Throws [ApiException] on non-2xx. Use for authenticated endpoints.
  Future<http.Response> _authRequest(Future<http.Response> Function() call) async {
    final response = await call();
    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    if (kDebugMode) debugPrint('[API] _authRequest error body: ${response.body.length > 400 ? '${response.body.substring(0, 400)}...' : response.body}');
    final requiresLogin = _parseRequiresLogin(response.body);
    throw ApiException(
      'Request failed: ${response.statusCode}',
      statusCode: response.statusCode,
      requiresLogin: requiresLogin,
    );
  }

  /// POST /api/videos/{id}/like — toggle like. Auth required. Returns updated counts.
  Future<LikeVideoResult> likeVideo(String videoId) async {
    if (videoId.isEmpty) throw ApiException('Video id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] likeVideo (mock): no network call');
      return LikeVideoResult(likes: 0, liked: true);
    }
    final uri = _config.videoLikeUrl(videoId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri (Bearer token length: ${headers['Authorization']?.length ?? 0})');
    final response = await _authRequest(() => _client.post(uri, headers: headers, body: '{}'));
    _logResponse('likeVideo', response);
    final map = jsonDecode(response.body) is Map<String, dynamic> ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
    final result = LikeVideoResult.fromJson(map);
    if (kDebugMode) debugPrint('[API] likeVideo parsed: likes=${result.likes} liked=${result.liked}');
    return result;
  }

  /// DELETE /api/videos/{id}/like — remove like. Auth required.
  Future<LikeVideoResult> removeLike(String videoId) async {
    if (videoId.isEmpty) throw ApiException('Video id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] removeLike (mock): no network call');
      return const LikeVideoResult(likes: 0, liked: false);
    }
    final uri = _config.videoLikeUrl(videoId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: DELETE $uri');
    final response = await _authRequest(() => _client.delete(uri, headers: headers));
    _logResponse('removeLike', response);
    final map = response.body.isNotEmpty && response.body.trim().startsWith('{')
        ? (jsonDecode(response.body) as Map<String, dynamic>)
        : <String, dynamic>{};
    final result = LikeVideoResult.fromJson(map);
    if (kDebugMode) debugPrint('[API] removeLike parsed: likes=${result.likes} liked=${result.liked}');
    return result;
  }

  /// POST /api/videos/{id}/dislike — toggle dislike. Auth required.
  Future<DislikeVideoResult> dislikeVideo(String videoId) async {
    if (videoId.isEmpty) throw ApiException('Video id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] dislikeVideo (mock): no network call');
      return DislikeVideoResult(dislikes: 0, disliked: true);
    }
    final uri = _config.videoDislikeUrl(videoId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri');
    final response = await _authRequest(() => _client.post(uri, headers: headers, body: '{}'));
    _logResponse('dislikeVideo', response);
    final map = response.body.isNotEmpty && response.body.trim().startsWith('{')
        ? (jsonDecode(response.body) as Map<String, dynamic>)
        : <String, dynamic>{};
    final result = DislikeVideoResult.fromJson(map);
    if (kDebugMode) debugPrint('[API] dislikeVideo parsed: dislikes=${result.dislikes} disliked=${result.disliked}');
    return result;
  }

  /// DELETE /api/videos/{id}/dislike — remove dislike. Auth required.
  Future<DislikeVideoResult> removeDislike(String videoId) async {
    if (videoId.isEmpty) throw ApiException('Video id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] removeDislike (mock): no network call');
      return const DislikeVideoResult(dislikes: 0, disliked: false);
    }
    final uri = _config.videoDislikeUrl(videoId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: DELETE $uri');
    final response = await _authRequest(() => _client.delete(uri, headers: headers));
    _logResponse('removeDislike', response);
    final map = response.body.isNotEmpty && response.body.trim().startsWith('{')
        ? (jsonDecode(response.body) as Map<String, dynamic>)
        : <String, dynamic>{};
    final result = DislikeVideoResult.fromJson(map);
    if (kDebugMode) debugPrint('[API] removeDislike parsed: dislikes=${result.dislikes} disliked=${result.disliked}');
    return result;
  }

  /// POST /api/subscribe/{channelId}. Auth required.
  /// When backend returns 400 "Already subscribed", returns [SubscribeResult] with [isSubscribed] true so UI shows Unsubscribe.
  Future<SubscribeResult> subscribe(String channelId) async {
    if (channelId.isEmpty) throw ApiException('Channel id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] subscribe (mock): no network call');
      return const SubscribeResult(subscriberCount: 1, isSubscribed: true);
    }
    final uri = _config.subscribeUrl(channelId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri (Bearer token length: ${headers['Authorization']?.length ?? 0})');
    final response = await _client.post(uri, headers: headers);
    _logResponse('subscribe', response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = _parseJson(response, (m) => m);
      final result = SubscribeResult.fromJson(map);
      if (kDebugMode) debugPrint('[API] subscribe parsed: count=${result.subscriberCount} isSubscribed=${result.isSubscribed}');
      return result;
    }
    final body = response.body.toLowerCase();
    if (response.statusCode == 400 && (body.contains('already subscribed') || body.contains('already subscribed to this channel'))) {
      if (kDebugMode) debugPrint('[API] subscribe: already subscribed, treating as success');
      try {
        final map = jsonDecode(response.body) is Map ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
        final sub = map['subscriberCount'];
        final count = sub == null ? 0 : (sub is int ? sub : int.tryParse(sub.toString()) ?? 0);
        return SubscribeResult(subscriberCount: count, isSubscribed: true);
      } catch (_) {
        return const SubscribeResult(subscriberCount: 0, isSubscribed: true);
      }
    }
    if (kDebugMode) debugPrint('[API] _authRequest error body: ${response.body.length > 400 ? '${response.body.substring(0, 400)}...' : response.body}');
    final requiresLogin = _parseRequiresLogin(response.body);
    throw ApiException(
      'Request failed: ${response.statusCode}',
      statusCode: response.statusCode,
      requiresLogin: requiresLogin,
    );
  }
  Future<SubscribeResult> unsubscribe(String channelId) async {
    if (channelId.isEmpty) throw ApiException('Channel id is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] unsubscribe (mock): no network call');
      return const SubscribeResult(subscriberCount: 0, isSubscribed: false);
    }
    final uri = _config.unsubscribeUrl(channelId);
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri');
    final response = await _authRequest(() => _client.post(uri, headers: headers));
    _logResponse('unsubscribe', response);
    final map = _parseJson(response, (m) => m);
    final result = SubscribeResult.fromJson(map);
    if (kDebugMode) debugPrint('[API] unsubscribe parsed: count=${result.subscriberCount} isSubscribed=${result.isSubscribed}');
    return result;
  }

  /// GET /api/channels/{channelId}/subscription. Auth required. Returns false when not subscribed or 401.
  Future<bool> checkSubscription(String channelId) async {
    if (channelId.isEmpty) return false;
    if (_config.isMock) return false;
    final uri = _config.subscriptionUrl(channelId);
    final headers = _authHeaders();
    if (headers == null) return false;
    try {
      final response = await _client.get(uri, headers: headers);
      _logResponse('checkSubscription', response);
      if (response.statusCode == 401) return false;
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final map = jsonDecode(response.body) is Map ? jsonDecode(response.body) as Map<String, dynamic> : null;
      return map?['subscribed'] == true;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/comments — body videoId + text. Auth required. Returns created comment.
  Future<Comment> postComment(String videoId, String text) async {
    if (videoId.isEmpty) throw ApiException('Video id is required');
    if (text.trim().isEmpty) throw ApiException('Comment text is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] postComment (mock): no network call');
      return Comment(id: 0, videoId: videoId, userId: 0, text: text.trim());
    }
    final uri = _config.postCommentUrl;
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri (Bearer token length: ${headers['Authorization']?.length ?? 0})');
    final body = jsonEncode({'videoId': videoId, 'text': text.trim()});
    final response = await _authRequest(() => _client.post(uri, headers: headers, body: body));
    _logResponse('postComment', response);
    final map = _parseJson(response, (m) => m);
    final commentMap = map['comment'] ?? map['data'] ?? map;
    final comment = Comment.fromJson(commentMap is Map<String, dynamic> ? commentMap : <String, dynamic>{});
    if (kDebugMode) debugPrint('[API] postComment parsed: id=${comment.id} text=${comment.text.length} chars');
    return comment;
  }

  /// POST /api/comments/reply — body parentCommentId + text. Auth required.
  Future<Comment> replyComment(int parentCommentId, String text) async {
    if (text.trim().isEmpty) throw ApiException('Reply text is required');
    if (_config.isMock) {
      if (kDebugMode) debugPrint('[API] replyComment (mock): no network call');
      return Comment(id: 0, videoId: '', userId: 0, text: text.trim(), parentCommentId: parentCommentId);
    }
    final uri = _config.replyCommentUrl;
    final headers = _authHeaders();
    if (headers == null) throw ApiException('Sign in required', requiresLogin: true);
    if (kDebugMode) debugPrint('[API] OUTGOING: POST $uri');
    final body = jsonEncode({'parentCommentId': parentCommentId, 'text': text.trim()});
    final response = await _authRequest(() => _client.post(uri, headers: headers, body: body));
    _logResponse('replyComment', response);
    final map = _parseJson(response, (m) => m);
    final data = map['data'] ?? map['comment'] ?? map;
    final comment = Comment.fromJson(data is Map<String, dynamic> ? data : <String, dynamic>{});
    if (kDebugMode) debugPrint('[API] replyComment parsed: id=${comment.id} parentId=${comment.parentCommentId}');
    return comment;
  }

  Future<http.Response> _request(Future<http.Response> Function() call) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await call();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (kDebugMode) debugPrint('[API] _request error ${response.statusCode} body: ${response.body.length > 300 ? '${response.body.substring(0, 300)}...' : response.body}');
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
