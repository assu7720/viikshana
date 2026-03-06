import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/api/api_client.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/search_history/search_history_repository.dart';
import 'package:viikshana/data/models/video_item.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((ref) {
  return SearchHistoryRepository();
});

/// Search history list (max 10, most recent first). Persisted via [SearchHistoryRepository].
class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.read(searchHistoryRepositoryProvider).getQueries();
  }

  SearchHistoryRepository get _repo => ref.read(searchHistoryRepositoryProvider);

  Future<void> addQuery(String query) async {
    await _repo.addQuery(query);
    state = _repo.getQueries();
  }

  Future<void> clear() async {
    await _repo.clear();
    state = [];
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);

/// State for search: suggestions while typing; video results after submit/select.
class SearchState {
  const SearchState({
    this.query = '',
    this.suggestions = const AsyncValue.data([]),
    this.isLoading = false,
    this.submittedQuery,
    this.videoResults = const AsyncValue.data([]),
    this.isVideoSearching = false,
  });

  final String query;
  final AsyncValue<List<String>> suggestions;
  final bool isLoading;
  /// Set when user submits or selects a suggestion; triggers video search and grid below.
  final String? submittedQuery;
  final AsyncValue<List<VideoItem>> videoResults;
  final bool isVideoSearching;

  SearchState copyWith({
    String? query,
    AsyncValue<List<String>>? suggestions,
    bool? isLoading,
    Object? submittedQuery = _unchanged,
    AsyncValue<List<VideoItem>>? videoResults,
    bool? isVideoSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      submittedQuery: submittedQuery == _unchanged ? this.submittedQuery : submittedQuery as String?,
      videoResults: videoResults ?? this.videoResults,
      isVideoSearching: isVideoSearching ?? this.isVideoSearching,
    );
  }
}

const _unchanged = Object();

/// Debounce duration for search (300–500ms per M7).
const Duration _searchDebounce = Duration(milliseconds: 400);

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchState();
  }

  ApiClient get _client => ref.read(apiClientProvider);

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounceTimer?.cancel();
    if (q.trim().isEmpty) {
      state = state.copyWith(
        suggestions: const AsyncValue.data([]),
        isLoading: false,
      );
      return;
    }
    _debounceTimer = Timer(_searchDebounce, () => _fetchSuggestions(q.trim()));
  }

  Future<void> _fetchSuggestions(String q) async {
    state = state.copyWith(
      isLoading: true,
      suggestions: const AsyncValue.loading(),
    );
    try {
      final list = await _client.getSearchSuggestions(q, limit: 8);
      state = state.copyWith(
        suggestions: AsyncValue.data(list),
        isLoading: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        suggestions: AsyncValue.error(e, st),
        isLoading: false,
      );
    }
  }

  /// On submit or suggestion selected: add to history, run video search, show grid below.
  Future<void> submitQuery(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    await ref.read(searchHistoryProvider.notifier).addQuery(trimmed);
    _debounceTimer?.cancel();
    state = state.copyWith(
      query: trimmed,
      submittedQuery: trimmed,
      isVideoSearching: true,
      videoResults: const AsyncValue.loading(),
    );
    try {
      final response = await _client.searchVideos(trimmed, page: 1, limit: 20);
      state = state.copyWith(
        videoResults: AsyncValue.data(response.videos),
        isVideoSearching: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        videoResults: AsyncValue.error(e, st),
        isVideoSearching: false,
      );
    }
  }

  void clearError() {
    if (state.suggestions.hasError) {
      state = state.copyWith(suggestions: const AsyncValue.data([]));
    }
    if (state.videoResults.hasError) {
      state = state.copyWith(videoResults: const AsyncValue.data([]));
    }
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
