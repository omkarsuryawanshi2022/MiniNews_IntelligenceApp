import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../presentation/widgets/article_card.dart';
import '../../../presentation/widgets/favorite_action.dart';
import '../../../presentation/widgets/feedback_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/presentation/favorites_controller.dart';
import 'providers/news_providers.dart';
import 'state/news_feed_state.dart';

class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  final _scrollController = ScrollController();

  static const _categories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      ref.read(newsFeedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(newsFeedControllerProvider);
    final favorites =
        ref.watch(favoritesControllerProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini News'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } on AppException catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsFeedControllerProvider),
        ),
        data: (data) => Column(
          children: [
            if (data.isRefreshing) const LinearProgressIndicator(),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            '${category[0].toUpperCase()}${category.substring(1)}',
                          ),
                          selected: data.category == category,
                          onSelected: (_) => ref
                              .read(newsFeedControllerProvider.notifier)
                              .selectCategory(category),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(newsFeedControllerProvider.notifier).refresh(),
                child: _articleList(data, favorites.map((a) => a.key).toSet()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articleList(NewsFeedState data, Set<String> favoriteKeys) {
    if (data.articles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const EmptyState(
            message: 'No headlines were found for this category.',
          ),
          if (data.refreshError != null || data.loadMoreError != null)
            TextButton(
              onPressed: data.refreshError != null
                  ? () => ref
                        .read(newsFeedControllerProvider.notifier)
                        .selectCategory(data.retryCategory ?? data.category)
                  : () =>
                        ref.read(newsFeedControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
        ],
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount:
          data.articles.length +
          (data.isLoadingMore ||
                  data.loadMoreError != null ||
                  data.refreshError != null
              ? 1
              : 0),
      itemBuilder: (context, index) {
        if (index >= data.articles.length) {
          if (data.refreshError != null) {
            return TextButton(
              onPressed: () => ref
                  .read(newsFeedControllerProvider.notifier)
                  .selectCategory(data.retryCategory ?? data.category),
              child: Text('Refresh failed: ${data.refreshError} · Retry'),
            );
          }
          if (data.loadMoreError != null) {
            return TextButton(
              onPressed: () =>
                  ref.read(newsFeedControllerProvider.notifier).retryLoadMore(),
              child: Text('Could not load more: ${data.loadMoreError} · Retry'),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final article = data.articles[index];
        return ArticleCard(
          article: article,
          isFavorite: favoriteKeys.contains(article.key),
          onTap: () => context.push('/article', extra: article),
          onFavoriteTap: () => toggleFavorite(context, ref, article),
        );
      },
    );
  }
}
