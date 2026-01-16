import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Image source options
enum ImagePickerSource {
  camera,
  gallery,
}

/// Options for image picking
class ImagePickerOptions {
  /// Maximum image width
  final double? maxWidth;

  /// Maximum image height
  final double? maxHeight;

  /// Image quality (0-100)
  final int? imageQuality;

  /// Preferred camera device for camera source
  final CameraDevice preferredCameraDevice;

  /// Whether to request full metadata
  final bool requestFullMetadata;

  const ImagePickerOptions({
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.preferredCameraDevice = CameraDevice.rear,
    this.requestFullMetadata = true,
  });

  /// Default options for profile pictures
  static const ImagePickerOptions profile = ImagePickerOptions(
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 80,
  );

  /// Default options for incident photos
  static const ImagePickerOptions incident = ImagePickerOptions(
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 90,
  );

  /// Default options for chat attachments
  static const ImagePickerOptions chat = ImagePickerOptions(
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );
}

/// Options for image cropping
class ImageCropperOptions {
  /// Aspect ratio X
  final double? aspectRatioX;

  /// Aspect ratio Y
  final double? aspectRatioY;

  /// Lock aspect ratio
  final bool lockAspectRatio;

  /// Crop style (circle or rectangle)
  final CropStyle cropStyle;

  /// Compress quality (0-100)
  final int compressQuality;

  /// Toolbar title
  final String? toolbarTitle;

  /// Active controls color
  final Color? activeControlsColor;

  const ImageCropperOptions({
    this.aspectRatioX,
    this.aspectRatioY,
    this.lockAspectRatio = false,
    this.cropStyle = CropStyle.rectangle,
    this.compressQuality = 90,
    this.toolbarTitle,
    this.activeControlsColor,
  });

  /// Profile picture cropping options (1:1 ratio, circular)
  static const ImageCropperOptions profile = ImageCropperOptions(
    aspectRatioX: 1,
    aspectRatioY: 1,
    lockAspectRatio: true,
    cropStyle: CropStyle.circle,
    compressQuality: 85,
    toolbarTitle: 'Crop Profile Photo',
  );

  /// Square cropping options
  static const ImageCropperOptions square = ImageCropperOptions(
    aspectRatioX: 1,
    aspectRatioY: 1,
    lockAspectRatio: true,
    cropStyle: CropStyle.rectangle,
    compressQuality: 90,
  );

  /// 16:9 cropping options (landscape)
  static const ImageCropperOptions landscape = ImageCropperOptions(
    aspectRatioX: 16,
    aspectRatioY: 9,
    lockAspectRatio: true,
    cropStyle: CropStyle.rectangle,
    compressQuality: 90,
  );

  /// Free form cropping
  static const ImageCropperOptions freeForm = ImageCropperOptions(
    lockAspectRatio: false,
    cropStyle: CropStyle.rectangle,
    compressQuality: 90,
  );
}

/// Options for document picking
class DocumentPickerOptions {
  /// Allowed file extensions
  final List<String>? allowedExtensions;

  /// Allow multiple selection
  final bool allowMultiple;

  /// File type filter
  final FileType type;

  const DocumentPickerOptions({
    this.allowedExtensions,
    this.allowMultiple = false,
    this.type = FileType.any,
  });

  /// PDF documents only
  static const DocumentPickerOptions pdf = DocumentPickerOptions(
    allowedExtensions: ['pdf'],
    type: FileType.custom,
  );

  /// Image files only
  static const DocumentPickerOptions images = DocumentPickerOptions(
    type: FileType.image,
  );

  /// Common document types
  static const DocumentPickerOptions documents = DocumentPickerOptions(
    allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    type: FileType.custom,
  );

  /// All media (images and videos)
  static const DocumentPickerOptions media = DocumentPickerOptions(
    type: FileType.media,
  );
}

/// Helper class for picking and cropping images.
///
/// Provides unified interface for:
/// - Picking images from camera or gallery
/// - Picking multiple images
/// - Cropping images
/// - Picking documents
class ImagePickerHelper {
  /// Private constructor for singleton
  ImagePickerHelper._internal();

  /// Singleton instance
  static final ImagePickerHelper _instance = ImagePickerHelper._internal();

  /// Factory constructor returns singleton
  factory ImagePickerHelper() => _instance;

  /// ImagePicker instance
  final ImagePicker _imagePicker = ImagePicker();

  /// ImageCropper instance
  final ImageCropper _imageCropper = ImageCropper();

  // ============================================================================
  // PICK SINGLE IMAGE
  // ============================================================================

  /// Pick a single image from camera or gallery
  Future<File?> pickImage({
    required ImagePickerSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source == ImagePickerSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        imageQuality: options.imageQuality,
        preferredCameraDevice: options.preferredCameraDevice,
        requestFullMetadata: options.requestFullMetadata,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _log('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickFromCamera({
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return pickImage(source: ImagePickerSource.camera, options: options);
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery({
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return pickImage(source: ImagePickerSource.gallery, options: options);
  }

  // ============================================================================
  // PICK MULTIPLE IMAGES
  // ============================================================================

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    ImagePickerOptions options = const ImagePickerOptions(),
    int? limit,
  }) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        imageQuality: options.imageQuality,
        requestFullMetadata: options.requestFullMetadata,
        limit: limit,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      _log('Error picking multiple images: $e');
      return [];
    }
  }

