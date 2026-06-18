class AppException implements Exception {
  final String message;
  final AppExceptionType type;

  const AppException._(this.message, this.type);

  factory AppException.network(String msg) =>
      AppException._(msg, AppExceptionType.network);
  factory AppException.unauthorized() =>
      AppException._('Session expirée, veuillez vous reconnecter', AppExceptionType.unauthorized);
  factory AppException.forbidden() =>
      AppException._('Accès refusé', AppExceptionType.forbidden);
  factory AppException.notFound(String msg) =>
      AppException._(msg, AppExceptionType.notFound);
  factory AppException.badRequest(String msg) =>
      AppException._(msg, AppExceptionType.badRequest);
  factory AppException.validation(String msg) =>
      AppException._(msg, AppExceptionType.validation);
  factory AppException.server(String msg) =>
      AppException._(msg, AppExceptionType.server);
  factory AppException.rateLimit() =>
      AppException._('Trop de requêtes, réessayez dans un instant', AppExceptionType.rateLimit);
  factory AppException.unknown(String msg) =>
      AppException._(msg, AppExceptionType.unknown);

  bool get isUnauthorized => type == AppExceptionType.unauthorized;
  bool get isNetwork => type == AppExceptionType.network;

  @override
  String toString() => message;
}

enum AppExceptionType {
  network,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  validation,
  server,
  rateLimit,
  unknown,
}
