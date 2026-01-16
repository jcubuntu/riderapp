import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A reusable bottom sheet widget for selecting images from camera or gallery.
///
/// Provides a clean Material 3 design with options for:
/// - Taking a new photo with the camera
/// - Selecting an existing image from the gallery
/// - Removing the current image (optional)
class ImagePickerSheet extends StatelessWidget {
  /// Whether to show the remove image option.
  final bool showRemoveOption;

  /// Callback when an image is selected.
  final void Function(File image)? onImageSelected;

  /// Callback when remove is selected.
  final VoidCallback? onRemoveSelected;

  /// Maximum width for the selected image.
  final double? maxWidth;

  /// Maximum height for the selected image.
  final double? maxHeight;

  /// Image quality (0-100).
  final int imageQuality;

  const ImagePickerSheet({
    super.key,
    this.showRemoveOption = false,
    this.onImageSelected,
    this.onRemoveSelected,
    this.maxWidth = 1024,
    this.maxHeight = 1024,
    this.imageQuality = 85,
  });

  /// Show the image picker bottom sheet.
  ///
  /// Returns the selected [File] or null if cancelled.
  /// Returns a special marker if remove was selected (check via callback).
  static Future<File?> show(
    BuildContext context, {
    bool showRemoveOption = false,
    double? maxWidth = 1024,
    double? maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    File? selectedImage;
    bool removeSelected = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerSheet(
        showRemoveOption: showRemoveOption,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        onImageSelected: (image) {
          selectedImage = image;
          Navigator.of(context).pop();
        },
        onRemoveSelected: () {
          removeSelected = true;
          Navigator.of(context).pop();
        },
      ),
    );

    if (removeSelected) {
      return null; // Caller should check if remove was requested via separate callback
    }

    return selectedImage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'profile.selectImage'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Divider(height: 1),

            // Camera option
            _buildOption(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: 'profile.takePhoto'.tr(),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),

            // Gallery option
            _buildOption(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'profile.chooseFromGallery'.tr(),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),

            // Remove option (if enabled)
            if (showRemoveOption) ...[
              const Divider(height: 1),
              _buildOption(
                context: context,
                icon: Icons.delete_outline,
                label: 'profile.removePhoto'.tr(),
                isDestructive: true,
                onTap: () {
                  onRemoveSelected?.call();
                },
              ),
            ],

            const SizedBox(height: 8),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('common.cancel'.tr()),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive
                        ? colorScheme.error
                        : colorScheme.primaryContainer)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? colorScheme.error
                    : colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        onImageSelected?.call(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.imagePickerError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
