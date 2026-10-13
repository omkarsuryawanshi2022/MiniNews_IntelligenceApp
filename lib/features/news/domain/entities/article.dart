class Article {
  const Article({
    required this.title,
    required this.sourceName,
    this.url,
    this.imageUrl,
    this.description,
    this.content,
    this.author,
    this.publishedAt,
  });

  final String title;
  final String sourceName;
  final String? url;
  final String? imageUrl;
  final String? description;
  final String? content;
  final String? author;
  final DateTime? publishedAt;

  String get key {
    final canonicalUrl = url?.trim();
    if (canonicalUrl != null && canonicalUrl.isNotEmpty) return canonicalUrl;
    return '${sourceName.trim().toLowerCase()}|${title.trim().toLowerCase()}';
  }
}
