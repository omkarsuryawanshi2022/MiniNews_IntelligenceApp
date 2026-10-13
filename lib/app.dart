import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/favorites/presentation/favorites_screen.dart';
import 'features/news/domain/entities/article.dart';
import 'features/news/presentation/article_detail_screen.dart';
import 'features/news/presentation/news_feed_screen.dart';
import 'features/news/presentation/search_screen.dart';
import 'presentation/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final router = GoRouter(
    initialLocation: '/startup',
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.isLoading) return path == '/startup' ? null : '/startup';
      final loggedIn = auth.asData?.value != null;
      if (!loggedIn && path != '/login') return '/login';
      if (loggedIn && (path == '/login' || path == '/startup')) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const _StartupScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const NewsFeedScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/article',
            builder: (context, state) {
              final article = state.extra;
              if (article is! Article) return const _MissingArticleScreen();
              return ArticleDetailScreen(article: article);
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class MiniNewsApp extends ConsumerWidget {
  const MiniNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mini News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF164E63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _MissingArticleScreen extends StatelessWidget {
  const _MissingArticleScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('This article is no longer available.')),
  );
}
