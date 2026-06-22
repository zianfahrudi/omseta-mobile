/// A normalized error raised by the API layer so the UI can display a friendly
/// message and (optionally) field-level validation errors.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  /// Human readable message (from the API `message` field when available).
  final String message;

  /// HTTP status code, when known.
  final int? statusCode;

  /// Field-level validation errors as returned by Laravel (`errors` map).
  final Map<String, List<String>>? errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  /// First error message for a given field, if present.
  String? firstError(String field) {
    final list = errors?[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  @override
  String toString() => message;
}
