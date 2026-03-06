import 'package:viikshana/core/api/api_config.dart';

/// Video list item (home feed, search results).
class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.channelId,
    this.channelName,
    this.viewCount = 0,
    this.durationSeconds = 0,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? channelId;
  final String? channelName;
  final int viewCount;
  final int durationSeconds;
  final DateTime? publishedAt;

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];
    final String? channelName = channel is Map<String, dynamic>
        ? channel['name'] as String?
        : json['channelName'] as String?;
    final String? channelId = channel is Map<String, dynamic>
        ? channel['id']?.toString()
        : json['channelId'] as String?;
    final rawThumbnail = (json['thumbnailHome'] ?? json['thumbnailUrl'] ?? json['thumbnail']) as String?;
    return VideoItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: rawThumbnail != null ? ApiConfig.resolveMediaUrl(rawThumbnail) : null,
      channelId: channelId,
      channelName: channelName,
      viewCount: _parseInt(json['views'] ?? json['viewCount'], 0),
      durationSeconds: _parseDurationSeconds(json['duration'] ?? json['durationSeconds']),
      publishedAt: (json['createdAt'] ?? json['publishedAt']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['publishedAt']) as String)
          : null,
    );
  }

  /// Parses duration from API: may be int, double, or string (e.g. "8053.000").
  static int _parseDurationSeconds(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final d = double.tryParse(v);
      return d != null ? d.round() : 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (channelId != null) 'channelId': channelId,
      if (channelName != null) 'channelName': channelName,
      'viewCount': viewCount,
      'durationSeconds': durationSeconds,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }

  static int _parseInt(dynamic v, int fallback) => parseInt(v, fallback);

  static int parseInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
