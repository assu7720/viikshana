import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/data/models/video_detail.dart';

/// Loads video detail (including HLS URL) for playback.
final videoDetailProvider =
    FutureProvider.autoDispose.family<VideoDetail, String>((ref, videoId) async {
  final client = ref.watch(apiClientProvider);
  return client.getVideo(videoId);
});
