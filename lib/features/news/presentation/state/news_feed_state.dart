import '../../domain/entities/article.dart';

class NewsFeedState {
  const NewsFeedState({
    this.articles = const [],
    this.page = 0,
    this.totalResults = 0,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.loadMoreError,
    this.refreshError,
    this.retryCategory,
    this.category = 'general',
    this.query = '',
  });

  final List<Article> articles;
  final int page;
  final int totalResults;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? loadMoreError;
  final String? refreshError;
  final String? retryCategory;
  final String category;
  final String query;

  bool get hasMore => articles.length < totalResults && articles.isNotEmpty;

  NewsFeedState copyWith({
    List<Article>? articles,
    int? page,
    int? totalResults,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    String? refreshError,
    bool clearRefreshError = false,
    String? retryCategory,
    bool clearRetryCategory = false,
    String? category,
    String? query,
  }) => NewsFeedState(
    articles: articles ?? this.articles,
    page: page ?? this.page,
    totalResults: totalResults ?? this.totalResults,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    loadMoreError: clearLoadMoreError
        ? null
        : loadMoreError ?? this.loadMoreError,
    refreshError: clearRefreshError ? null : refreshError ?? this.refreshError,
    retryCategory: clearRetryCategory
        ? null
        : retryCategory ?? this.retryCategory,
    category: category ?? this.category,
    query: query ?? this.query,
  );
}
