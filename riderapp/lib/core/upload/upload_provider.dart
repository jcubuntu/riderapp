import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/api_exception.dart';
import 'image_picker_helper.dart';
import 'upload_service.dart';
import 'upload_state.dart';

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

/// Provider for the upload service singleton
final uploadServiceProvider = Provider<UploadService>((ref) {
  final service = UploadService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for the image picker helper singleton
final imagePickerHelperProvider = Provider<ImagePickerHelper>((ref) {
  return ImagePickerHelper();
});

// ============================================================================
// UPLOAD STATE NOTIFIER
// ============================================================================

/// State notifier for managing upload state
class UploadNotifier extends StateNotifier<UploadState> {
  final UploadService _uploadService;
  String? _currentUploadId;

  UploadNotifier(this._uploadService) : super(const UploadIdle());

  /// Current upload ID for cancellation
  String? get currentUploadId => _currentUploadId;

  /// Reset to idle state
  void reset() {
    state = const UploadIdle();
    _currentUploadId = null;
  }

  /// Upload a single file
  Future<UploadedFile?> uploadFile(
    File file, {
    String? endpoint,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    UploadConfig config = UploadConfig.defaultConfig,
  }) async {
    // Generate upload ID
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = file.path.split('/').last;

    try {
      // Set preparing state
      state = UploadPreparing(message: 'Preparing $fileName...');

      // Validate file first
      final validation = _uploadService.validateFile(file, config: config);
      if (!validation.isValid) {
        state = UploadValidationError(
          message: validation.message!,
          invalidFiles: validation.invalidFiles,
        );
        return null;
      }

      // Upload with progress tracking
      final result = await _uploadService.uploadFile(
        file,
        endpoint: endpoint ?? _uploadService.toString(),
        fieldName: fieldName,
        additionalData: additionalData,
        config: config,
        uploadId: _currentUploadId,
        onProgress: (progress) {
          if (state is! UploadCancelled) {
            state = UploadInProgress(
              progress: progress,
              fileName: fileName,
            );
          }
        },
      );

      state = UploadSuccess(file: result);
      return result;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.cancelled) {
        state = const UploadCancelled();
      } else {
        state = UploadError(
          message: e.message,
          code: e.errorCode,
          canRetry: e.type == ApiExceptionType.network ||
              e.type == ApiExceptionType.timeout,
        );
      }
      return null;
    } catch (e) {
      state = UploadError(
        message: e.toString(),
        canRetry: true,
      );
      return null;
    } finally {
      _currentUploadId = null;
    }
  }

  /// Upload multiple files
  Future<List<UploadedFile>?> uploadMultipleFiles(
    List<File> files, {
    String? endpoint,
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
    UploadConfig config = UploadConfig.defaultConfig,
  }) async {
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Set preparing state
      state = UploadPreparing(message: 'Preparing ${files.length} files...');

      // Validate all files
      final validation = _uploadService.validateFiles(files, config: config);
      if (!validation.isValid) {
        state = UploadValidationError(
          message: validation.message!,
          invalidFiles: validation.invalidFiles,
        );
        return null;
      }

      // Upload with progress tracking
      final results = await _uploadService.uploadFilesSequentially(
        files,
        endpoint: endpoint ?? _uploadService.toString(),
        fieldName: fieldName,
        additionalData: additionalData,
        config: config,
        onProgress: (currentIndex, total, progress) {
          if (state is! UploadCancelled) {
            state = UploadInProgress(
              progress: progress,
              fileName: files[currentIndex].path.split('/').last,
              currentFileIndex: currentIndex,
              totalFiles: total,
            );
          }
        },
      );

      state = UploadMultipleSuccess(files: results);
      return results;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.cancelled) {
        state = const UploadCancelled();
      } else {
        state = UploadError(
          message: e.message,
          code: e.errorCode,
          canRetry: e.type == ApiExceptionType.network ||
              e.type == ApiExceptionType.timeout,
        );
      }
      return null;
    } catch (e) {
      state = UploadError(
        message: e.toString(),
        canRetry: true,
      );
      return null;
    } finally {
      _currentUploadId = null;
    }
  }

  /// Upload profile picture
  Future<UploadedFile?> uploadProfilePicture(File file) async {
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      state = const UploadPreparing(message: 'Preparing profile photo...');

      final result = await _uploadService.uploadProfilePicture(
        file,
        onProgress: (progress) {
          if (state is! UploadCancelled) {
            state = UploadInProgress(
              progress: progress,
              fileName: 'Profile Photo',
            );
          }
        },
      );

      state = UploadSuccess(file: result);
      return result;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.cancelled) {
        state = const UploadCancelled();
      } else {
        state = UploadError(
          message: e.message,
          code: e.errorCode,
          canRetry: true,
        );
      }
      return null;
    } catch (e) {
      state = UploadError(
        message: e.toString(),
        canRetry: true,
      );
      return null;
    } finally {
      _currentUploadId = null;
    }
  }

  /// Cancel current upload
  void cancelUpload() {
    if (_currentUploadId != null) {
      _uploadService.cancelUpload(_currentUploadId!);
      state = const UploadCancelled();
      _currentUploadId = null;
    }
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for upload state management
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final uploadService = ref.watch(uploadServiceProvider);
  return UploadNotifier(uploadService);
});

