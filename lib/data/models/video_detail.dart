import 'package:flutter/foundation.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/data/models/channel_metadata.dart';
import 'package:viikshana/data/models/video_item.dart';

/// Full video detail for playback (GET /videos/{id}).
class VideoDetail {
  const VideoDetail({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.channelId,
    this.channelName,
    this.viewCount = 0,
    this.durationSeconds = 0,
    this.publishedAt,
    this.hlsUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.channel,
  });

  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? channelId;
  final String? channelName;
  final int viewCount;
  final int durationSeconds;
  final DateTime? publishedAt;
  /// HLS playlist URL (.m3u8) for playback.
  final String? hlsUrl;
  final int likeCount;
  final int commentCount;
  final ChannelMetadata? channel;

  /// Tries common API keys for HLS playlist URL; supports nested playback/streams.
  static String? _parseHlsUrl(Map<String, dynamic> json) {
    const keys = [
      'hlsUrl', 'hls_url', 'playlistUrl', 'playlist_url',
      'streamUrl', 'stream_url', 'playbackUrl', 'playback_url',
      'videoUrl', 'video_url', 'source', 'url',
      'hlsPath', 'hls_path', 'playlistPath', 'processedPath',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final playback = json['playback'];
    if (playback is Map<String, dynamic>) {
      for (final k in keys) {
        final v = playback[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    final streams = json['streams'];
    if (streams is List && streams.isNotEmpty) {
      final first = streams.first;
      if (first is Map<String, dynamic>) {
        final u = first['url'] ?? first['src'];
        if (u is String && u.trim().isNotEmpty) return u.trim();
      }
    }
    if (kDebugMode) {
      debugPrint('[VideoDetail] No HLS URL found. Top-level keys: ${json.keys.join(', ')}');
    }
    return null;
  }

  static int _parseDurationSeconds(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) {
      final d = double.tryParse(v);
      if (d != null) return d.toInt();
      final i = int.tryParse(v);
      if (i != null) return i;
    }
    return 0;
  }

  /// Coerce dynamic to String? (handles int, double, String from API).
  static String? _stringValue(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is int || v is double) return v.toString();
    return null;
  }

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      id: _stringValue(json['id']) ?? '',
      title: _stringValue(json['title']) ?? '',
      thumbnailUrl: _stringValue(json['thumbnailUrl'] ?? json['thumbnail'] ?? json['thumbnailHome']),
      channelId: _stringValue(json['channelId']),
      channelName: _stringValue(json['channelName']),
      viewCount: VideoItem.parseInt(json['viewCount'] ?? json['views'], 0),
      durationSeconds: _parseDurationSeconds(json['durationSeconds'] ?? json['duration']),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(_stringValue(json['publishedAt']) ?? '')
          : null,
      hlsUrl: () {
        final raw = _parseHlsUrl(json);
        if (raw == null || raw.isEmpty) return null;
        return ApiConfig.resolveMediaUrl(raw);
      }(),
      likeCount: VideoItem.parseInt(json['likeCount'], 0),
      commentCount: VideoItem.parseInt(json['commentCount'], 0),
      channel: json['channel'] != null
          ? ChannelMetadata.fromJson(
              json['channel'] as Map<String, dynamic>,
            )
          : null,
    );
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
      if (hlsUrl != null) 'hlsUrl': hlsUrl,
      'likeCount': likeCount,
      'commentCount': commentCount,
      if (channel != null) 'channel': channel!.toJson(),
    };
  }

  VideoItem toVideoItem() {
    return VideoItem(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      channelId: channelId,
      channelName: channelName ?? channel?.name,
      viewCount: viewCount,
      durationSeconds: durationSeconds,
      publishedAt: publishedAt,
    );
  }
}
