import 'dart:io';

import '../../../../shared/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// Implementation of [ProfileRepository] using remote data source.
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSource();

  @override
  Future<UserModel> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? vehicle,
    String? address,
  }) {
    return _remoteDataSource.updateProfile(
      fullName: fullName,
      phone: phone,
      email: email,
      vehicle: vehicle,
      address: address,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<UserModel> uploadProfileImage({
    required File imageFile,
    void Function(double progress)? onProgress,
  }) {
    return _remoteDataSource.uploadProfileImage(
      imageFile: imageFile,
      onProgress: onProgress,
    );
  }

  @override
  Future<UserModel> removeProfileImage() {
    return _remoteDataSource.removeProfileImage();
  }
}
