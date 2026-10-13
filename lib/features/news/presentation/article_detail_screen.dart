import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../presentation/widgets/favorite_action.dart';
import '../../favorites/presentation/favorites_controller.dart';
import '../domain/entities/article.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({required this.article, super.key});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites =
        ref.watch(favoritesControllerProvider).asData?.value ?? [];
    final isFavorite = favorites.any((saved) => saved.key == article.key);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove saved article' : 'Save article',
            onPressed: () => toggleFavorite(context, ref, article),
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl!,
                height: 230,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 230,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            article.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            [
              article.sourceName,
              if (article.author != null) article.author!,
              if (article.publishedAt != null)
                DateFormat.yMMMMd().add_jm().format(article.publishedAt!),
            ].join('  ·  '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (article.url != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              article.url!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (article.description != null) ...[
            const SizedBox(height: 22),
            Text(
              article.description!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          if (article.content != null) ...[
            const SizedBox(height: 16),
            Text(
              article.content!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (article.url != null) ...[
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => _openArticle(context, article.url!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Read full article'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openArticle(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This article has an invalid web address.'),
        ),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this article.')),
      );
    }
  }
}
