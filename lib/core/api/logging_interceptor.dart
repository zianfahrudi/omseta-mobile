import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every Dio request, response and error to the debug console.
///
/// Active only in debug mode. The `Authorization` header value is masked so the
/// bearer token never leaks into the logs.
class LoggingInterceptor extends Interceptor {
  static const _tag = 'API';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln('--> ${options.method} ${options.uri}')
        ..writeln('Headers: ${_maskHeaders(options.headers)}');
      if (options.data != null) {
        buffer.writeln('Body: ${_stringify(options.data)}');
      }
      _log(buffer.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln(
          '<-- ${response.statusCode} ${response.requestOptions.method} '
          '${response.requestOptions.uri}',
        )
        ..writeln('Data: ${_stringify(response.data)}');
      _log(buffer.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final buffer = StringBuffer()
        ..writeln(
          'xxx ${err.type.name} ${err.requestOptions.method} '
          '${err.requestOptions.uri}',
        )
        ..writeln('Message: ${err.message}');
      if (err.response != null) {
        buffer
          ..writeln('Status: ${err.response?.statusCode}')
          ..writeln('Data: ${_stringify(err.response?.data)}');
      }
      if (err.error != null) {
        buffer.writeln('Cause: ${err.error}');
      }
      _log(buffer.toString());
    }
    handler.next(err);
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = 'Bearer ***';
    }
    return copy;
  }

  String _stringify(Object? data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}=${e.value}').join(', ');
      final files = data.files.map((e) => e.key).join(', ');
      return 'FormData(fields: [$fields], files: [$files])';
    }
    try {
      if (data is String) return data;
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _log(String message) {
    developer.log(message, name: _tag);
  }
}
