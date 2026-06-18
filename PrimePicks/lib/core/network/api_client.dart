import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl, // dynamique selon la plateforme
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _RetryInterceptor(_dio),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        PrettyDioLogger(requestBody: true, responseBody: false),
    ]);
  }

  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParams);
      return fromJson != null ? fromJson(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.post(path, data: data);
      return fromJson != null ? fromJson(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final res = await _dio.patch(path, data: data);
      return fromJson != null ? fromJson(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // Upload multipart — utilisé sur mobile uniquement (pas web)
  Future<T> uploadBytes<T>(
    String path,
    List<int> bytes,
    String filename, {
    String field = 'file',
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final form = FormData.fromMap({
        field: MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post(path, data: form);
      return fromJson != null ? fromJson(res.data) : res.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppException.network('Délai de connexion dépassé');
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppException.network('Pas de connexion internet');
    }
    final status = e.response?.statusCode;
    final detail = _extractDetail(e.response?.data);
    switch (status) {
      case 400: return AppException.badRequest(detail ?? 'Requête invalide');
      case 401: return AppException.unauthorized();
      case 403: return AppException.forbidden();
      case 404: return AppException.notFound(detail ?? 'Ressource introuvable');
      case 422: return AppException.validation(detail ?? 'Données invalides');
      case 429: return AppException.rateLimit();
      default:  return AppException.server(detail ?? 'Erreur serveur');
    }
  }

  String? _extractDetail(dynamic data) {
    if (data is Map) {
      final d = data['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty) return d.first['msg']?.toString();
    }
    return null;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken(true);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          final res = await Dio().fetch(opts);
          return handler.resolve(res);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const _maxRetries = 2;

  _RetryInterceptor(this.dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retryCount'] as int?) ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.connectionError);

    if (shouldRetry) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
      try {
        final res = await dio.fetch(err.requestOptions);
        return handler.resolve(res);
      } catch (e) {
        if (e is DioException) return handler.next(e);
      }
    }
    handler.next(err);
  }
}
