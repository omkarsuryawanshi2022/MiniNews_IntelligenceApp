import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final authBoxProvider = Provider<Box<dynamic>>((ref) {
  throw StateError('Auth storage has not been initialized.');
});

final favoritesBoxProvider = Provider<Box<dynamic>>((ref) {
  throw StateError('Favorites storage has not been initialized.');
});
