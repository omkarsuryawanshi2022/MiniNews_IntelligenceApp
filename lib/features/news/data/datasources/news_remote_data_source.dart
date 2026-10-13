import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/news_page.dart';
import '../models/article_model.dart';

class NewsRemoteDataSource {
  const NewsRemoteDataSource(this._dio, {String? apiKey})
    : _apiKey = apiKey ?? AppConfig.newsApiKey;

  final Dio _dio;
  final String _apiKey;

  Future<NewsPage> getHeadlines({
    required String country,
    required String category,
    required int page,
    required int pageSize,
  }) => _getPage('/v2/top-headlines', {
    'country': country,
    'category': category,
    'page': page,
    'pageSize': pageSize,
  });

  Future<NewsPage> searchArticles({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) => _getPage(
    '/v2/everything',
    buildSearchQueryParameters(
      query: query,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
    ),
  );

  static Map<String, Object> buildSearchQueryParameters({
    required String query,
    required int page,
    required int pageSize,
    required String sortBy,
  }) => {
    'q': query.trim(),
    'page': page,
    'pageSize': pageSize,
    'sortBy': sortBy,
  };

  Future<NewsPage> _getPage(String path, Map<String, Object> parameters) async {
    if (_apiKey.trim().isEmpty) {
      throw const AppException(
        'News is temporarily unavailable. Please try again later.',
        kind: AppErrorKind.configuration,
      );
    }

    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: parameters,
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AppException(
          'NewsAPI returned an invalid response.',
          kind: AppErrorKind.malformedResponse,
        );
      }
      if (body['status'] != 'ok') {
        final message = body['message'];
        throw AppException(
          message is String && message.isNotEmpty
              ? message
              : 'NewsAPI could not complete the request.',
          kind: AppErrorKind.api,
        );
      }

      final rawArticles = body['articles'];
      if (rawArticles is! List) {
        throw const AppException(
          'NewsAPI returned an invalid article list.',
          kind: AppErrorKind.malformedResponse,
        );
      }

      final articles = <ArticleModel>[];
      for (final item in rawArticles) {
        if (item is Map<String, dynamic>) {
          final article = ArticleModel.fromJson(item);
          if (article.title.isNotEmpty) articles.add(article);
        }
      }
      final totalResults = body['totalResults'];

      return NewsPage(
        articles: articles,
        totalResults: totalResults is int ? totalResults : articles.length,
      );
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw const AppException(
          'NewsAPI rejected the key or this endpoint is not available on your plan.',
          kind: AppErrorKind.unauthorized,
        );
      }
      if (statusCode == 429) {
        throw const AppException(
          'NewsAPI request limit reached. Please try again later.',
          kind: AppErrorKind.rateLimit,
        );
      }
      if (statusCode != null && statusCode >= 500) {
        throw const AppException(
          'NewsAPI is temporarily unavailable. Please try again.',
          kind: AppErrorKind.server,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AppException(
          'The request timed out. Check your connection and retry.',
          kind: AppErrorKind.timeout,
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        throw const AppException(
          'Unable to connect. Check your internet connection.',
          kind: AppErrorKind.network,
        );
      }
      if (error.error is FormatException) {
        throw const AppException(
          'NewsAPI returned malformed JSON.',
          kind: AppErrorKind.malformedResponse,
        );
      }
      final responseBody = error.response?.data;
      if (responseBody is Map<String, dynamic> &&
          responseBody['message'] is String) {
        throw AppException(
          responseBody['message'] as String,
          kind: AppErrorKind.api,
        );
      }
      throw const AppException(
        'The news request failed. Please try again.',
        kind: AppErrorKind.unknown,
      );
    } on FormatException {
      throw const AppException(
        'NewsAPI returned malformed article data.',
        kind: AppErrorKind.malformedResponse,
      );
    }
  }
}
