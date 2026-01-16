import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import '../network/api_client.dart';
import 'upload_state.dart';

/// Configuration for file uploads
class UploadConfig {
  /// Maximum file size in bytes (default: 10MB)
  final int maxFileSize;

  /// Maximum image dimension for compression (default: 1920px)
  final int maxImageDimension;

  /// Image compression quality (0-100, default: 85)
  final int imageQuality;

  /// Allowed MIME types for images
  final List<String> allowedImageTypes;

  /// Allowed MIME types for documents
  final List<String> allowedDocumentTypes;

  /// Request timeout duration
  final Duration timeout;

  const UploadConfig({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxImageDimension = 1920,
    this.imageQuality = 85,
    this.allowedImageTypes = const [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
    ],
    this.allowedDocumentTypes = const [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    ],
    this.timeout = const Duration(minutes: 5),
  });

  /// Default configuration
  static const UploadConfig defaultConfig = UploadConfig();

  /// Profile image configuration (smaller size, stricter types)
  static const UploadConfig profileConfig = UploadConfig(
    maxFileSize: 5 * 1024 * 1024, // 5MB
    maxImageDimension: 1024,
    imageQuality: 80,
    allowedImageTypes: ['image/jpeg', 'image/jpg', 'image/png'],
    allowedDocumentTypes: [],
  );

  /// Incident media configuration (larger size)
  static const UploadConfig incidentConfig = UploadConfig(
    maxFileSize: 20 * 1024 * 1024, // 20MB
    maxImageDimension: 2048,
    imageQuality: 90,
  );
}

/// Callback type for upload progress
typedef UploadProgressCallback = void Function(UploadProgress progress);

/// File upload service using Dio.
///
/// Provides:
/// - Single and multiple file uploads
/// - Progress tracking
/// - Upload cancellation
/// - Retry failed uploads
/// - File validation
class UploadService {
  /// Private constructor for singleton
  UploadService._internal();

  /// Singleton instance
  static final UploadService _instance = UploadService._internal();

  /// Factory constructor returns singleton
  factory UploadService() => _instance;

  /// API client for HTTP requests
  final ApiClient _apiClient = ApiClient();

  /// Map of cancel tokens by upload ID
  final Map<String, CancelToken> _cancelTokens = {};

  /// Map of pending retries
  final Map<String, int> _retryAttempts = {};

  /// Maximum retry attempts
  static const int maxRetryAttempts = 3;

  // ============================================================================
  // FILE VALIDATION
  // ============================================================================

  /// Validate file before upload
  ValidationResult validateFile(
    File file, {
    UploadConfig config = UploadConfig.defaultConfig,
    bool isImage = false,
  }) {
    final fileName = file.path.split('/').last;

    // Check if file exists
    if (!file.existsSync()) {
      return ValidationResult.invalid('File does not exist: $fileName');
    }

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > config.maxFileSize) {
      final maxSizeMB = (config.maxFileSize / (1024 * 1024)).toStringAsFixed(1);
      return ValidationResult.invalid(
        'File "$fileName" is too large. Maximum size is ${maxSizeMB}MB',
      );
    }

    // Check file type
    final mimeType = _getMimeType(file.path);
    if (mimeType == null) {
      return ValidationResult.invalid(
        'Could not determine file type for "$fileName"',
      );
    }

    if (isImage) {
      if (!config.allowedImageTypes.contains(mimeType)) {
        return ValidationResult.invalid(
          'File type "$mimeType" is not allowed. Allowed types: ${config.allowedImageTypes.join(", ")}',
        );
      }
    } else {
      final allAllowed = [...config.allowedImageTypes, ...config.allowedDocumentTypes];
      if (!allAllowed.contains(mimeType)) {
        return ValidationResult.invalid(
          'File type "$mimeType" is not allowed.',
        );
      }
    }

