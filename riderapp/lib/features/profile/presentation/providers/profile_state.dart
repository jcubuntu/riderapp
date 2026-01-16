import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';

/// Profile states using sealed class pattern.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded yet.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state - fetching or updating profile.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Loaded state - profile data is available.
class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Error state - an error occurred.
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Update success state - profile was updated successfully.
class ProfileUpdateSuccess extends ProfileState {
  final UserModel user;
  final String message;

  const ProfileUpdateSuccess({
    required this.user,
    this.message = 'Profile updated successfully',
  });

  @override
  List<Object?> get props => [user, message];
}

/// Password change states.
sealed class PasswordChangeState extends Equatable {
  const PasswordChangeState();

  @override
  List<Object?> get props => [];
}

/// Initial password change state.
class PasswordChangeInitial extends PasswordChangeState {
  const PasswordChangeInitial();
}

/// Loading password change state.
class PasswordChangeLoading extends PasswordChangeState {
  const PasswordChangeLoading();
}

/// Password change success state.
class PasswordChangeSuccess extends PasswordChangeState {
  const PasswordChangeSuccess();
}

/// Password change error state.
class PasswordChangeError extends PasswordChangeState {
  final String message;

  const PasswordChangeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Image upload states.
sealed class ImageUploadState extends Equatable {
  const ImageUploadState();

  @override
  List<Object?> get props => [];
}

/// Initial image upload state.
class ImageUploadInitial extends ImageUploadState {
  const ImageUploadInitial();
}

/// Image upload in progress state.
class ImageUploadInProgress extends ImageUploadState {
  /// Upload progress (0.0 to 1.0).
  final double progress;

  const ImageUploadInProgress({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

/// Image upload success state.
class ImageUploadSuccess extends ImageUploadState {
  /// The URL of the uploaded image.
  final String imageUrl;

  /// The updated user model.
  final UserModel user;

  const ImageUploadSuccess({
    required this.imageUrl,
    required this.user,
  });

  @override
  List<Object?> get props => [imageUrl, user];
}

/// Image upload error state.
class ImageUploadError extends ImageUploadState {
  final String message;

  const ImageUploadError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Image removal states.
sealed class ImageRemovalState extends Equatable {
  const ImageRemovalState();

  @override
  List<Object?> get props => [];
}

/// Initial image removal state.
class ImageRemovalInitial extends ImageRemovalState {
  const ImageRemovalInitial();
}

/// Image removal in progress state.
class ImageRemovalInProgress extends ImageRemovalState {
  const ImageRemovalInProgress();
}

/// Image removal success state.
class ImageRemovalSuccess extends ImageRemovalState {
  /// The updated user model.
  final UserModel user;

  const ImageRemovalSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Image removal error state.
class ImageRemovalError extends ImageRemovalState {
  final String message;

  const ImageRemovalError(this.message);

  @override
  List<Object?> get props => [message];
}
