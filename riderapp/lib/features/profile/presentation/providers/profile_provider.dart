import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Profile repository provider.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

/// Profile state notifier provider.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return ProfileNotifier(repository, authNotifier);
});

/// Password change state notifier provider.
final passwordChangeProvider =
    StateNotifierProvider<PasswordChangeNotifier, PasswordChangeState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return PasswordChangeNotifier(repository);
});

/// Image upload state notifier provider.
final imageUploadProvider =
    StateNotifierProvider<ImageUploadNotifier, ImageUploadState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return ImageUploadNotifier(repository, authNotifier);
});

/// Image removal state notifier provider.
final imageRemovalProvider =
    StateNotifierProvider<ImageRemovalNotifier, ImageRemovalState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return ImageRemovalNotifier(repository, authNotifier);
});

/// Profile notifier class.
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final AuthNotifier _authNotifier;

  ProfileNotifier(this._repository, this._authNotifier)
      : super(const ProfileInitial());

  /// Load the current user's profile.
  Future<void> loadProfile() async {
    state = const ProfileLoading();

    try {
      final user = await _repository.getProfile();
      state = ProfileLoaded(user: user);
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }

  /// Update the current user's profile.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? vehicle,
    String? address,
  }) async {
    state = const ProfileLoading();

    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        email: email,
        vehicle: vehicle,
        address: address,
      );

      // Update auth state with new user data
      _authNotifier.updateUser(user);

      state = ProfileUpdateSuccess(user: user);
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }

  /// Reset state to initial.
  void reset() {
    state = const ProfileInitial();
  }
}

/// Password change notifier class.
class PasswordChangeNotifier extends StateNotifier<PasswordChangeState> {
  final ProfileRepository _repository;

  PasswordChangeNotifier(this._repository)
      : super(const PasswordChangeInitial());

  /// Change the current user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const PasswordChangeLoading();

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = const PasswordChangeSuccess();
    } catch (e) {
      state = PasswordChangeError(e.toString());
    }
  }

  /// Reset state to initial.
  void reset() {
    state = const PasswordChangeInitial();
  }
}

/// Image upload notifier class.
class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  final ProfileRepository _repository;
  final AuthNotifier _authNotifier;

  ImageUploadNotifier(this._repository, this._authNotifier)
      : super(const ImageUploadInitial());

  /// Upload a profile image.
  Future<void> uploadProfileImage(File imageFile) async {
    state = const ImageUploadInProgress(progress: 0.0);

    try {
      final user = await _repository.uploadProfileImage(
        imageFile: imageFile,
        onProgress: (progress) {
          if (mounted) {
            state = ImageUploadInProgress(progress: progress);
          }
        },
      );

      // Update auth state with new user data
      _authNotifier.updateUser(user);

      state = ImageUploadSuccess(
        imageUrl: user.profileImageUrl ?? '',
        user: user,
      );
    } catch (e) {
      state = ImageUploadError(e.toString());
    }
  }

  /// Reset state to initial.
  void reset() {
    state = const ImageUploadInitial();
  }
}

/// Image removal notifier class.
class ImageRemovalNotifier extends StateNotifier<ImageRemovalState> {
  final ProfileRepository _repository;
  final AuthNotifier _authNotifier;

  ImageRemovalNotifier(this._repository, this._authNotifier)
      : super(const ImageRemovalInitial());

  /// Remove the current user's profile image.
  Future<void> removeProfileImage() async {
    state = const ImageRemovalInProgress();

    try {
      final user = await _repository.removeProfileImage();

      // Update auth state with new user data
      _authNotifier.updateUser(user);

      state = ImageRemovalSuccess(user: user);
    } catch (e) {
      state = ImageRemovalError(e.toString());
    }
  }

  /// Reset state to initial.
  void reset() {
    state = const ImageRemovalInitial();
  }
}
