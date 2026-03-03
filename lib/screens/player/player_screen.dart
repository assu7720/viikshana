import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateController;
import 'package:video_player/video_player.dart';
import 'package:viikshana/core/providers/player_providers.dart';
import 'package:viikshana/core/providers/video_detail_provider.dart';
import 'package:viikshana/core/watch_history/watch_history_repository.dart';
import 'package:viikshana/data/models/video_detail.dart';

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
  VideoPlayerController? _videoController;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: detailAsync.when(
        data: (detail) => _buildPlayer(detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load video: $e',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
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
    return _VideoPlayerContent(
      videoId: widget.videoId,
      hlsUrl: hlsUrl,
      startAt: startAt,
      onSavePosition: (positionSeconds) {
        _watchHistoryRepo?.setPosition(widget.videoId, positionSeconds);
      },
      onControllersReady: (video, chewie) {
        if (!_fullScreenListenerAttached && chewie != null) {
          _fullScreenListenerAttached = true;
          _videoController = video;
          _chewieController = chewie;
          chewie.addListener(_onChewieUpdate);
          _onChewieUpdate();
        }
      },
    );
  }

  Duration _getStartPosition() {
    final WatchHistoryRepository repo = _watchHistoryRepo ?? ref.read(watchHistoryRepositoryProvider);
    final seconds = repo.getPosition(widget.videoId);
    return Duration(seconds: seconds);
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
