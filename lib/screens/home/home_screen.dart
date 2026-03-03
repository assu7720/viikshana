import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/shared/components/video_card.dart';

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
    if (width >= 900) return 5;
    if (width >= 600) return 3;
    return 1;
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
                      : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: columns == 1 ? 1.28 : 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: state.items.length +
                          (state.hasMore && state.items.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return VideoCard(
                          video: state.items[index],
                          onTap: () {
                            // M6: navigate to player
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
