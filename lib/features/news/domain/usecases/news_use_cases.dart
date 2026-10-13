import '../entities/news_page.dart';
import '../repositories/news_repository.dart';

class GetHeadlines {
  const GetHeadlines(this._repository);

  final NewsRepository _repository;

  Future<NewsPage> call({
    String country = 'us',
    String category = 'general',
    int page = 1,
    int pageSize = 20,
  }) => _repository.getHeadlines(
    country: country,
    category: category,
    page: page,
    pageSize: pageSize,
  );
}

class SearchArticles {
  const SearchArticles(this._repository);

  final NewsRepository _repository;

  Future<NewsPage> call({
    required String query,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'publishedAt',
  }) => _repository.searchArticles(
    query: query,
    page: page,
    pageSize: pageSize,
    sortBy: sortBy,
  );
}
