import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A widget that displays a user's profile avatar.
///
/// Shows the user's profile image if available, otherwise displays
/// the user's initials on a colored background.
///
/// Features:
/// - Cached network image loading
/// - Edit button overlay when editable
/// - Upload progress indicator
/// - Fallback to initials when no image
class ProfileAvatar extends StatelessWidget {
  /// The URL of the profile image.
  final String? imageUrl;

  /// A local file to display (takes precedence over imageUrl).
  final File? localImage;

  /// The full name of the user (used to generate initials).
  final String fullName;

  /// The size of the avatar.
  final double size;

  /// The background color when no image is available.
  final Color? backgroundColor;

  /// The text color for initials.
  final Color? textColor;

  /// The border color around the avatar.
  final Color? borderColor;

  /// The width of the border.
  final double borderWidth;

  /// Whether the avatar is editable (shows edit button).
  final bool editable;

  /// Upload progress (0.0 to 1.0). When not null, shows progress indicator.
  final double? uploadProgress;

  /// Whether an upload is in progress.
  final bool isUploading;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  /// Called when the edit button is tapped.
  final VoidCallback? onEditTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.localImage,
    required this.fullName,
    this.size = 80,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 2,
    this.editable = false,
    this.uploadProgress,
    this.isUploading = false,
    this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(fullName);
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = textColor ?? AppColors.onPrimary;

    return GestureDetector(
      onTap: onTap ?? (editable ? onEditTap : null),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar container
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: borderColor != null
                    ? Border.all(color: borderColor!, width: borderWidth)
                    : null,
              ),
              child: ClipOval(
                child: _buildAvatarContent(context, initials, bgColor, fgColor),
              ),
            ),

            // Upload progress overlay
            if (isUploading) _buildUploadOverlay(bgColor),

            // Edit button
            if (editable && !isUploading) _buildEditButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(
    BuildContext context,
    String initials,
    Color bgColor,
    Color fgColor,
  ) {
    // Priority: local image > network image > initials
    if (localImage != null) {
      return Image.file(
        localImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar(initials, bgColor, fgColor);
        },
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingAvatar(bgColor),
        errorWidget: (context, url, error) {
          return _buildInitialsAvatar(initials, bgColor, fgColor);
        },
      );
    }

    return _buildInitialsAvatar(initials, bgColor, fgColor);
  }

  Widget _buildInitialsAvatar(String initials, Color bgColor, Color fgColor) {
    return Container(
      width: size,
      height: size,
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: fgColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar(Color bgColor) {
    return Container(
      width: size,
      height: size,
      color: bgColor.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.4,
        height: size * 0.4,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUploadOverlay(Color bgColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: uploadProgress != null
              ? CircularProgressIndicator(
                  value: uploadProgress,
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                )
              : const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final buttonSize = size * 0.32;
    final iconSize = buttonSize * 0.55;

    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: onEditTap,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.camera_alt,
            color: AppColors.onPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
