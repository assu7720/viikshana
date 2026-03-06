import 'package:viikshana/data/models/video_item.dart';

/// Response for GET /api/home/videos and GET /api/search/videos.
/// Home: success, regularVideos[], hasMore, nextPage.
/// Search (API.md): success, data[], hasMore, nextPage.
/// Related (GET /api/video/{id}/related): success, relatedVideos[], hasMore.
class HomeFeedResponse {
  const HomeFeedResponse({
    required this.videos,
    this.page = 1,
    this.limit = 20,
    this.total,
    this.hasMore = true,
    this.nextPage,
  });

  final List<VideoItem> videos;
  final int page;
  final int limit;
  final int? total;
  /// From API: hasMore.
  final bool hasMore;
  /// From API: nextPage (server-driven pagination).
  final int? nextPage;

  factory HomeFeedResponse.fromJson(Map<String, dynamic> json) {
    final list = json['regularVideos'] ?? json['videos'] ?? json['relatedVideos'] ?? json['data'];
    final List<VideoItem> videos = list is List
        ? list
            .map((e) => VideoItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <VideoItem>[];
    final page = VideoItem.parseInt(json['page'], 1);
    return HomeFeedResponse(
      videos: videos,
      page: page,
      limit: VideoItem.parseInt(json['limit'], 20),
      total: json['total'] != null
          ? VideoItem.parseInt(json['total'], 0)
          : null,
      hasMore: json['hasMore'] == true,
      nextPage: json['nextPage'] != null
          ? VideoItem.parseInt(json['nextPage'], page + 1)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videos': videos.map((e) => e.toJson()).toList(),
      'page': page,
      'limit': limit,
      if (total != null) 'total': total,
      'hasMore': hasMore,
      if (nextPage != null) 'nextPage': nextPage,
    };
  }
}
