import '../../../news/domain/entities/article.dart';

abstract interface class FavoritesRepository {
  Future<List<Article>> getFavorites();
  Future<void> save(Article article);
  Future<void> remove(String articleKey);
}
