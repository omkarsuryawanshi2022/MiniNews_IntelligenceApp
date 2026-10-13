import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/article_card.dart';
import '../../../presentation/widgets/favorite_action.dart';
import '../../../presentation/widgets/feedback_state.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved articles')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(favoritesControllerProvider),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return const EmptyState(
              message: 'Articles you save will be available here offline.',
            );
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ArticleCard(
                article: article,
                isFavorite: true,
                onTap: () => context.push('/article', extra: article),
                onFavoriteTap: () => toggleFavorite(context, ref, article),
              );
            },
          );
        },
      ),
    );
  }
}
