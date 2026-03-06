import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/providers/search_provider.dart';
import 'package:viikshana/data/models/video_item.dart';
import 'package:viikshana/screens/player/player_screen.dart';
import 'package:viikshana/shared/components/video_card.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// When true, show suggestions below; when false and we have video results, show cards only.
  bool _hasSearchFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _hasSearchFocus) {
      setState(() => _hasSearchFocus = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ViikshanaSpacing.md,
              vertical: ViikshanaSpacing.sm,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(searchProvider.notifier).setQuery(value),
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                ref.read(searchProvider.notifier).submitQuery(value);
              },
            ),
          ),
        ),
      ),
      body: _buildBody(context, searchState, history, _hasSearchFocus),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchState searchState,
    List<String> history,
    bool hasSearchFocus,
  ) {
    final query = searchState.query.trim();
    final hasQuery = query.isNotEmpty;
    final submitted = searchState.submittedQuery;
    final hasVideoResults = submitted != null;

    // When focus is out and we have a submitted query: show video cards only (no suggestions).
    if (!hasSearchFocus && hasVideoResults) {
      return searchState.videoResults.when(
        data: (videos) {
          if (searchState.isVideoSearching && videos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No videos for "$submitted"',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return _SearchVideoGrid(items: videos);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(searchProvider.notifier).clearError(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Focus in or no submitted query: show suggestions when there is a query.
    if (hasQuery) {
      return searchState.suggestions.when(
        data: (suggestionList) {
          if (searchState.isLoading && suggestionList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (suggestionList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No results for "$query"',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.md),
            itemCount: suggestionList.length,
            itemBuilder: (context, index) {
              final suggestion = suggestionList[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion),
                onTap: () {
                  _controller.text = suggestion;
                  _controller.selection =
                      TextSelection.collapsed(offset: suggestion.length);
                  FocusScope.of(context).unfocus();
                  ref.read(searchProvider.notifier).submitQuery(suggestion);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(searchProvider.notifier).clearError(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty query: show recent history or placeholder.
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search history will appear here',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ViikshanaSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(searchHistoryProvider.notifier).clear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        ...history.map(
          (q) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(q),
            onTap: () {
              _controller.text = q;
              _controller.selection = TextSelection.collapsed(offset: q.length);
              FocusScope.of(context).unfocus();
              ref.read(searchProvider.notifier).submitQuery(q);
            },
          ),
        ),
      ],
    );
  }

  static int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 600) return 3;
    return 1;
  }

  static double _cardHeightForWidth(double cardWidth) {
    const paddingVertical = ViikshanaSpacing.sm * 2;
    const titleHeight = 34.0;
    const metaHeight = 14.0;
    const gap = 4.0;
    const bottomBuffer = 20.0;
    return cardWidth * (9 / 16) +
        paddingVertical +
        titleHeight +
        gap +
        metaHeight +
        bottomBuffer;
  }
}

class _SearchVideoGrid extends StatelessWidget {
  const _SearchVideoGrid({required this.items});

  final List<VideoItem> items;

  @override
  Widget build(BuildContext context) {
    const padding = 12.0;
    const spacing = 12.0;
    final width = MediaQuery.sizeOf(context).width;
    final columns = _SearchScreenState._crossAxisCount(width);
    final contentWidth = width - padding * 2;
    final cardWidth =
        (contentWidth - (columns - 1) * spacing) / columns;
    final cardHeight = _SearchScreenState._cardHeightForWidth(cardWidth);
    final rowHeight = cardHeight + spacing;
    final rowCount = (items.length / columns).ceil();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        return SizedBox(
          height: rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columns, (col) {
              final index = rowIndex * columns + col;
              return Padding(
                padding: EdgeInsets.only(
                  right: col < columns - 1 ? spacing : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: index < items.length
                      ? VideoCard(
                          video: items[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PlayerScreen(
                                  videoId: items[index].id,
                                ),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
