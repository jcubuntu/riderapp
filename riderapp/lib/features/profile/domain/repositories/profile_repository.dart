import 'dart:io';

import '../../../../shared/models/user_model.dart';

/// Repository interface for profile operations.
abstract class ProfileRepository {
  /// Get the current user's profile.
  Future<UserModel> getProfile();

  /// Update the current user's profile.
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? vehicle,
    String? address,
  });

  /// Change the current user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Upload a profile image.
  ///
  /// Returns the updated [UserModel] with the new profile image URL.
  /// The [onProgress] callback is called with upload progress (0.0 to 1.0).
  Future<UserModel> uploadProfileImage({
    required File imageFile,
    void Function(double progress)? onProgress,
  });

  /// Remove the current user's profile image.
  ///
  /// Returns the updated [UserModel] with the profile image URL cleared.
  Future<UserModel> removeProfileImage();
}
