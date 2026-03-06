import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateController;
import 'package:video_player/video_player.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/player_providers.dart';
import 'package:viikshana/core/providers/video_detail_provider.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/watch_history/watch_history_repository.dart';
import 'package:viikshana/data/models/comment.dart';
import 'package:viikshana/data/models/video_detail.dart';
import 'package:viikshana/data/models/video_item.dart';
import 'package:viikshana/screens/auth/login_screen.dart';
import 'package:viikshana/shared/components/video_card.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

/// Sample HLS URL used only by mock API (ApiConfig.isMock) for tests.
const String sampleHlsUrl =
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  ChewieController? _chewieController;
  bool _fullScreenListenerAttached = false;
  StateController<bool>? _fullScreenNotifier;
  WatchHistoryRepository? _watchHistoryRepo;

  @override
  void dispose() {
    _chewieController?.removeListener(_onChewieUpdate);
    _fullScreenNotifier?.state = false;
    super.dispose();
  }

  void _onChewieUpdate() {
    final chewie = _chewieController;
    if (chewie == null) return;
    final isFullScreen = chewie.isFullScreen;
    _fullScreenNotifier?.state = isFullScreen;
  }

  @override
  Widget build(BuildContext context) {
    _fullScreenNotifier ??= ref.read(fullScreenPlayerProvider.notifier);
    _watchHistoryRepo ??= ref.read(watchHistoryRepositoryProvider);
    final detailAsync = ref.watch(videoDetailProvider(widget.videoId));

    return detailAsync.when(
      data: (detail) => Scaffold(
        appBar: AppBar(
          title: Text(detail.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildPlayer(detail),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Video'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Video'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load video: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(VideoDetail detail) {
    final hlsUrl = detail.hlsUrl?.trim() ?? '';
    if (hlsUrl.isEmpty) {
      return Center(
        child: Text(
          'No playable stream',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final startAt = _getStartPosition();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _VideoPlayerContent(
            videoId: widget.videoId,
            hlsUrl: hlsUrl,
            startAt: startAt,
            onSavePosition: (positionSeconds) {
              _watchHistoryRepo?.setPosition(widget.videoId, positionSeconds);
            },
            onControllersReady: (video, chewie) {
              if (!_fullScreenListenerAttached && chewie != null) {
                _fullScreenListenerAttached = true;
                _chewieController = chewie;
                chewie.addListener(_onChewieUpdate);
                _onChewieUpdate();
              }
            },
          ),
        ),
        Expanded(
          child: _PlayerBodyContent(
            videoId: widget.videoId,
            detail: detail,
          ),
        ),
      ],
    );
  }

  Duration _getStartPosition() {
    final WatchHistoryRepository repo = _watchHistoryRepo ?? ref.read(watchHistoryRepositoryProvider);
    final seconds = repo.getPosition(widget.videoId);
    return Duration(seconds: seconds);
  }
}

String _relativeTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} yr ago';
  if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} wk ago';
  if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  if (diff.inHours >= 1) return '${diff.inHours} hr ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
  return 'Just now';
}

String _formatSubscribers(int? count) {
  if (count == null || count < 0) return '';
  if (count >= 100000) {
    final lakh = count / 100000;
    return lakh >= 10 ? '${(lakh / 10).toStringAsFixed(1)} crore' : '${lakh.toStringAsFixed(2)} lakh';
  }
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

class _PlayerBodyContent extends ConsumerWidget {
  const _PlayerBodyContent({required this.videoId, required this.detail});

  final String videoId;
  final VideoDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isSignedIn = user != null;
    void onRequireLogin() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to comment, like, subscribe, and more')),
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
    final commentsAsync = ref.watch(videoCommentsProvider(videoId));
    final relatedAsync = ref.watch(relatedVideosProvider(videoId));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ViikshanaSpacing.xs),
          Row(
            children: [
              if (detail.viewCount > 0)
                Text(_formatViews(detail.viewCount), style: theme.textTheme.bodySmall),
              if (detail.viewCount > 0 && detail.publishedAt != null)
                Text(' • ', style: theme.textTheme.bodySmall),
              if (detail.publishedAt != null)
                Text(_relativeTime(detail.publishedAt), style: theme.textTheme.bodySmall),
            ],
          ),
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: ViikshanaSpacing.sm),
            _ExpandableDescription(text: detail.description!),
          ],
          const SizedBox(height: ViikshanaSpacing.md),
          _ChannelRow(detail: detail, isSignedIn: isSignedIn, onRequireLogin: onRequireLogin),
          const SizedBox(height: ViikshanaSpacing.md),
          _EngagementRow(detail: detail, isSignedIn: isSignedIn, onRequireLogin: onRequireLogin),
          const SizedBox(height: ViikshanaSpacing.md),
          SectionHeader(title: 'Comments ${detail.commentCount}'),
          const SizedBox(height: ViikshanaSpacing.sm),
          commentsAsync.when(
            data: (res) => _CommentsList(comments: res.comments),
            loading: () => const Padding(
              padding: EdgeInsets.all(ViikshanaSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(ViikshanaSpacing.md),
              child: Text('Comments unavailable', style: theme.textTheme.bodySmall),
            ),
          ),
          const SizedBox(height: ViikshanaSpacing.sm),
          _CommentInputStub(
            onTap: () {
              if (isSignedIn) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment posting coming in M10')));
              } else {
                onRequireLogin();
              }
            },
          ),
          const SizedBox(height: ViikshanaSpacing.lg),
          SectionHeader(title: 'Related'),
          const SizedBox(height: ViikshanaSpacing.sm),
          relatedAsync.when(
            data: (res) => _RelatedVideosGrid(videos: res.videos, currentVideoId: videoId),
            loading: () => const Padding(
              padding: EdgeInsets.all(ViikshanaSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(ViikshanaSpacing.md),
              child: Text('Related videos unavailable', style: theme.textTheme.bodySmall),
            ),
          ),
          const SizedBox(height: ViikshanaSpacing.xl),
        ],
      ),
    );
  }

  static String _formatViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M views';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K views';
    return '$n views';
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});
  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;
  static const int _maxCollapsed = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showMore = widget.text.length > _maxCollapsed;
    final display = _expanded || !showMore ? widget.text : '${widget.text.substring(0, _maxCollapsed)}...';
    return InkWell(
      onTap: showMore ? () => setState(() => _expanded = !_expanded) : null,
      child: Text(display, style: theme.textTheme.bodySmall, maxLines: _expanded ? null : 2, overflow: _expanded ? null : TextOverflow.ellipsis),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.detail, required this.isSignedIn, required this.onRequireLogin});
  final VideoDetail detail;
  final bool isSignedIn;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channel = detail.channel;
    final name = detail.channelName ?? channel?.name ?? 'Channel';
    final rawAvatar = channel?.avatarUrl;
    final avatarUrl = rawAvatar != null && rawAvatar.isNotEmpty
        ? ApiConfig.resolveMediaUrl(rawAvatar)
        : null;
    final subCount = channel?.subscriberCount;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: theme.textTheme.titleMedium) : null,
        ),
        const SizedBox(width: ViikshanaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (subCount != null && subCount > 0) Text(_formatSubscribers(subCount), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: () => isSignedIn
              ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribe coming in M10')))
              : onRequireLogin(),
          child: const Text('Subscribe'),
        ),
      ],
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({required this.detail, required this.isSignedIn, required this.onRequireLogin});
  final VideoDetail detail;
  final bool isSignedIn;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    void onTap() => isSignedIn
        ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming in M10')))
        : onRequireLogin();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionChip(icon: Icons.thumb_up_outlined, label: _formatCount(detail.likeCount), onTap: onTap),
          _ActionChip(icon: Icons.thumb_down_outlined, label: 'Dislike', onTap: onTap),
          _ActionChip(icon: Icons.share_outlined, label: 'Share', onTap: onTap),
          _ActionChip(icon: Icons.download_outlined, label: 'Download', onTap: onTap),
          _ActionChip(icon: Icons.playlist_add_outlined, label: 'Save', onTap: onTap),
          _ActionChip(icon: Icons.volunteer_activism_outlined, label: 'Thanks', onTap: onTap),
          _ActionChip(icon: Icons.flag_outlined, label: 'Report', onTap: onTap),
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: ViikshanaSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.sm, vertical: ViikshanaSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: ViikshanaSpacing.xs),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600));
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.comments});
  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ViikshanaSpacing.md),
        child: Text('No comments yet.', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: comments.map((c) => _CommentTile(comment: c)).toList(),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ViikshanaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text((comment.username ?? '?').isNotEmpty ? (comment.username ?? '?')[0].toUpperCase() : '?', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: ViikshanaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(comment.username ?? 'User', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                Text(comment.text, style: theme.textTheme.bodySmall, maxLines: 4, overflow: TextOverflow.ellipsis),
                if (comment.createdAt != null) Text(_relativeTime(comment.createdAt), style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputStub extends StatelessWidget {
  const _CommentInputStub({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.md, vertical: ViikshanaSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
            const SizedBox(width: ViikshanaSpacing.sm),
            Text(
              'Comment...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedVideosGrid extends StatelessWidget {
  const _RelatedVideosGrid({required this.videos, required this.currentVideoId});
  final List<VideoItem> videos;
  final String currentVideoId;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(ViikshanaSpacing.md),
        child: Text('No related videos.', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    final list = videos.where((v) => v.id != currentVideoId).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 400 ? 2 : 1;
        final itemWidth = constraints.maxWidth / crossAxisCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: (itemWidth / 220).clamp(0.5, 2.0),
            crossAxisSpacing: ViikshanaSpacing.sm,
            mainAxisSpacing: ViikshanaSpacing.sm,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final vid = list[index];
            return VideoCard(
              video: vid,
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoId: vid.id)),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _VideoPlayerContent extends StatefulWidget {
  const _VideoPlayerContent({
    required this.videoId,
    required this.hlsUrl,
    required this.startAt,
    required this.onSavePosition,
    required this.onControllersReady,
  });

  final String videoId;
  final String hlsUrl;
  final Duration startAt;
  final void Function(int positionSeconds) onSavePosition;
  final void Function(
    VideoPlayerController video,
    ChewieController? chewie,
  ) onControllersReady;

  @override
  State<_VideoPlayerContent> createState() => _VideoPlayerContentState();
}

class _VideoPlayerContentState extends State<_VideoPlayerContent> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.hlsUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    );

    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: true,
        startAt: widget.startAt,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );
      setState(() {
        _videoController = controller;
        _chewieController = chewie;
        _error = null;
      });
      widget.onControllersReady(controller, chewie);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _videoController?.position.then((pos) {
      final sec = pos?.inSeconds ?? 0;
      if (sec > 0) widget.onSavePosition(sec);
    });
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Playback error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final chewie = _chewieController;
    if (chewie == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final aspectRatio = chewie.aspectRatio ?? 16 / 9;
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Chewie(controller: chewie),
      ),
    );
  }
}
