import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/api/api_config.dart';
import 'package:viikshana/core/api/dev_http_client.dart';
import 'package:viikshana/core/session/session_provider.dart';
import 'package:viikshana/data/models/video_item.dart';

String? _getAccessToken(Ref ref) => ref.read(sessionRepositoryProvider).accessToken;

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ApiConfig();
  final client = kDebugMode && !config.isMock ? createDevHttpClient() : null;
  return ApiClient(config: config, client: client, getAccessToken: () => _getAccessToken(ref));
});

/// State for the home feed (infinite list).
class HomeFeedState {
  const HomeFeedState({
    this.items = const [],
    this.nextPage = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<VideoItem> items;
  final int nextPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  HomeFeedState copyWith({
    List<VideoItem>? items,
    int? nextPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return HomeFeedState(
      items: items ?? this.items,
      nextPage: nextPage ?? this.nextPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class HomeFeedNotifier extends Notifier<HomeFeedState> {
  @override
  HomeFeedState build() => const HomeFeedState();

  ApiClient get _client => ref.read(apiClientProvider);
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    if (state.isLoading || state.items.isNotEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    await _loadPage(1);
  }

  /// Pull-to-refresh: reset and load page 1.
  Future<void> refresh() async {
    state = const HomeFeedState(isLoading: true);
    await _loadPage(1);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final page = state.nextPage;
    state = state.copyWith(isLoading: true);
    await _loadPage(page);
  }

  Future<void> _loadPage(int page) async {
    try {
      final response = await _client.getHomeFeed(page: page, limit: _pageSize);
      final newItems = state.items.isEmpty
          ? response.videos
          : [...state.items, ...response.videos];
      final hasMore = response.hasMore;
      final nextPage = response.nextPage ?? page + 1;
      state = state.copyWith(
        items: newItems,
        nextPage: nextPage,
        isLoading: false,
        hasMore: hasMore,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final homeFeedProvider =
    NotifierProvider<HomeFeedNotifier, HomeFeedState>(HomeFeedNotifier.new);
