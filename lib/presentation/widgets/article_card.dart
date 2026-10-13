import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/news/domain/entities/article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    required this.article,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    super.key,
  });

  final Article article;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final date = article.publishedAt;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              CachedNetworkImage(
                imageUrl: article.imageUrl!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 190,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          [
                            article.sourceName,
                            if (date != null) DateFormat.yMMMd().format(date),
                          ].join('  ·  '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (onFavoriteTap != null)
                    IconButton(
                      tooltip: isFavorite
                          ? 'Remove saved article'
                          : 'Save article',
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