  // ============================================================================
  // IMAGE CROPPING
  // ============================================================================

  /// Crop an image file
  Future<File?> cropImage(
    File imageFile, {
    ImageCropperOptions options = const ImageCropperOptions(),
    BuildContext? context,
  }) async {
    try {
      // Get theme colors for cropper UI
      Color activeColor = options.activeControlsColor ?? Colors.blue;
      if (context != null) {
        activeColor = Theme.of(context).primaryColor;
      }

      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: options.aspectRatioX != null && options.aspectRatioY != null
            ? CropAspectRatio(
                ratioX: options.aspectRatioX!,
                ratioY: options.aspectRatioY!,
              )
            : null,
        compressQuality: options.compressQuality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: options.toolbarTitle ?? 'Crop Image',
            toolbarColor: activeColor,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: activeColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: options.lockAspectRatio,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: options.toolbarTitle ?? 'Crop Image',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
            aspectRatioLockEnabled: options.lockAspectRatio,
            resetAspectRatioEnabled: !options.lockAspectRatio,
            aspectRatioPickerButtonHidden: options.lockAspectRatio,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      _log('Error cropping image: $e');
      return null;
    }
  }

  /// Pick and crop image in one step
  Future<File?> pickAndCropImage({
    required ImagePickerSource source,
    ImagePickerOptions pickerOptions = const ImagePickerOptions(),
    ImageCropperOptions cropperOptions = const ImageCropperOptions(),
    BuildContext? context,
  }) async {
    final pickedFile = await pickImage(
      source: source,
      options: pickerOptions,
    );

    if (pickedFile != null && context != null && context.mounted) {
      return cropImage(
        pickedFile,
        options: cropperOptions,
        context: context,
      );
    } else if (pickedFile != null) {
      // Context not available or not mounted, return uncropped file
      return cropImage(
        pickedFile,
        options: cropperOptions,
      );
    }
    return null;
  }

  /// Pick profile picture (from camera/gallery with circular crop)
  Future<File?> pickProfilePicture({
    required ImagePickerSource source,
    BuildContext? context,
  }) async {
    return pickAndCropImage(
      source: source,
      pickerOptions: ImagePickerOptions.profile,
      cropperOptions: ImageCropperOptions.profile,
      context: context,
    );
  }

  // ============================================================================
  // DOCUMENT PICKING
  // ============================================================================

  /// Pick a single document
  Future<File?> pickDocument({
    DocumentPickerOptions options = const DocumentPickerOptions(),
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: options.type,
        allowedExtensions: options.allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      _log('Error picking document: $e');
      return null;
    }
  }

  /// Pick multiple documents
  Future<List<File>> pickMultipleDocuments({
    DocumentPickerOptions options = const DocumentPickerOptions(),
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: options.type,
        allowedExtensions: options.allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      _log('Error picking multiple documents: $e');
      return [];
    }
  }

  /// Pick PDF file
  Future<File?> pickPdf() async {
    return pickDocument(options: DocumentPickerOptions.pdf);
  }

  // ============================================================================
  // VIDEO PICKING
  // ============================================================================

  /// Pick video from camera or gallery
  Future<File?> pickVideo({
    required ImagePickerSource source,
    Duration? maxDuration,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source == ImagePickerSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxDuration: maxDuration,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _log('Error picking video: $e');
      return null;
    }
  }

  // ============================================================================
  // DIALOG HELPER
  // ============================================================================

  /// Show source selection dialog (camera or gallery)
  Future<ImagePickerSource?> showSourceSelectionDialog(
    BuildContext context, {
    String? title,
    String? cameraLabel,
    String? galleryLabel,
    String? cancelLabel,
  }) async {
    return showModalBottomSheet<ImagePickerSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(cameraLabel ?? 'Camera'),
                  onTap: () {
                    Navigator.of(context).pop(ImagePickerSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(galleryLabel ?? 'Gallery'),
                  onTap: () {
                    Navigator.of(context).pop(ImagePickerSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(cancelLabel ?? 'Cancel'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pick image with source selection dialog
  Future<File?> pickImageWithDialog(
    BuildContext context, {
    ImagePickerOptions options = const ImagePickerOptions(),
    String? title,
  }) async {
    final source = await showSourceSelectionDialog(
      context,
      title: title ?? 'Select Image Source',
    );

    if (source != null) {
      return pickImage(source: source, options: options);
    }
    return null;
  }

  /// Pick and crop image with source selection dialog
  Future<File?> pickAndCropImageWithDialog(
    BuildContext context, {
    ImagePickerOptions pickerOptions = const ImagePickerOptions(),
    ImageCropperOptions cropperOptions = const ImageCropperOptions(),
    String? title,
  }) async {
    final source = await showSourceSelectionDialog(
      context,
      title: title ?? 'Select Image Source',
    );

    if (source != null && context.mounted) {
      return pickAndCropImage(
        source: source,
        pickerOptions: pickerOptions,
        cropperOptions: cropperOptions,
        context: context,
      );
    }
    return null;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Log message in debug mode
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ImagePickerHelper] $message');
    }
  }

  /// Check if device has camera
  Future<bool> get hasCamera async {
    // On mobile, cameras are typically available
    // This is a simplified check - you might want to use device_info_plus
    // for more accurate detection
    return Platform.isAndroid || Platform.isIOS;
  }
}
