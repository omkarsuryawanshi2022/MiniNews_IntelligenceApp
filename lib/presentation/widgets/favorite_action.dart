import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../features/favorites/presentation/favorites_controller.dart';
import '../../features/news/domain/entities/article.dart';

Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Article article,
) async {
  try {
    await ref.read(favoritesControllerProvider.notifier).toggle(article);
  } on AppException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
