import 'package:flutter/material.dart';
import 'package:viikshana/data/models/video_item.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

/// Card for video list: thumbnail, title, channel, views.
class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
  });

  final VideoItem video;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Thumbnail(url: video.thumbnailUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ViikshanaSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: ViikshanaSpacing.xs),
                    Row(
                      children: [
                        if (video.channelName != null)
                          Expanded(
                            child: Text(
                              video.channelName!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (video.viewCount > 0) ...[
                          if (video.channelName != null)
                            Text(
                              ' • ',
                              style: theme.textTheme.bodySmall,
                            ),
                          Flexible(
                            child: Text(
                              _formatViews(video.viewCount),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M views';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K views';
    return '$n views';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _Placeholder(),
            )
          : const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.video_library, size: 48),
      ),
    );
  }
}
