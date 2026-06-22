import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'logging_interceptor.dart';

/// Thin wrapper around [Dio] that injects the bearer token, sets the standard
/// headers and converts errors into [ApiException]s.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              headers: {'Accept': 'application/json'},
              // We handle non-2xx ourselves to build rich exceptions.
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Use the in-memory token. We deliberately avoid reading secure
          // storage (Keychain) on every request, which can block/prompt and
          // make requests hang.
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
    // Network logging (debug builds only).
    _dio.interceptors.add(LoggingInterceptor());
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Cached bearer token, kept in memory for the app session.
  String? _token;

  /// Sets (or clears) the active bearer token used for subsequent requests.
  set token(String? value) => _token = value;

  /// The token storage backing this client (for callers that need to persist).
  TokenStorage get tokenStorage => _tokenStorage;

  /// Callback invoked when a request returns 401 so the app can sign out.
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() => _dio.get(path, queryParameters: query));
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    return _send(() => _dio.post(path, data: data, queryParameters: query));
  }

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return _handleResponse(response);
    } on DioException catch (e) {
      if (e.response != null) {
        return _handleResponse(e.response!);
      }
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  dynamic _handleResponse(Response response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return response.data;
    }

    final data = response.data;
    String message = 'Terjadi kesalahan.';
    Map<String, List<String>>? errors;

    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        message = data['message'] as String;
      }
      final rawErrors = data['errors'];
      if (rawErrors is Map<String, dynamic>) {
        errors = rawErrors.map(
          (key, value) =>
              MapEntry(key, (value as List).map((e) => e.toString()).toList()),
        );
      }
    }

    if (status == 401) {
      onUnauthorized?.call();
    }

    throw ApiException(message, statusCode: status, errors: errors);
  }
}