    return ValidationResult.valid();
  }

  /// Validate multiple files
  ValidationResult validateFiles(
    List<File> files, {
    UploadConfig config = UploadConfig.defaultConfig,
    bool areImages = false,
  }) {
    if (files.isEmpty) {
      return ValidationResult.invalid('No files provided');
    }

    final invalidFiles = <String>[];
    for (final file in files) {
      final result = validateFile(file, config: config, isImage: areImages);
      if (!result.isValid) {
        invalidFiles.add(file.path.split('/').last);
      }
    }

    if (invalidFiles.isNotEmpty) {
      return ValidationResult.invalidMultiple(
        'Some files are invalid',
        invalidFiles,
      );
    }

    return ValidationResult.valid();
  }

  /// Get MIME type from file path
  String? _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
    };
    return mimeTypes[extension];
  }

  // ============================================================================
  // SINGLE FILE UPLOAD
  // ============================================================================

  /// Upload a single file
  ///
  /// Returns [UploadedFile] on success.
  /// Throws [ApiException] on failure.
  Future<UploadedFile> uploadFile(
    File file, {
    String endpoint = ApiEndpoints.uploadFile,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    UploadProgressCallback? onProgress,
    UploadConfig config = UploadConfig.defaultConfig,
    String? uploadId,
  }) async {
    // Generate upload ID if not provided
    final id = uploadId ?? _generateUploadId();

    // Validate file
    final validation = validateFile(file, config: config);
    if (!validation.isValid) {
      throw ApiException.badRequest(message: validation.message!);
    }

    // Create cancel token
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    try {
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(file.path);

      // Create form data
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
        ),
        if (additionalData != null) ...additionalData,
      });

      // Upload with progress
      final response = await _apiClient.uploadFile<Map<String, dynamic>>(
        endpoint,
        formData: formData,
        onSendProgress: (sent, total) {
          final progress = UploadProgress.fromBytes(sent, total);
          onProgress?.call(progress);
        },
        cancelToken: cancelToken,
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final fileData = data['data'] as Map<String, dynamic>? ?? data;
          return UploadedFile.fromJson(fileData);
        }
        throw ApiException.unknown(message: 'Invalid response format');
      }

      throw ApiException.serverError(
        message: 'Upload failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw ApiException.cancelled(message: 'Upload was cancelled');
      }

      // Check if we should retry
      if (_shouldRetry(e) && _canRetry(id)) {
        _retryAttempts[id] = (_retryAttempts[id] ?? 0) + 1;
        _log('Retrying upload (attempt ${_retryAttempts[id]})');
        return uploadFile(
          file,
          endpoint: endpoint,
          fieldName: fieldName,
          additionalData: additionalData,
          onProgress: onProgress,
          config: config,
          uploadId: id,
        );
      }

      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.network(
        message: 'Upload failed: ${e.message}',
        originalError: e,
      );
    } finally {
      _cancelTokens.remove(id);
      _retryAttempts.remove(id);
    }
  }

  // ============================================================================
  // MULTIPLE FILE UPLOAD
  // ============================================================================

  /// Upload multiple files
  ///
  /// Returns list of [UploadedFile] on success.
  /// Partially successful uploads will still return uploaded files.
  Future<List<UploadedFile>> uploadMultipleFiles(
    List<File> files, {
    String endpoint = ApiEndpoints.uploadMultipleFiles,
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
    UploadProgressCallback? onProgress,
    void Function(int currentIndex, int total)? onFileProgress,
    UploadConfig config = UploadConfig.defaultConfig,
    String? uploadId,
  }) async {
    if (files.isEmpty) {
      throw ApiException.badRequest(message: 'No files provided');
    }

    // Validate all files first
    final validation = validateFiles(files, config: config);
    if (!validation.isValid) {
      throw ApiException.badRequest(message: validation.message!);
    }

    final id = uploadId ?? _generateUploadId();
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    try {
      final multipartFiles = <MultipartFile>[];
      int totalSize = 0;

      // Prepare all files
      for (final file in files) {
        final fileName = file.path.split('/').last;
        final mimeType = _getMimeType(file.path);
        totalSize += file.lengthSync();

        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: mimeType != null ? DioMediaType.parse(mimeType) : null,
          ),
        );
      }

      // Create form data with all files
      final formData = FormData.fromMap({
        fieldName: multipartFiles,
        if (additionalData != null) ...additionalData,
      });

      // Upload with progress
      final response = await _apiClient.uploadFile<Map<String, dynamic>>(
        endpoint,
        formData: formData,
        onSendProgress: (sent, total) {
          final progress = UploadProgress.fromBytes(sent, total > 0 ? total : totalSize);
          onProgress?.call(progress);
        },
        cancelToken: cancelToken,
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final filesData = data['data'] as List? ?? [];
          return filesData
              .map((f) => UploadedFile.fromJson(f as Map<String, dynamic>))
              .toList();
        }
        throw ApiException.unknown(message: 'Invalid response format');
      }

      throw ApiException.serverError(
        message: 'Upload failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw ApiException.cancelled(message: 'Upload was cancelled');
      }
      if (e.error is ApiException) {
        rethrow;
      }
      throw ApiException.network(
        message: 'Upload failed: ${e.message}',
        originalError: e,
      );
    } finally {
      _cancelTokens.remove(id);
    }
  }

  /// Upload files sequentially (one at a time)
  ///
  /// Useful when you need individual progress for each file.
  Future<List<UploadedFile>> uploadFilesSequentially(
    List<File> files, {
    String endpoint = ApiEndpoints.uploadFile,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int currentIndex, int total, UploadProgress progress)? onProgress,
    UploadConfig config = UploadConfig.defaultConfig,
  }) async {
    final uploadedFiles = <UploadedFile>[];
    final errors = <String, String>{};

    for (var i = 0; i < files.length; i++) {
      try {
        final result = await uploadFile(
          files[i],
          endpoint: endpoint,
          fieldName: fieldName,
          additionalData: additionalData,
          onProgress: (progress) {
            onProgress?.call(i, files.length, progress);
          },
          config: config,
        );
        uploadedFiles.add(result);
      } catch (e) {
        final fileName = files[i].path.split('/').last;
        errors[fileName] = e.toString();
        _log('Failed to upload $fileName: $e');
      }
    }

    if (errors.isNotEmpty && uploadedFiles.isEmpty) {
      throw ApiException.badRequest(
        message: 'All uploads failed',
        errors: errors,
      );
    }

    return uploadedFiles;
  }

  // ============================================================================
  // PROFILE PICTURE UPLOAD
  // ============================================================================

  /// Upload profile picture
  Future<UploadedFile> uploadProfilePicture(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return uploadFile(
      file,
      endpoint: ApiEndpoints.uploadProfilePicture,
      fieldName: 'picture',
      onProgress: onProgress,
      config: UploadConfig.profileConfig,
    );
  }

  // ============================================================================
  // INCIDENT MEDIA UPLOAD
  // ============================================================================

  /// Upload incident media
  Future<List<UploadedFile>> uploadIncidentMedia(
    String incidentId,
    List<File> files, {
    void Function(int currentIndex, int total, UploadProgress progress)? onProgress,
  }) async {
    return uploadFilesSequentially(
      files,
      endpoint: ApiEndpoints.uploadIncidentMedia(incidentId),
      fieldName: 'media',
      onProgress: onProgress,
      config: UploadConfig.incidentConfig,
    );
  }

  // ============================================================================
  // CANCEL & RETRY
  // ============================================================================

  /// Cancel an upload by ID
  void cancelUpload(String uploadId) {
    final cancelToken = _cancelTokens[uploadId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Upload cancelled by user');
      _log('Cancelled upload: $uploadId');
    }
    _cancelTokens.remove(uploadId);
    _retryAttempts.remove(uploadId);
  }

  /// Cancel all uploads
  void cancelAllUploads() {
    for (final entry in _cancelTokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('All uploads cancelled');
      }
    }
    _cancelTokens.clear();
    _retryAttempts.clear();
    _log('Cancelled all uploads');
  }

  /// Check if upload should be retried
  bool _shouldRetry(DioException error) {
    // Retry on network errors or timeout
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Check if we can retry (haven't exceeded max attempts)
  bool _canRetry(String uploadId) {
    final attempts = _retryAttempts[uploadId] ?? 0;
    return attempts < maxRetryAttempts;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Generate unique upload ID
  String _generateUploadId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_cancelTokens.length}';
  }

  /// Log message in debug mode
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[UploadService] $message');
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose resources
  void dispose() {
    cancelAllUploads();
  }
}

/// Validation result for file uploads
class ValidationResult {
  final bool isValid;
  final String? message;
  final List<String>? invalidFiles;

  const ValidationResult._({
    required this.isValid,
    this.message,
    this.invalidFiles,
  });

  factory ValidationResult.valid() => const ValidationResult._(isValid: true);

  factory ValidationResult.invalid(String message) => ValidationResult._(
        isValid: false,
        message: message,
      );

  factory ValidationResult.invalidMultiple(
    String message,
    List<String> invalidFiles,
  ) =>
      ValidationResult._(
        isValid: false,
        message: message,
        invalidFiles: invalidFiles,
      );
}
