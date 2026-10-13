import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/article_card.dart';
import '../../../presentation/widgets/favorite_action.dart';
import '../../../presentation/widgets/feedback_state.dart';
import '../../favorites/presentation/favorites_controller.dart';
import 'providers/news_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    ref.read(searchControllerProvider.notifier).invalidatePendingSearch();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => ref.read(searchControllerProvider.notifier).search(value),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    ref.read(searchControllerProvider.notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchControllerProvider);
    final favoriteKeys =
        (ref.watch(favoritesControllerProvider).asData?.value ?? [])
            .map((article) => article.key)
            .toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Search articles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              maxLength: 500,
              onChanged: _onChanged,
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: 'Search topics, people, or places',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _queryController.clear();
                    _onChanged('');
                  },
                  icon: const Icon(Icons.close),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: search.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => _submit(_queryController.text),
              ),
              data: (data) {
                if (data.query.isEmpty) {
                  return const EmptyState(
                    message: 'Enter a topic to search NewsAPI.',
                  );
                }
                if (data.articles.isEmpty) {
                  return const EmptyState(
                    message: 'No articles matched your search.',
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      data.articles.length +
                      (data.isLoadingMore || data.loadMoreError != null
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index >= data.articles.length) {
                      if (data.loadMoreError != null) {
                        return TextButton(
                          onPressed: () => ref
                              .read(searchControllerProvider.notifier)
                              .retryLoadMore(),
                          child: Text(
                            'Could not load more: ${data.loadMoreError} · Retry',
                          ),
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
                      onFavoriteTap: () =>
                          toggleFavorite(context, ref, article),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
