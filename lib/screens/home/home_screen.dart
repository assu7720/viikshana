import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/shared/components/video_card.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeFeedProvider.notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notifier = ref.read(homeFeedProvider.notifier);
    final state = ref.read(homeFeedProvider);
    if (!state.hasMore || state.isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      notifier.loadMore();
    }
  }

  static int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 600) return 3;
    return 1;
  }

  /// Card content height from card width: 16:9 thumbnail + padding + 2-line title + xs + 1-line meta.
  static double _cardHeightForWidth(double cardWidth) {
    const paddingVertical = ViikshanaSpacing.sm * 2; // 16
    const titleHeight = 34.0; // ~2 lines titleSmall
    const metaHeight = 14.0; // 1 line bodySmall
    const gap = 4.0; // xs
    const bottomBuffer = 20.0; // avoid text overflow (tablet narrow cards)
    return cardWidth * (9 / 16) + paddingVertical + titleHeight + gap + metaHeight + bottomBuffer;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeFeedProvider);
    final columns = _crossAxisCount(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: state.error != null && state.items.isEmpty
          ? _ErrorView(
              message: state.error!,
              onRetry: () {
                ref.read(homeFeedProvider.notifier).clearError();
                ref.read(homeFeedProvider.notifier).loadInitial();
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(homeFeedProvider.notifier).refresh();
              },
              child: state.items.isEmpty && state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? _EmptyView()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const padding = 12.0;
                            const spacing = 12.0;
                            final columns = _crossAxisCount(constraints.maxWidth);
                            final contentWidth = constraints.maxWidth - padding * 2;
                            final cardWidth = (contentWidth - (columns - 1) * spacing) / columns;
                            final cardHeight = _cardHeightForWidth(cardWidth);
                            final rowHeight = cardHeight + spacing;
                            final rowCount = (state.items.length / columns).ceil();
                            final hasLoader = state.hasMore && state.items.isNotEmpty;

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                              itemCount: rowCount + (hasLoader ? 1 : 0),
                              itemBuilder: (context, rowIndex) {
                                if (rowIndex >= rowCount) {
                                  return SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox(
                                  height: rowHeight,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List.generate(columns, (col) {
                                      final index = rowIndex * columns + col;
                                      return Padding(
                                        padding: EdgeInsets.only(right: col < columns - 1 ? spacing : 0),
                                        child: SizedBox(
                                          width: cardWidth,
                                          height: cardHeight,
                                          child: index < state.items.length
                                              ? VideoCard(
                                                  video: state.items[index],
                                                  onTap: () {
                                                    // M6: navigate to player
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
                          },
                        ),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
