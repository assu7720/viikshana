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

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      channelId: json['channelId'] as String?,
      channelName: json['channelName'] as String?,
      viewCount: VideoItem.parseInt(json['viewCount'], 0),
      durationSeconds: VideoItem.parseInt(json['durationSeconds'], 0),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      hlsUrl: json['hlsUrl'] as String?,
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
