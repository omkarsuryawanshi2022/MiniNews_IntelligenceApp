import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/storage/storage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final Box<dynamic> authBox;
  late final Box<dynamic> favoritesBox;
  try {
    await Hive.initFlutter();
    authBox = await Hive.openBox<dynamic>('auth');
    favoritesBox = await Hive.openBox<dynamic>('favorites');
  } on HiveError {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const Text(
                'Local storage could not be initialized. Restart the app or '
                'check available device storage.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        authBoxProvider.overrideWithValue(authBox),
        favoritesBoxProvider.overrideWithValue(favoritesBox),
      ],
      child: const MiniNewsApp(),
    ),
  );
}
