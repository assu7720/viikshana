import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/data/models/comment.dart';
import 'package:viikshana/data/models/home_feed_response.dart';
import 'package:viikshana/data/models/video_detail.dart';

/// Loads video detail (including HLS URL) for playback.
final videoDetailProvider =
    FutureProvider.autoDispose.family<VideoDetail, String>((ref, videoId) async {
  final client = ref.watch(apiClientProvider);
  return client.getVideo(videoId);
});

/// Loads comments for a video (GET /api/videos/{id}/comments).
final videoCommentsProvider = FutureProvider.autoDispose
    .family<VideoCommentsResponse, String>((ref, videoId) async {
  final client = ref.watch(apiClientProvider);
  return client.getVideoComments(videoId);
});

/// Loads related/recommended videos (GET /api/video/{id}/related).
final relatedVideosProvider = FutureProvider.autoDispose
    .family<HomeFeedResponse, String>((ref, videoId) async {
  final client = ref.watch(apiClientProvider);
  return client.getRelatedVideos(videoId);
});
