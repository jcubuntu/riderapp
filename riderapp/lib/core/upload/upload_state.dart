import 'package:equatable/equatable.dart';

/// Upload progress information
class UploadProgress extends Equatable {
  /// Bytes that have been sent
  final int bytesSent;

  /// Total bytes to send
  final int totalBytes;

  /// Upload progress percentage (0.0 to 1.0)
  final double percentage;

  const UploadProgress({
    required this.bytesSent,
    required this.totalBytes,
    required this.percentage,
  });

  /// Create an initial upload progress
  const UploadProgress.initial()
      : bytesSent = 0,
        totalBytes = 0,
        percentage = 0.0;

  /// Create upload progress from bytes
  factory UploadProgress.fromBytes(int sent, int total) {
    return UploadProgress(
      bytesSent: sent,
      totalBytes: total,
      percentage: total > 0 ? sent / total : 0.0,
    );
  }

  /// Get formatted percentage string
  String get percentageString => '${(percentage * 100).toStringAsFixed(1)}%';

  /// Get formatted bytes sent string
  String get bytesSentString => _formatBytes(bytesSent);

  /// Get formatted total bytes string
  String get totalBytesString => _formatBytes(totalBytes);

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [bytesSent, totalBytes, percentage];
}

/// Uploaded file result
class UploadedFile extends Equatable {
  /// File ID from server
  final String id;

  /// Original file name
  final String fileName;

  /// File URL on server
  final String url;

  /// File MIME type
  final String mimeType;

  /// File size in bytes
  final int size;

  /// Thumbnail URL (for images)
  final String? thumbnailUrl;

  /// Upload timestamp
  final DateTime uploadedAt;

  const UploadedFile({
    required this.id,
    required this.fileName,
    required this.url,
    required this.mimeType,
    required this.size,
    this.thumbnailUrl,
    required this.uploadedAt,
  });

  /// Create from JSON response
  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? json['filename'] as String? ?? '',
      url: json['url'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? json['contentType'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'url': url,
        'mimeType': mimeType,
        'size': size,
        'thumbnailUrl': thumbnailUrl,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  /// Check if this is an image file
  bool get isImage => mimeType.startsWith('image/');

  /// Check if this is a video file
  bool get isVideo => mimeType.startsWith('video/');

  /// Check if this is a document file
  bool get isDocument =>
      mimeType.startsWith('application/') || mimeType.startsWith('text/');

  @override
  List<Object?> get props => [id, fileName, url, mimeType, size, thumbnailUrl, uploadedAt];
}

/// Upload states using sealed class pattern
sealed class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no upload in progress
class UploadIdle extends UploadState {
  const UploadIdle();
}

/// Preparing upload - compressing/processing files
class UploadPreparing extends UploadState {
  final String? message;

  const UploadPreparing({this.message});

  @override
  List<Object?> get props => [message];
}

/// Upload in progress
class UploadInProgress extends UploadState {
  final UploadProgress progress;
  final String? fileName;
  final int? currentFileIndex;
  final int? totalFiles;

  const UploadInProgress({
    required this.progress,
    this.fileName,
    this.currentFileIndex,
    this.totalFiles,
  });

  /// Check if this is a multi-file upload
  bool get isMultiFile => totalFiles != null && totalFiles! > 1;

  /// Get upload status message
  String get statusMessage {
    if (isMultiFile && currentFileIndex != null && totalFiles != null) {
      return 'Uploading file ${currentFileIndex! + 1} of $totalFiles';
    }
    if (fileName != null) {
      return 'Uploading $fileName';
    }
    return 'Uploading...';
  }

  @override
  List<Object?> get props => [progress, fileName, currentFileIndex, totalFiles];
}

/// Upload successful
class UploadSuccess extends UploadState {
  final UploadedFile file;

  const UploadSuccess({required this.file});

  @override
  List<Object?> get props => [file];
}

/// Multiple uploads successful
class UploadMultipleSuccess extends UploadState {
  final List<UploadedFile> files;

  const UploadMultipleSuccess({required this.files});

  @override
  List<Object?> get props => [files];
}

/// Upload failed
class UploadError extends UploadState {
  final String message;
  final String? code;
  final bool canRetry;

  const UploadError({
    required this.message,
    this.code,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, code, canRetry];
}

/// Upload cancelled
class UploadCancelled extends UploadState {
  const UploadCancelled();
}

/// File validation error
class UploadValidationError extends UploadState {
  final String message;
  final List<String>? invalidFiles;

  const UploadValidationError({
    required this.message,
    this.invalidFiles,
  });

  @override
  List<Object?> get props => [message, invalidFiles];
}
