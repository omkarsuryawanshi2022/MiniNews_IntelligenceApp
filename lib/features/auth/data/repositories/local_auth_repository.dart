import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository(this._box);

  final Box<dynamic> _box;

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final email = _box.get('email');
      final displayName = _box.get('displayName');
      if (email is! String || displayName is! String) return null;
      return AuthSession(email: email, displayName: displayName);
    } on HiveError {
      throw const AppException(
        'The local sign-in session could not be restored.',
        kind: AppErrorKind.storage,
      );
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AppException('Email and password are required.');
    }
    final session = AuthSession(
      email: email.trim(),
      displayName: email.trim().split('@').first,
    );
    try {
      await _box.put('email', session.email);
      await _box.put('displayName', session.displayName);
    } on HiveError {
      throw const AppException(
        'The local sign-in session could not be saved.',
        kind: AppErrorKind.storage,
      );
    }
    return session;
  }

  @override
  Future<void> signOut() async {
    try {
      await _box.clear();
    } on HiveError {
      throw const AppException(
        'The local sign-in session could not be cleared.',
        kind: AppErrorKind.storage,
      );
    }
  }
}
