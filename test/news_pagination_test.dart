import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mininews_intelligenceapp/core/errors/app_exception.dart';
import 'package:mininews_intelligenceapp/features/news/domain/entities/article.dart';
import 'package:mininews_intelligenceapp/features/news/domain/entities/news_page.dart';
import 'package:mininews_intelligenceapp/features/news/domain/repositories/news_repository.dart';
import 'package:mininews_intelligenceapp/features/news/presentation/providers/news_providers.dart';
import 'package:mininews_intelligenceapp/features/news/presentation/state/news_feed_state.dart';

void main() {
  test('feed state detects when another result page is available', () {
    const article = Article(title: 'First', sourceName: 'Wire');
    expect(
      const NewsFeedState(articles: [article], totalResults: 2).hasMore,
      isTrue,
    );
    expect(
      const NewsFeedState(articles: [article], totalResults: 1).hasMore,
      isFalse,
    );
    expect(const NewsFeedState(totalResults: 5).hasMore, isFalse);
  });

  test('controller appends a page and stops at the API result count', () async {
    final repository = _PagedRepository();
    final container = _containerFor(repository);
    addTearDown(container.dispose);

    await container.read(newsFeedControllerProvider.future);
    await container.read(newsFeedControllerProvider.notifier).loadMore();

    final state = container.read(newsFeedControllerProvider).requireValue;
    expect(state.articles.map((article) => article.title), ['First', 'Second']);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);

    await container.read(newsFeedControllerProvider.notifier).loadMore();
    expect(repository.headlineCalls, 2);
  });

  test(
    'pagination stops when a page contains only duplicate articles',
    () async {
      final repository = _DuplicateRepository();
      final container = _containerFor(repository);
      addTearDown(container.dispose);

      await container.read(newsFeedControllerProvider.future);
      await container.read(newsFeedControllerProvider.notifier).loadMore();

      final state = container.read(newsFeedControllerProvider).requireValue;
      expect(state.articles, hasLength(1));
      expect(state.hasMore, isFalse);
      await container.read(newsFeedControllerProvider.notifier).loadMore();
      expect(repository.headlineCalls, 2);
    },
  );

  test(
    'failed category change keeps the old category and its articles',
    () async {
      final container = _containerFor(_CategoryFailureRepository());
      addTearDown(container.dispose);

      await container.read(newsFeedControllerProvider.future);
      await container
          .read(newsFeedControllerProvider.notifier)
          .selectCategory('sports');

      final state = container.read(newsFeedControllerProvider).requireValue;
      expect(state.category, 'general');
      expect(state.retryCategory, 'sports');
      expect(state.articles.single.title, 'Current headlines');
      expect(state.refreshError, isNotNull);
    },
  );

  test('search ignores an older response after a newer query', () async {
    final repository = _RacingSearchRepository();
    final container = _containerFor(repository);
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);

    final olderRequest = container
        .read(searchControllerProvider.notifier)
        .search('older');
    await container.read(searchControllerProvider.notifier).search('newer');
    repository.olderSearch.complete(
      const NewsPage(
        articles: [Article(title: 'Older result', sourceName: 'Wire')],
        totalResults: 1,
      ),
    );
    await olderRequest;

    final state = container.read(searchControllerProvider).requireValue;
    expect(state.query, 'newer');
    expect(state.articles.single.title, 'Newer result');
  });
}

ProviderContainer _containerFor(NewsRepository repository) => ProviderContainer(
  overrides: [newsRepositoryProvider.overrideWithValue(repository)],
);

class _PagedRepository implements NewsRepository {
  int headlineCalls = 0;

  @override
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) async {
    headlineCalls++;
    return NewsPage(
      articles: [
        Article(
          title: page == 1 ? 'First' : 'Second',
          sourceName: 'Wire',
          url: 'https://example.test/$page',
        ),
      ],
      totalResults: 2,
    );
  }

  @override
  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) async => const NewsPage(articles: [], totalResults: 0);
}

class _DuplicateRepository implements NewsRepository {
  int headlineCalls = 0;
  static const _article = Article(
    title: 'Repeated article',
    sourceName: 'Wire',
    url: 'https://example.test/repeated',
  );

  @override
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) async {
    headlineCalls++;
    return const NewsPage(articles: [_article], totalResults: 10);
  }

  @override
  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) async => const NewsPage(articles: [], totalResults: 0);
}

class _CategoryFailureRepository implements NewsRepository {
  @override
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) async {
    if (category == 'sports') throw const AppException('Request failed');
    return const NewsPage(
      articles: [Article(title: 'Current headlines', sourceName: 'Wire')],
      totalResults: 1,
    );
  }

  @override
  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) async => const NewsPage(articles: [], totalResults: 0);
}

class _RacingSearchRepository implements NewsRepository {
  final olderSearch = Completer<NewsPage>();

  @override
  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) async => const NewsPage(articles: [], totalResults: 0);

  @override
  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) {
    if (query == 'older') return olderSearch.future;
    return Future.value(
      const NewsPage(
        articles: [Article(title: 'Newer result', sourceName: 'Wire')],
        totalResults: 1,
      ),
    );
  }
}