/// Provider for checking if upload is in progress
final isUploadingProvider = Provider<bool>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState is UploadInProgress || uploadState is UploadPreparing;
});

/// Provider for upload progress
final uploadProgressProvider = Provider<UploadProgress?>((ref) {
  final uploadState = ref.watch(uploadProvider);
  if (uploadState is UploadInProgress) {
    return uploadState.progress;
  }
  return null;
});

// ============================================================================
// PROFILE PICTURE UPLOAD PROVIDER
// ============================================================================

/// Dedicated provider for profile picture uploads
class ProfilePictureUploadNotifier extends StateNotifier<UploadState> {
  final UploadService _uploadService;
  final ImagePickerHelper _imagePicker;
  String? _currentUploadId;

  ProfilePictureUploadNotifier(this._uploadService, this._imagePicker)
      : super(const UploadIdle());

  /// Reset state
  void reset() {
    state = const UploadIdle();
    _currentUploadId = null;
  }

  /// Pick and upload profile picture
  Future<UploadedFile?> pickAndUploadProfilePicture(
    ImagePickerSource source,
  ) async {
    try {
      // Pick and crop image
      final file = await _imagePicker.pickProfilePicture(source: source);
      if (file == null) {
        return null;
      }

      return await uploadProfilePicture(file);
    } catch (e) {
      state = UploadError(
        message: e.toString(),
        canRetry: true,
      );
      return null;
    }
  }

  /// Upload profile picture file
  Future<UploadedFile?> uploadProfilePicture(File file) async {
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      state = const UploadPreparing(message: 'Preparing...');

      final result = await _uploadService.uploadProfilePicture(
        file,
        onProgress: (progress) {
          if (state is! UploadCancelled) {
            state = UploadInProgress(progress: progress);
          }
        },
      );

      state = UploadSuccess(file: result);
      return result;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.cancelled) {
        state = const UploadCancelled();
      } else {
        state = UploadError(
          message: e.message,
          canRetry: true,
        );
      }
      return null;
    } catch (e) {
      state = UploadError(
        message: e.toString(),
        canRetry: true,
      );
      return null;
    } finally {
      _currentUploadId = null;
    }
  }

  /// Cancel upload
  void cancelUpload() {
    if (_currentUploadId != null) {
      _uploadService.cancelUpload(_currentUploadId!);
      state = const UploadCancelled();
      _currentUploadId = null;
    }
  }
}

/// Provider for profile picture uploads
final profilePictureUploadProvider =
    StateNotifierProvider<ProfilePictureUploadNotifier, UploadState>((ref) {
  final uploadService = ref.watch(uploadServiceProvider);
  final imagePicker = ref.watch(imagePickerHelperProvider);
  return ProfilePictureUploadNotifier(uploadService, imagePicker);
});

// ============================================================================
// INCIDENT MEDIA UPLOAD PROVIDER
// ============================================================================

/// State for incident media uploads
class IncidentMediaState {
  final UploadState uploadState;
  final List<UploadedFile> uploadedFiles;

  const IncidentMediaState({
    this.uploadState = const UploadIdle(),
    this.uploadedFiles = const [],
  });

  IncidentMediaState copyWith({
    UploadState? uploadState,
    List<UploadedFile>? uploadedFiles,
  }) {
    return IncidentMediaState(
      uploadState: uploadState ?? this.uploadState,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
    );
  }
}

/// Notifier for incident media uploads
class IncidentMediaUploadNotifier extends StateNotifier<IncidentMediaState> {
  final UploadService _uploadService;
  final ImagePickerHelper _imagePicker;
  String? _currentUploadId;

