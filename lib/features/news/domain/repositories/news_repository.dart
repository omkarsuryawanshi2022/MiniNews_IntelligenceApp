import '../entities/news_page.dart';

abstract interface class NewsRepository {
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  });

  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  });
}
