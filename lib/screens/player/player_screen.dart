import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateController;
import 'package:video_player/video_player.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/player_providers.dart';
import 'package:viikshana/core/providers/video_detail_provider.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/api/api_exception.dart';
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
  /// Preserves video player state when layout switches (e.g. tablet portrait ↔ landscape).
  GlobalKey<_VideoPlayerContentState> _playerContentKey =
      GlobalKey<_VideoPlayerContentState>();

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _chewieController?.removeListener(_onChewieUpdate);
      _chewieController = null;
      _fullScreenListenerAttached = false;
      _playerContentKey = GlobalKey<_VideoPlayerContentState>();
    }
  }

  @override
  void dispose() {
    _chewieController?.removeListener(_onChewieUpdate);
    _fullScreenNotifier?.state = false;
    super.dispose();
  }

  void _onChewieUpdate() {
    _syncShellBottomNav();
  }

  /// [MobileShell] hides its bottom [NavigationBar] when this is true (Chewie fullscreen or phone landscape player).
  void _syncShellBottomNav() {
    if (!mounted) return;
    _fullScreenNotifier ??= ref.read(fullScreenPlayerProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final isTablet = size.shortestSide >= 600;
    final landscape = orientation == Orientation.landscape;
    final detailReady = ref.read(videoDetailProvider(widget.videoId)).hasValue;
    final immersivePhoneLandscape = !isTablet && landscape && detailReady;
    // Do not call [exitFullScreen] when landscape becomes true: Chewie’s own fullscreen forces landscape
    // for wide videos, which would match “immersive + fullscreen” and pop the route immediately.
    final chewieFull = _chewieController?.isFullScreen ?? false;
    final hide = chewieFull || immersivePhoneLandscape;
    if (_fullScreenNotifier!.state != hide) {
      _fullScreenNotifier!.state = hide;
    }
  }

  @override
  Widget build(BuildContext context) {
    _fullScreenNotifier ??= ref.read(fullScreenPlayerProvider.notifier);
    _watchHistoryRepo ??= ref.read(watchHistoryRepositoryProvider);
    final detailAsync = ref.watch(videoDetailProvider(widget.videoId));
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final isTablet = size.shortestSide >= 600;
    final isTabletLandscape =
        isTablet && orientation == Orientation.landscape;
    final isMobileLandscape =
        !isTablet && orientation == Orientation.landscape;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncShellBottomNav();
    });

    return detailAsync.when(
      data: (detail) {
        // One [Scaffold] for loaded detail so orientation changes don’t swap the whole route shell
        // (avoids disposing/recreating Chewie’s [PlayerNotifier] mid-fullscreen — chewie#857).
        return Scaffold(
          appBar: isMobileLandscape
              ? null
              : AppBar(
                  title: Text(detail.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
          body: isMobileLandscape
              ? _buildMobileLandscapeFullscreen(detail)
              : _buildPlayer(detail, isTabletLayout: isTabletLandscape),
        );
      },
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

  /// Phone landscape: edge-to-edge video, same [GlobalKey] player as portrait (no reload).
  Widget _buildMobileLandscapeFullscreen(VideoDetail detail) {
    final hlsUrl = detail.hlsUrl?.trim() ?? '';
    if (hlsUrl.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              'No playable stream',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      );
    }
    final startAt = _getStartPosition();
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: _VideoPlayerContent(
            key: _playerContentKey,
            fillViewport: true,
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
        Positioned(
          top: MediaQuery.paddingOf(context).top,
          left: 0,
          child: SafeArea(
            bottom: false,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// [isTabletLayout]: tablet landscape only — video left, related right.
  Widget _buildPlayer(VideoDetail detail, {bool isTabletLayout = false}) {
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
    final videoBlock = AspectRatio(
      aspectRatio: 16 / 9,
      child: _VideoPlayerContent(
        key: _playerContentKey,
        fillViewport: false,
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
    );

    if (isTabletLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                videoBlock,
                Expanded(
                  child: _PlayerBodyContent(
                    videoId: widget.videoId,
                    detail: detail,
                    showRelatedOnRight: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: _RelatedVideosColumn(videoId: widget.videoId),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        videoBlock,
        Expanded(
          child: _PlayerBodyContent(
            videoId: widget.videoId,
            detail: detail,
            showRelatedOnRight: false,
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
  const _PlayerBodyContent({
    required this.videoId,
    required this.detail,
    this.showRelatedOnRight = false,
  });

  final String videoId;
  final VideoDetail detail;
  final bool showRelatedOnRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSignedIn = ref.watch(isSignedInProvider);
    void onRequireLogin() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to comment, like, subscribe, and more')),
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
    final apiClient = ref.read(apiClientProvider);
    void onAfterEngagement() {
      ref.invalidate(videoDetailProvider(videoId));
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
          if (detail.description != null && detail.description!.trim().isNotEmpty) ...[
            const SizedBox(height: ViikshanaSpacing.sm),
            _ExpandableDescription(text: detail.description!.trim()),
          ],
          const SizedBox(height: ViikshanaSpacing.md),
          _ChannelRow(
            detail: detail,
            isSignedIn: isSignedIn,
            onRequireLogin: onRequireLogin,
            subscribed: () {
              final chId = detail.channelId ?? detail.channel?.id;
              final fromDetail = (detail.subscribedToChannel ?? detail.channel?.isSubscribed) == true;
              if (chId != null && ref.watch(optimisticSubscribedChannelIdsProvider).contains(chId)) return true;
              return fromDetail;
            }(),
            onSubscribe: () async {
              final chId = detail.channelId ?? detail.channel?.id;
              if (chId == null || chId.isEmpty) return;
              final isSubscribed = (detail.subscribedToChannel ?? detail.channel?.isSubscribed) == true ||
                  ref.read(optimisticSubscribedChannelIdsProvider).contains(chId);
              try {
                if (isSubscribed) {
                  await apiClient.unsubscribe(chId);
                  ref.read(optimisticSubscribedChannelIdsProvider.notifier).update((s) => Set<String>.from(s)..remove(chId));
                } else {
                  await apiClient.subscribe(chId);
                  ref.read(optimisticSubscribedChannelIdsProvider.notifier).update((s) => <String>{...s, chId});
                }
                onAfterEngagement();
              } catch (e) {
                if (context.mounted) {
                  if (e is ApiException && e.requiresLogin) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to subscribe to channels')));
                    onRequireLogin();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
          ),
          const SizedBox(height: ViikshanaSpacing.md),
          _EngagementRow(
            detail: detail,
            isSignedIn: isSignedIn,
            onRequireLogin: onRequireLogin,
            onLike: () async {
              try {
                if (detail.likedByMe == true) {
                  await apiClient.removeLike(videoId);
                } else {
                  await apiClient.likeVideo(videoId);
                }
                onAfterEngagement();
              } catch (e) {
                if (context.mounted) {
                  if (e is ApiException && e.requiresLogin) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to like videos')));
                    onRequireLogin();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            onDislike: () async {
              try {
                if (detail.dislikedByMe == true) {
                  await apiClient.removeDislike(videoId);
                } else {
                  await apiClient.dislikeVideo(videoId);
                }
                onAfterEngagement();
              } catch (e) {
                if (context.mounted) {
                  if (e is ApiException && e.requiresLogin) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to dislike videos')));
                    onRequireLogin();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
          ),
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
          _CommentInput(
            videoId: videoId,
            isSignedIn: isSignedIn,
            onRequireLogin: onRequireLogin,
            onCommentPosted: () {
              ref.invalidate(videoCommentsProvider(videoId));
              ref.invalidate(videoDetailProvider(videoId));
            },
          ),
          if (!showRelatedOnRight) ...[
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
  const _ChannelRow({
    required this.detail,
    required this.isSignedIn,
    required this.onRequireLogin,
    required this.subscribed,
    required this.onSubscribe,
  });
  final VideoDetail detail;
  final bool isSignedIn;
  final VoidCallback onRequireLogin;
  final bool subscribed;
  final Future<void> Function() onSubscribe;

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
          onPressed: () {
            if (isSignedIn) {
              onSubscribe();
            } else {
              onRequireLogin();
            }
          },
          child: Text(subscribed ? 'Unsubscribe' : 'Subscribe'),
        ),
      ],
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({
    required this.detail,
    required this.isSignedIn,
    required this.onRequireLogin,
    required this.onLike,
    required this.onDislike,
  });
  final VideoDetail detail;
  final bool isSignedIn;
  final VoidCallback onRequireLogin;
  final Future<void> Function() onLike;
  final Future<void> Function() onDislike;

  @override
  Widget build(BuildContext context) {
    void onTapOther() => isSignedIn
        ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')))
        : onRequireLogin();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionChip(
            icon: detail.likedByMe == true ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: _formatCount(detail.likeCount),
            onTap: () {
              if (isSignedIn) {
                onLike();
              } else {
                onRequireLogin();
              }
            },
          ),
          _ActionChip(
            icon: detail.dislikedByMe == true ? Icons.thumb_down : Icons.thumb_down_outlined,
            label: _formatCount(detail.dislikeCount),
            onTap: () {
              if (isSignedIn) {
                onDislike();
              } else {
                onRequireLogin();
              }
            },
          ),
          _ActionChip(icon: Icons.share_outlined, label: 'Share', onTap: onTapOther),
          _ActionChip(icon: Icons.download_outlined, label: 'Download', onTap: onTapOther),
          _ActionChip(icon: Icons.playlist_add_outlined, label: 'Save', onTap: onTapOther),
          _ActionChip(icon: Icons.volunteer_activism_outlined, label: 'Thanks', onTap: onTapOther),
          _ActionChip(icon: Icons.flag_outlined, label: 'Report', onTap: onTapOther),
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

/// Comment input: when signed in shows field + submit; when not signed in tap prompts login.
class _CommentInput extends ConsumerStatefulWidget {
  const _CommentInput({
    required this.videoId,
    required this.isSignedIn,
    required this.onRequireLogin,
    required this.onCommentPosted,
  });
  final String videoId;
  final bool isSignedIn;
  final VoidCallback onRequireLogin;
  final VoidCallback onCommentPosted;

  @override
  ConsumerState<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<_CommentInput> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;
    setState(() => _isPosting = true);
    try {
      await ref.read(apiClientProvider).postComment(widget.videoId, text);
      _controller.clear();
      widget.onCommentPosted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment posted')));
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.requiresLogin) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to comment')));
          widget.onRequireLogin();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSignedIn) {
      return _CommentInputStub(
        onTap: widget.onRequireLogin,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: ViikshanaSpacing.sm),
        FilledButton(
          onPressed: _isPosting ? null : () => _submit(),
          child: _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
        ),
      ],
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

/// Tablet right column: related videos only.
class _RelatedVideosColumn extends ConsumerWidget {
  const _RelatedVideosColumn({required this.videoId});
  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedVideosProvider(videoId));
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ViikshanaSpacing.md, ViikshanaSpacing.sm, ViikshanaSpacing.md, ViikshanaSpacing.xs),
          child: SectionHeader(title: 'Related'),
        ),
        Expanded(
          child: relatedAsync.when(
            data: (res) {
              final list = res.videos.where((v) => v.id != videoId).toList();
              if (list.isEmpty) {
                return Center(
                  child: Text('No related videos.', style: theme.textTheme.bodySmall),
                );
              }
              return _RelatedVideosList(videos: list, currentVideoId: videoId);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(ViikshanaSpacing.md),
                child: Text('Related videos unavailable', style: theme.textTheme.bodySmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedVideosList extends StatelessWidget {
  const _RelatedVideosList({required this.videos, required this.currentVideoId});
  final List<VideoItem> videos;
  final String currentVideoId;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(
        child: Text('No related videos.', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.md),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final vid = videos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: ViikshanaSpacing.sm),
          child: SizedBox(
            height: 240,
            child: VideoCard(
              video: vid,
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoId: vid.id)),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _VideoPlayerContent extends StatefulWidget {
  const _VideoPlayerContent({
    super.key,
    this.fillViewport = false,
    required this.videoId,
    required this.hlsUrl,
    required this.startAt,
    required this.onSavePosition,
    required this.onControllersReady,
  });

  /// When true, video is sized to cover the parent (e.g. phone landscape fullscreen).
  final bool fillViewport;
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
  /// Keeps [ChewieState] (and its [PlayerNotifier]) across layout changes (portrait ↔ landscape).
  final GlobalKey _chewieWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(_VideoPlayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillViewport != widget.fillViewport) {
      setState(() {});
    }
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

    final aspectRatio = (chewie.aspectRatio ?? 16 / 9).clamp(0.5, 3.0);

    if (!widget.fillViewport) {
      return Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _ChewieLocalMediaQuery(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
                child: Chewie(key: _chewieWidgetKey, controller: chewie),
              );
            },
          ),
        ),
      );
    }

    // Letterbox to viewport; Chewie must see local [MediaQuery] size (not full screen) or controls mis-layout.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (maxW <= 0 || maxH <= 0) {
          return const Center(child: CircularProgressIndicator());
        }
        var w = maxW;
        var h = w / aspectRatio;
        if (h > maxH) {
          h = maxH;
          w = h * aspectRatio;
        }
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: _ChewieLocalMediaQuery(
              maxWidth: w,
              maxHeight: h,
              child: Chewie(key: _chewieWidgetKey, controller: chewie),
            ),
          ),
        );
      },
    );
  }
}

/// Chewie's [PlayerWithControls] sizes its inner [AspectRatio] from [MediaQuery.size] (full window).
/// Override size to the actual player bounds so controls and video lay out correctly when embedded.
class _ChewieLocalMediaQuery extends StatelessWidget {
  const _ChewieLocalMediaQuery({
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
  });

  final double maxWidth;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = maxWidth.clamp(1.0, double.infinity);
    final h = maxHeight.clamp(1.0, double.infinity);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(size: Size(w, h)),
      child: child,
    );
  }
}
