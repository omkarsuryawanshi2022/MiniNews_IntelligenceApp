enum AppErrorKind {
  configuration,
  network,
  timeout,
  unauthorized,
  rateLimit,
  server,
  api,
  malformedResponse,
  storage,
  unknown,
}

class AppException implements Exception {
  const AppException(this.message, {this.kind = AppErrorKind.unknown});

  final String message;
  final AppErrorKind kind;

  @override
  String toString() => message;
}
