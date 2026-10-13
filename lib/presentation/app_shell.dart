import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = switch (path) {
      '/search' => 1,
      '/favorites' => 2,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/search');
            case 2:
              context.go('/favorites');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper),
            label: 'Headlines',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}
