import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../news/domain/entities/article.dart';
import '../data/repositories/hive_favorites_repository.dart';
import '../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => HiveFavoritesRepository(ref.watch(favoritesBoxProvider)),
);

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<Article>>(
      FavoritesController.new,
    );

class FavoritesController extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() =>
      ref.read(favoritesRepositoryProvider).getFavorites();

  Future<void> toggle(Article article) async {
    final repository = ref.read(favoritesRepositoryProvider);
    final current = state.asData?.value ?? const <Article>[];
    final isFavorite = current.any((saved) => saved.key == article.key);
    if (isFavorite) {
      await repository.remove(article.key);
      state = AsyncData(
        current.where((saved) => saved.key != article.key).toList(),
      );
    } else {
      await repository.save(article);
      state = AsyncData([...current, article]);
    }
  }
}
