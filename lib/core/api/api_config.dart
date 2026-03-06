/// Base URL and config for the ClipsNow API.
/// Default [baseUrl] is https://viikshana.com for all devices.
/// Override in tests via --dart-define=VIIKSHANA_API_BASE_URL= (use empty string for mock/empty feed).
///
/// Video thumbnails and video files (HLS, etc.) are served from [mediaBaseUrl].
class ApiConfig {
  ApiConfig({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'VIIKSHANA_API_BASE_URL',
              defaultValue: _defaultBaseUrl,
            );

  /// Default when no dart-define is set. Production API for all devices.
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000';

  /// Base URL for video thumbnails and video files (HLS, MP4). All media assets are served from this host.
  static const String mediaBaseUrl = 'https://videoprocess.viikshana.com';

  final String baseUrl;

  /// When true, skip real HTTP and return empty feed (for emulator/local without API).
  bool get isMock => baseUrl.isEmpty;

  /// GET /api/home/videos
  String get homeFeedPath => '/api/home/videos';

  /// GET /videos/{id}
  String videoPath(String id) => '/videos/$id';

  Uri homeFeedUrl({int page = 1, int limit = 20}) {
    return Uri.parse(baseUrl).replace(path: homeFeedPath, queryParameters: {
      'page': page.toString(),
      'limit': limit.clamp(1, 100).toString(),
    });
  }

  Uri videoUrl(String id) {
    return Uri.parse(baseUrl).replace(path: videoPath(id));
  }

  /// GET /search/suggestions?q=...&limit=8
  String get searchSuggestionsPath => '/search/suggestions';

  Uri searchSuggestionsUrl(String q, {int limit = 8}) {
    return Uri.parse(baseUrl).replace(
      path: searchSuggestionsPath,
      queryParameters: {
        'q': q,
        'limit': limit.clamp(1, 100).toString(),
      },
    );
  }

  /// GET /api/search/videos?q=... (video search; same response shape as home feed).
  String get searchVideosPath => '/api/search/videos';

  Uri searchVideosUrl(String q, {int page = 1, int limit = 20}) {
    return Uri.parse(baseUrl).replace(
      path: searchVideosPath,
      queryParameters: {
        'q': q,
        'page': page.toString(),
        'limit': limit.clamp(1, 100).toString(),
      },
    );
  }

  /// GET /api/videos/{id}/comments (paginated).
  String videoCommentsPath(String videoId) => '/api/videos/$videoId/comments';

  Uri videoCommentsUrl(String videoId, {int page = 1, int limit = 20}) {
    return Uri.parse(baseUrl).replace(
      path: videoCommentsPath(videoId),
      queryParameters: {
        'page': page.toString(),
        'limit': limit.clamp(1, 100).toString(),
      },
    );
  }

  /// GET /api/video/{id}/related (related/recommended videos; same shape as home feed).
  String relatedVideosPath(String videoId) => '/api/video/$videoId/related';

  Uri relatedVideosUrl(String videoId) {
    return Uri.parse(baseUrl).replace(path: relatedVideosPath(videoId));
  }

  /// POST /auth/api/login (session + cookies). Body: { email, password }.
  String get authLoginPath => '/auth/api/login';

  Uri get authLoginUrl => Uri.parse(baseUrl).replace(path: authLoginPath);

  /// GET /auth/api/me (current user profile; session required).
  String get authMePath => '/auth/api/me';

  Uri get authMeUrl => Uri.parse(baseUrl).replace(path: authMePath);

  /// Resolves a thumbnail or video URL. If [urlOrPath] is relative (starts with /), prepends [mediaBaseUrl].
  static String resolveMediaUrl(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return urlOrPath ?? '';
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    final base = mediaBaseUrl.endsWith('/') ? mediaBaseUrl : '$mediaBaseUrl/';
    final path = urlOrPath.startsWith('/') ? urlOrPath.substring(1) : urlOrPath;
    return base + path;
  }

  /// Resolves a relative URL for API-served assets (e.g. channel logos at /processed/channels/...).
  /// Use when the asset is served from the same host as [baseUrl]. Leaves absolute URLs unchanged.
  static String resolveApiAssetUrl(String? urlOrPath, String baseUrl) {
    if (urlOrPath == null || urlOrPath.isEmpty) return urlOrPath ?? '';
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return urlOrPath;
    }
    if (baseUrl.isEmpty) return urlOrPath;
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final path = urlOrPath.startsWith('/') ? urlOrPath.substring(1) : urlOrPath;
    return base + path;
  }
}
