/// Custom exception class for API errors.
///
/// Provides detailed error information for different types of API failures.
class ApiException implements Exception {
  /// Creates an ApiException
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.errors,
    this.originalError,
  });

  /// The type of API exception
  final ApiExceptionType type;

  /// Human-readable error message
  final String message;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Error code from API (for specific error handling)
  final String? errorCode;

  /// Validation errors map (field -> error messages)
  final Map<String, dynamic>? errors;

  /// Original error that caused this exception
  final dynamic originalError;

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Network error (no internet, DNS failure, etc.)
  factory ApiException.network({
    required String message,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.network,
      message: message,
      originalError: originalError,
    );
  }

  /// Timeout error
  factory ApiException.timeout({
    required String message,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.timeout,
      message: message,
      originalError: originalError,
    );
  }

  /// Request cancelled
  factory ApiException.cancelled({
    required String message,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.cancelled,
      message: message,
      originalError: originalError,
    );
  }

  /// Bad request (400)
  factory ApiException.badRequest({
    required String message,
    String? errorCode,
    Map<String, dynamic>? errors,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.badRequest,
      message: message,
      statusCode: 400,
      errorCode: errorCode,
      errors: errors,
      originalError: originalError,
    );
  }

  /// Unauthorized (401)
  factory ApiException.unauthorized({
    required String message,
    String? errorCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.unauthorized,
      message: message,
      statusCode: 401,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  /// Forbidden (403)
  factory ApiException.forbidden({
    required String message,
    String? errorCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.forbidden,
      message: message,
      statusCode: 403,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  /// Not found (404)
  factory ApiException.notFound({
    required String message,
    String? errorCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.notFound,
      message: message,
      statusCode: 404,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  /// Conflict (409)
  factory ApiException.conflict({
    required String message,
    String? errorCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.conflict,
      message: message,
      statusCode: 409,
      errorCode: errorCode,
      originalError: originalError,
    );
  }

  /// Validation error (422)
  factory ApiException.validationError({
    required String message,
    Map<String, dynamic>? errors,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.validationError,
      message: message,
      statusCode: 422,
      errors: errors,
      originalError: originalError,
    );
  }

  /// Too many requests (429)
  factory ApiException.tooManyRequests({
    required String message,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.tooManyRequests,
      message: message,
      statusCode: 429,
      originalError: originalError,
    );
  }

  /// Server error (500+)
  factory ApiException.serverError({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.serverError,
      message: message,
      statusCode: statusCode ?? 500,
      originalError: originalError,
    );
  }

  /// Unknown error
  factory ApiException.unknown({
    required String message,
    int? statusCode,
    dynamic originalError,
  }) {
    return ApiException(
      type: ApiExceptionType.unknown,
      message: message,
      statusCode: statusCode,
      originalError: originalError,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if this is a network-related error
  bool get isNetworkError =>
      type == ApiExceptionType.network || type == ApiExceptionType.timeout;

  /// Check if this is an authentication error
  bool get isAuthError =>
      type == ApiExceptionType.unauthorized ||
      type == ApiExceptionType.forbidden;

  /// Check if this is a client error (4xx)
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if this is a server error (5xx)
  bool get isServerError =>
      statusCode != null && statusCode! >= 500 && statusCode! < 600;

  /// Check if this error is retryable
  bool get isRetryable =>
      type == ApiExceptionType.network ||
      type == ApiExceptionType.timeout ||
      type == ApiExceptionType.serverError;

  /// Get validation error for a specific field
  String? getFieldError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    if (fieldErrors is String) {
      return fieldErrors;
    }
    return null;
  }

  /// Get all validation errors as a flat list
  List<String> getAllErrors() {
    if (errors == null) return [message];
    final allErrors = <String>[];
    errors!.forEach((key, value) {
      if (value is List) {
        allErrors.addAll(value.map((e) => e.toString()));
      } else if (value is String) {
        allErrors.add(value);
      }
    });
    return allErrors.isEmpty ? [message] : allErrors;
  }

  @override
  String toString() {
    final buffer = StringBuffer('ApiException(');
    buffer.write('type: $type, ');
    buffer.write('message: $message');
    if (statusCode != null) buffer.write(', statusCode: $statusCode');
    if (errorCode != null) buffer.write(', errorCode: $errorCode');
    if (errors != null) buffer.write(', errors: $errors');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Types of API exceptions
enum ApiExceptionType {
  /// Network connectivity issues
  network,

  /// Request timeout
  timeout,

  /// Request was cancelled
  cancelled,

  /// Bad request (400)
  badRequest,

  /// Unauthorized (401)
  unauthorized,

  /// Forbidden (403)
  forbidden,

  /// Not found (404)
  notFound,

  /// Conflict (409)
  conflict,

  /// Validation error (422)
  validationError,

  /// Too many requests (429)
  tooManyRequests,

  /// Server error (5xx)
  serverError,

  /// Unknown error
  unknown,
}