  IncidentMediaUploadNotifier(this._uploadService, this._imagePicker)
      : super(const IncidentMediaState());

  /// Reset state
  void reset() {
    state = const IncidentMediaState();
    _currentUploadId = null;
  }

  /// Clear uploaded files
  void clearUploadedFiles() {
    state = state.copyWith(uploadedFiles: []);
  }

  /// Pick and add images
  Future<void> pickAndAddImages({
    ImagePickerSource? source,
    int maxImages = 5,
  }) async {
    try {
      List<File> files = [];

      if (source == null) {
        // Pick from gallery with multiple selection
        files = await _imagePicker.pickMultipleImages(
          options: ImagePickerOptions.incident,
          limit: maxImages - state.uploadedFiles.length,
        );
      } else if (source == ImagePickerSource.camera) {
        final file = await _imagePicker.pickFromCamera(
          options: ImagePickerOptions.incident,
        );
        if (file != null) files = [file];
      } else {
        files = await _imagePicker.pickMultipleImages(
          options: ImagePickerOptions.incident,
          limit: maxImages - state.uploadedFiles.length,
        );
      }

      if (files.isEmpty) return;

      // Check max limit
      final currentCount = state.uploadedFiles.length;
      if (currentCount + files.length > maxImages) {
        final allowedCount = maxImages - currentCount;
        files = files.take(allowedCount).toList();
      }

      // Store pending files for later upload
      _log('Selected ${files.length} files for upload');
    } catch (e) {
      state = state.copyWith(
        uploadState: UploadError(message: e.toString()),
      );
    }
  }

  /// Upload incident media files
  Future<List<UploadedFile>?> uploadIncidentMedia(
    String incidentId,
    List<File> files,
  ) async {
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      state = state.copyWith(
        uploadState: UploadPreparing(
          message: 'Preparing ${files.length} files...',
        ),
      );

      final results = await _uploadService.uploadIncidentMedia(
        incidentId,
        files,
        onProgress: (currentIndex, total, progress) {
          state = state.copyWith(
            uploadState: UploadInProgress(
              progress: progress,
              fileName: files[currentIndex].path.split('/').last,
              currentFileIndex: currentIndex,
              totalFiles: total,
            ),
          );
        },
      );

      state = state.copyWith(
        uploadState: UploadMultipleSuccess(files: results),
        uploadedFiles: [...state.uploadedFiles, ...results],
      );

      return results;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.cancelled) {
        state = state.copyWith(uploadState: const UploadCancelled());
      } else {
        state = state.copyWith(
          uploadState: UploadError(
            message: e.message,
            canRetry: true,
          ),
        );
      }
      return null;
    } catch (e) {
      state = state.copyWith(
        uploadState: UploadError(
          message: e.toString(),
          canRetry: true,
        ),
      );
      return null;
    } finally {
      _currentUploadId = null;
    }
  }

  /// Remove an uploaded file from the list
  void removeUploadedFile(String fileId) {
    state = state.copyWith(
      uploadedFiles: state.uploadedFiles.where((f) => f.id != fileId).toList(),
    );
  }

  /// Cancel current upload
  void cancelUpload() {
    if (_currentUploadId != null) {
      _uploadService.cancelUpload(_currentUploadId!);
      state = state.copyWith(uploadState: const UploadCancelled());
      _currentUploadId = null;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[IncidentMediaUpload] $message');
    }
  }
}

/// Provider for incident media uploads
final incidentMediaUploadProvider =
    StateNotifierProvider<IncidentMediaUploadNotifier, IncidentMediaState>((ref) {
  final uploadService = ref.watch(uploadServiceProvider);
  final imagePicker = ref.watch(imagePickerHelperProvider);
  return IncidentMediaUploadNotifier(uploadService, imagePicker);
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider for checking if profile picture upload is in progress
final isUploadingProfilePictureProvider = Provider<bool>((ref) {
  final state = ref.watch(profilePictureUploadProvider);
  return state is UploadInProgress || state is UploadPreparing;
});

/// Provider for checking if incident media upload is in progress
final isUploadingIncidentMediaProvider = Provider<bool>((ref) {
  final state = ref.watch(incidentMediaUploadProvider);
  return state.uploadState is UploadInProgress ||
      state.uploadState is UploadPreparing;
});

/// Provider for getting uploaded incident media files
final uploadedIncidentMediaProvider = Provider<List<UploadedFile>>((ref) {
  final state = ref.watch(incidentMediaUploadProvider);
  return state.uploadedFiles;
});
