import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mininews_intelligenceapp/core/errors/app_exception.dart';
import 'package:mininews_intelligenceapp/features/news/data/datasources/news_remote_data_source.dart';
import 'package:mininews_intelligenceapp/features/news/data/models/article_model.dart';
import 'package:mininews_intelligenceapp/features/news/data/repositories/news_repository_impl.dart';

void main() {
  group('ArticleModel', () {
    test('maps nullable API fields without failing', () {
      final article = ArticleModel.fromJson({
        'title': 'A headline',
        'source': null,
        'author': null,
        'description': null,
        'url': null,
        'urlToImage': null,
        'publishedAt': 'not-a-date',
        'content': null,
      });

      expect(article.title, 'A headline');
      expect(article.sourceName, 'Unknown source');
      expect(article.imageUrl, isNull);
      expect(article.publishedAt, isNull);
      expect(article.key, 'unknown source|a headline');
    });

    test('round-trips the complete article for local persistence', () {
      final article = ArticleModel(
        title: 'Headline',
        sourceName: 'Daily News',
        url: 'https://news.example/article',
        imageUrl: 'https://news.example/image.jpg',
        description: 'Description',
        content: 'Article content',
        author: 'Reporter',
        publishedAt: DateTime.utc(2026, 1, 2),
      );

      final restored = ArticleModel.fromJson(article.toJson());
      expect(restored.title, article.title);
      expect(restored.sourceName, article.sourceName);
      expect(restored.url, article.url);
      expect(restored.imageUrl, article.imageUrl);
      expect(restored.description, article.description);
      expect(restored.content, article.content);
      expect(restored.author, article.author);
      expect(restored.publishedAt, article.publishedAt);
    });
  });

  test('constructs API search pagination and sorting parameters', () {
    expect(
      NewsRemoteDataSource.buildSearchQueryParameters(
        query: '  climate change ',
        page: 3,
        pageSize: 20,
        sortBy: 'publishedAt',
      ),
      {
        'q': 'climate change',
        'page': 3,
        'pageSize': 20,
        'sortBy': 'publishedAt',
      },
    );
  });

  group('NewsRepositoryImpl', () {
    test('returns parsed articles for a successful API response', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://newsapi.org'))
        ..httpClientAdapter = _ResponseAdapter(
          '{"status":"ok","totalResults":1,"articles":['
          '{"title":"Headline","source":{"name":"Wire"},"url":"https://x.test"}]}',
          200,
        );
      final repository = NewsRepositoryImpl(
        NewsRemoteDataSource(dio, apiKey: 'test-key'),
      );

      final page = await repository.getHeadlines(
        country: 'us',
        category: 'general',
        page: 1,
        pageSize: 20,
      );

      expect(page.totalResults, 1);
      expect(page.articles.single.title, 'Headline');
    });

    test('surfaces API-level error responses', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://newsapi.org'))
        ..httpClientAdapter = _ResponseAdapter(
          '{"status":"error","code":"apiKeyInvalid","message":"Invalid API key"}',
          200,
        );
      final repository = NewsRepositoryImpl(
        NewsRemoteDataSource(dio, apiKey: 'test-key'),
      );

      await expectLater(
        repository.getHeadlines(
          country: 'us',
          category: 'general',
          page: 1,
          pageSize: 20,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.kind,
            'kind',
            AppErrorKind.api,
          ),
        ),
      );
    });

    test('maps plan and authentication HTTP errors', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://newsapi.org'))
        ..httpClientAdapter = _ResponseAdapter(
          '{"status":"error","message":"Forbidden"}',
          403,
        );
      final repository = NewsRepositoryImpl(
        NewsRemoteDataSource(dio, apiKey: 'test-key'),
      );

      await expectLater(
        repository.getHeadlines(
          country: 'us',
          category: 'general',
          page: 1,
          pageSize: 20,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.kind,
            'kind',
            AppErrorKind.unauthorized,
          ),
        ),
      );
    });
  });
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.body, this.statusCode);

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
