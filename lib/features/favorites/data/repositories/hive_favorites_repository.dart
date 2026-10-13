import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../news/data/models/article_model.dart';
import '../../../news/domain/entities/article.dart';
import '../../domain/repositories/favorites_repository.dart';

class HiveFavoritesRepository implements FavoritesRepository {
  const HiveFavoritesRepository(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<Article>> getFavorites() async {
    try {
      return _box.values
          .map((value) {
            if (value is! String) {
              throw const FormatException('Invalid saved article record.');
            }
            final decoded = jsonDecode(value);
            if (decoded is! Map<String, dynamic>) {
              throw const FormatException('Invalid saved article record.');
            }
            return ArticleModel.fromJson(decoded);
          })
          .toList(growable: false);
    } on FormatException {
      throw const AppException(
        'Saved articles could not be read from local storage.',
        kind: AppErrorKind.storage,
      );
    } on HiveError {
      throw const AppException(
        'Saved articles are currently unavailable in local storage.',
        kind: AppErrorKind.storage,
      );
    }
  }

  @override
  Future<void> save(Article article) async {
    try {
      await _box.put(
        article.key,
        jsonEncode(ArticleModel.fromEntity(article).toJson()),
      );
    } on HiveError {
      throw const AppException(
        'Could not save this article to local storage.',
        kind: AppErrorKind.storage,
      );
    }
  }

  @override
  Future<void> remove(String articleKey) async {
    try {
      await _box.delete(articleKey);
    } on HiveError {
      throw const AppException(
        'Could not remove this article from local storage.',
        kind: AppErrorKind.storage,
      );
    }
  }
}
