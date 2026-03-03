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
  static const String _defaultBaseUrl = 'https://viikshana.com';

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
}
