import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage.dart';

/// HTTP client wrapper using Dio for API communication.
///
/// Provides:
/// - Base configuration with timeouts
/// - Automatic auth token injection
/// - Response/error handling interceptors
/// - Request logging (debug mode)
/// - Retry logic for transient failures
class ApiClient {
  /// Private constructor
  ApiClient._internal();

  /// Singleton instance
  static final ApiClient _instance = ApiClient._internal();

  /// Factory constructor returns singleton
  factory ApiClient() => _instance;

  /// Dio instance
  late Dio _dio;

  /// Secure storage for tokens
  final SecureStorage _secureStorage = SecureStorage();

  /// Whether the client has been initialized
  bool _isInitialized = false;

  /// Connection timeout duration
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Initialize the API client
  Future<void> init({String? baseUrl}) async {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
          HttpHeaders.acceptHeader: ContentType.json.mimeType,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _authInterceptor(),
      _loggingInterceptor(),
      _errorInterceptor(),
    ]);

    _isInitialized = true;
  }

  /// Get Dio instance (for advanced usage)
  Dio get dio {
    _ensureInitialized();
    return _dio;
  }

  /// Ensure client is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'ApiClient not initialized. Call ApiClient().init() first.',
      );
    }
  }

  // ============================================================================
  // INTERCEPTORS
  // ============================================================================

  /// Auth interceptor - adds authorization header
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for certain endpoints
        final noAuthEndpoints = [
          ApiEndpoints.login,
          ApiEndpoints.register,
          ApiEndpoints.forgotPassword,
          ApiEndpoints.resetPassword,
          ApiEndpoints.refreshToken,
        ];

        final shouldAddAuth = !noAuthEndpoints.any(
          (endpoint) => options.path.endsWith(endpoint),
        );

        if (shouldAddAuth) {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Handle 401 - try to refresh token
        if (error.response?.statusCode == 401) {
          final didRefresh = await _tryRefreshToken();
          if (didRefresh) {
            // Retry the original request
            try {
              final response = await _retryRequest(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  /// Logging interceptor - logs requests/responses in debug mode
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          _logRequest(options);
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          _logResponse(response);
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          _logError(error);
        }
        return handler.next(error);
      },
    );
  }

  /// Error interceptor - transforms errors into ApiException
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final apiException = _transformError(error);
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: apiException,
          ),
        );
      },
    );
  }

  // ============================================================================
  // TOKEN REFRESH
  // ============================================================================

  /// Try to refresh the access token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Create a new Dio instance without interceptors to avoid loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.saveAccessToken(newAccessToken);
        }
        if (newRefreshToken != null) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      // Token refresh failed - user needs to re-login
      await _secureStorage.clearAll();
      return false;
    }
  }

  /// Retry a failed request with new token
  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await _secureStorage.getAccessToken();
    options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    return _dio.fetch(options);
  }

  // ============================================================================
  // ERROR TRANSFORMATION
  // ============================================================================

  /// Transform DioException to ApiException
  ApiException _transformError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout(
          message: 'Connection timed out. Please try again.',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return ApiException.network(
          message: 'No internet connection. Please check your network.',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return ApiException.cancelled(
          message: 'Request was cancelled.',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return ApiException.network(
          message: 'Invalid SSL certificate.',
          originalError: error,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return ApiException.network(
            message: 'No internet connection.',
            originalError: error,
          );
        }
        return ApiException.unknown(
          message: 'An unexpected error occurred.',
          originalError: error,
        );
    }
  }

  /// Handle bad response errors
  ApiException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;

    String message = 'Something went wrong';
    String? errorCode;
    Map<String, dynamic>? errors;

    // Try to extract error details from response
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;
      errorCode = data['code'] as String?;
      if (data['errors'] is Map<String, dynamic>) {
        errors = data['errors'] as Map<String, dynamic>;
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException.badRequest(
          message: message,
          errorCode: errorCode,
          errors: errors,
          originalError: error,
        );
      case 401:
        return ApiException.unauthorized(
          message: message,
          errorCode: errorCode,
          originalError: error,
        );
      case 403:
        return ApiException.forbidden(
          message: message,
          errorCode: errorCode,
          originalError: error,
        );
      case 404:
        return ApiException.notFound(
          message: message,
          errorCode: errorCode,
          originalError: error,
        );
      case 409:
        return ApiException.conflict(
          message: message,
          errorCode: errorCode,
          originalError: error,
        );
      case 422:
        return ApiException.validationError(
          message: message,
          errors: errors,
          originalError: error,
        );
      case 429:
        return ApiException.tooManyRequests(
          message: message,
          originalError: error,
        );
      case 500:
      case 501:
      case 502:
      case 503:
        return ApiException.serverError(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return ApiException.unknown(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  // ============================================================================
  // LOGGING
  // ============================================================================

  void _logRequest(RequestOptions options) {
    debugPrint('╔══════════════════════════════════════════════════════════');
    debugPrint('║ REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════');
    debugPrint('║ ${options.method} ${options.uri}');
    debugPrint('║ Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('║ Body: ${options.data}');
    }
    debugPrint('╚══════════════════════════════════════════════════════════');
  }

  void _logResponse(Response response) {
    debugPrint('╔══════════════════════════════════════════════════════════');
    debugPrint('║ RESPONSE');
    debugPrint('╠══════════════════════════════════════════════════════════');
    debugPrint('║ Status: ${response.statusCode}');
    debugPrint('║ Data: ${response.data}');
    debugPrint('╚══════════════════════════════════════════════════════════');
  }

  void _logError(DioException error) {
    debugPrint('╔══════════════════════════════════════════════════════════');
    debugPrint('║ ERROR');
    debugPrint('╠══════════════════════════════════════════════════════════');
    debugPrint('║ Type: ${error.type}');
    debugPrint('║ Message: ${error.message}');
    debugPrint('║ Response: ${error.response?.data}');
    debugPrint('╚══════════════════════════════════════════════════════════');
  }

  // ============================================================================
  // HTTP METHODS
  // ============================================================================

  /// Perform GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file(s)
  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.post<T>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response> downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    return _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  /// Update base URL
  void setBaseUrl(String baseUrl) {
    _ensureInitialized();
    _dio.options.baseUrl = baseUrl;
  }

  /// Add custom header
  void addHeader(String key, String value) {
    _ensureInitialized();
    _dio.options.headers[key] = value;
  }

  /// Remove custom header
  void removeHeader(String key) {
    _ensureInitialized();
    _dio.options.headers.remove(key);
  }

  /// Clear all custom headers
  void clearHeaders() {
    _ensureInitialized();
    _dio.options.headers.clear();
    _dio.options.headers[HttpHeaders.contentTypeHeader] =
        ContentType.json.mimeType;
    _dio.options.headers[HttpHeaders.acceptHeader] = ContentType.json.mimeType;
  }
}
