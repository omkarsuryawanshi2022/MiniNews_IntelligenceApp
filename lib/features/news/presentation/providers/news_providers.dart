import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/news_remote_data_source.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/entities/news_page.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/news_use_cases.dart';
import '../state/news_feed_state.dart';

final newsRemoteDataSourceProvider = Provider<NewsRemoteDataSource>(
  (ref) => NewsRemoteDataSource(ref.watch(dioProvider)),
);

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepositoryImpl(ref.watch(newsRemoteDataSourceProvider)),
);

final getHeadlinesProvider = Provider<GetHeadlines>(
  (ref) => GetHeadlines(ref.watch(newsRepositoryProvider)),
);

final searchArticlesProvider = Provider<SearchArticles>(
  (ref) => SearchArticles(ref.watch(newsRepositoryProvider)),
);

final newsFeedControllerProvider =
    AsyncNotifierProvider<NewsFeedController, NewsFeedState>(
      NewsFeedController.new,
    );

class NewsFeedController extends AsyncNotifier<NewsFeedState> {
  int _requestId = 0;

  @override
  Future<NewsFeedState> build() async {
    final result = await _fetchPage(category: 'general', page: 1);
    return NewsFeedState(
      articles: result.articles,
      page: 1,
      totalResults: result.totalResults,
    );
  }

  Future<NewsPage> _fetchPage({required String category, required int page}) =>
      ref.read(getHeadlinesProvider)(
        country: AppConfig.newsCountry,
        category: category,
        page: page,
        pageSize: AppConfig.pageSize,
      );

  Future<void> selectCategory(String category) async {
    final requestId = ++_requestId;
    final current = state.asData?.value;
    if (current == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(
        current.copyWith(
          isRefreshing: true,
          clearRefreshError: true,
          retryCategory: category,
        ),
      );
    }
    try {
      final result = await _fetchPage(category: category, page: 1);
      if (requestId != _requestId) return;
      state = AsyncData(
        NewsFeedState(
          articles: result.articles,
          page: 1,
          totalResults: result.totalResults,
          category: category,
        ),
      );
    } catch (error, stackTrace) {
      if (requestId == _requestId) {
        final latest = state.asData?.value;
        state = latest == null
            ? AsyncError(error, stackTrace)
            : AsyncData(
                latest.copyWith(
                  category: current?.category ?? latest.category,
                  isRefreshing: false,
                  refreshError: error.toString(),
                  retryCategory: category,
                ),
              );
      }
    }
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    if (current == null) {
      await selectCategory('general');
      return;
    }
    final requestId = ++_requestId;
    state = AsyncData(
      current.copyWith(
        isRefreshing: true,
        retryCategory: current.category,
        clearRefreshError: true,
      ),
    );
    try {
      final result = await _fetchPage(category: current.category, page: 1);
      if (requestId != _requestId) return;
      state = AsyncData(
        current.copyWith(
          articles: result.articles,
          page: 1,
          totalResults: result.totalResults,
          isRefreshing: false,
          clearLoadMoreError: true,
          clearRefreshError: true,
          clearRetryCategory: true,
        ),
      );
    } catch (error) {
      if (requestId == _requestId) {
        state = AsyncData(
          current.copyWith(
            isRefreshing: false,
            refreshError: error.toString(),
            retryCategory: current.category,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreError != null) {
      return;
    }
    final requestId = _requestId;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final result = await _fetchPage(
        category: current.category,
        page: current.page + 1,
      );
      if (requestId != _requestId) return;
      final latest = state.asData?.value ?? current;
      final keys = latest.articles.map((article) => article.key).toSet();
      final additions = result.articles
          .where((article) => keys.add(article.key))
          .toList();
      state = AsyncData(
        latest.copyWith(
          articles: [...latest.articles, ...additions],
          page: current.page + 1,
          totalResults: additions.isEmpty
              ? latest.articles.length
              : result.totalResults,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreError: error.toString()),
      );
    }
  }

  Future<void> retryLoadMore() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearLoadMoreError: true));
    await loadMore();
  }
}

final searchControllerProvider =
    AsyncNotifierProvider<SearchController, NewsFeedState>(
      SearchController.new,
    );

class SearchController extends AsyncNotifier<NewsFeedState> {
  int _requestId = 0;

  @override
  Future<NewsFeedState> build() async => const NewsFeedState();

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    final requestId = ++_requestId;
    if (normalizedQuery.isEmpty) {
      state = const AsyncData(NewsFeedState());
      return;
    }

    state = const AsyncLoading();
    try {
      final result = await ref.read(searchArticlesProvider)(
        query: normalizedQuery,
        page: 1,
        pageSize: AppConfig.pageSize,
        sortBy: AppConfig.searchSortBy,
      );
      if (requestId != _requestId) return;
      state = AsyncData(
        NewsFeedState(
          articles: result.articles,
          page: 1,
          totalResults: result.totalResults,
          query: normalizedQuery,
        ),
      );
    } catch (error, stackTrace) {
      if (requestId == _requestId) state = AsyncError(error, stackTrace);
    }
  }

  void invalidatePendingSearch() {
    _requestId++;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.query.isEmpty ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreError != null) {
      return;
    }
    final requestId = _requestId;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final result = await ref.read(searchArticlesProvider)(
        query: current.query,
        page: current.page + 1,
        pageSize: AppConfig.pageSize,
        sortBy: AppConfig.searchSortBy,
      );
      if (requestId != _requestId) return;
      final latest = state.asData?.value ?? current;
      final keys = latest.articles.map((article) => article.key).toSet();
      final additions = result.articles
          .where((article) => keys.add(article.key))
          .toList();
      state = AsyncData(
        latest.copyWith(
          articles: [...latest.articles, ...additions],
          page: current.page + 1,
          totalResults: additions.isEmpty
              ? latest.articles.length
              : result.totalResults,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreError: error.toString()),
      );
    }
  }

  Future<void> retryLoadMore() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearLoadMoreError: true));
    await loadMore();
  }
}
