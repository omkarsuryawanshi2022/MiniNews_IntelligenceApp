import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.title,
    required super.sourceName,
    super.url,
    super.imageUrl,
    super.description,
    super.content,
    super.author,
    super.publishedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    final sourceMap = source is Map<String, dynamic> ? source : const {};
    final publishedAt = json['publishedAt'];

    return ArticleModel(
      title: _string(json['title']) ?? '',
      sourceName: _string(sourceMap['name']) ?? 'Unknown source',
      url: _string(json['url']),
      imageUrl: _string(json['urlToImage']),
      description: _string(json['description']),
      content: _string(json['content']),
      author: _string(json['author']),
      publishedAt: publishedAt is String
          ? DateTime.tryParse(publishedAt)
          : null,
    );
  }

  factory ArticleModel.fromEntity(Article article) => ArticleModel(
    title: article.title,
    sourceName: article.sourceName,
    url: article.url,
    imageUrl: article.imageUrl,
    description: article.description,
    content: article.content,
    author: article.author,
    publishedAt: article.publishedAt,
  );

  Map<String, Object?> toJson() => {
    'title': title,
    'source': {'name': sourceName},
    'url': url,
    'urlToImage': imageUrl,
    'description': description,
    'content': content,
    'author': author,
    'publishedAt': publishedAt?.toUtc().toIso8601String(),
  };

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
