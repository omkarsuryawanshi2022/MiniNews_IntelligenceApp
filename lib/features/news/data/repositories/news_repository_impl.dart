import '../../domain/entities/news_page.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_data_source.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._remoteDataSource);

  final NewsRemoteDataSource _remoteDataSource;

  @override
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) => _remoteDataSource.getHeadlines(
    country: country,
    category: category,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) => _remoteDataSource.searchArticles(
    query: query,
    page: page,
    pageSize: pageSize,
    sortBy: sortBy,
  );
}
