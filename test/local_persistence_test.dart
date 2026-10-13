import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mininews_intelligenceapp/features/auth/data/repositories/local_auth_repository.dart';
import 'package:mininews_intelligenceapp/features/favorites/data/repositories/hive_favorites_repository.dart';
import 'package:mininews_intelligenceapp/features/news/domain/entities/article.dart';

void main() {
  late Directory storageDirectory;

  setUp(() async {
    storageDirectory = await Directory.systemTemp.createTemp('mini_news_hive_');
    Hive.init(storageDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await storageDirectory.delete(recursive: true);
  });

  test(
    'favorites persist full article data and prevent duplicate keys',
    () async {
      final box = await Hive.openBox<dynamic>('favorites');
      final repository = HiveFavoritesRepository(box);
      const article = Article(
        title: 'Saved story',
        sourceName: 'Daily Wire',
        url: 'https://example.test/saved',
        imageUrl: 'https://example.test/image.jpg',
        description: 'Summary',
        content: 'Content',
        author: 'Reporter',
      );

      await repository.save(article);
      await repository.save(article);
      expect(box.length, 1);
      final restored = await repository.getFavorites();
      expect(restored, hasLength(1));
      expect(restored.single.title, article.title);
      expect(restored.single.imageUrl, article.imageUrl);
      expect(restored.single.content, article.content);

      await repository.remove(article.key);
      expect(await repository.getFavorites(), isEmpty);
    },
  );

  test('demo auth session restores and is removed on sign out', () async {
    final box = await Hive.openBox<dynamic>('auth');
    final repository = LocalAuthRepository(box);

    final session = await repository.signIn(
      email: 'reader@example.com',
      password: 'demo-password',
    );
    expect(session.email, 'reader@example.com');
    expect(box.containsKey('password'), isFalse);
    expect((await repository.restoreSession())?.email, session.email);

    await repository.signOut();
    expect(await repository.restoreSession(), isNull);
  });
}
