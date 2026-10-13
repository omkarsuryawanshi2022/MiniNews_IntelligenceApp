import 'article.dart';

class NewsPage {
  const NewsPage({required this.articles, required this.totalResults});

  final List<Article> articles;
  final int totalResults;
}
