import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';

/// Remote data source for profile operations.
class ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get the current user's profile from the API.
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.me);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final userData = data['data'] ?? data;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }

    throw Exception('Failed to fetch profile');
  }

  /// Update the current user's profile via the API.
  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? vehicle,
    String? address,
  }) async {
    final body = <String, dynamic>{};

    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (vehicle != null) body['vehicle'] = vehicle;
    if (address != null) body['address'] = address;

    // Use PATCH /auth/profile endpoint (as per CLAUDE.md)
    final response = await _apiClient.patch(
      '/auth/profile',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final userData = data['data'] ?? data;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }

    throw Exception('Failed to update profile');
  }

  /// Change the current user's password via the API.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode != 200) {
      final data = response.data as Map<String, dynamic>?;
      final message = data?['message'] as String? ?? 'Failed to change password';
      throw Exception(message);
    }
  }

  /// Upload a profile image to the API.
  ///
  /// Returns the updated [UserModel] with the new profile image URL.
  Future<UserModel> uploadProfileImage({
    required File imageFile,
    void Function(double progress)? onProgress,
  }) async {
    // Get the file name and extension
    final fileName = imageFile.path.split('/').last;

    // Create multipart form data
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    // Upload the image with progress tracking
    final response = await _apiClient.uploadFile<Map<String, dynamic>>(
      ApiEndpoints.uploadProfilePicture,
      formData: formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          onProgress?.call(sent / total);
        }
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!;
      final userData = data['data'] ?? data;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }

    // Handle error response
    final errorMessage = _extractErrorMessage(response.data);
    throw Exception(errorMessage ?? 'Failed to upload profile image');
  }

  /// Remove the current user's profile image.
  ///
  /// Returns the updated [UserModel] with the profile image URL cleared.
  Future<UserModel> removeProfileImage() async {
    final response = await _apiClient.delete(
      ApiEndpoints.deleteProfilePicture,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final userData = data['data'] ?? data;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }

    // Handle error response
    final errorMessage = _extractErrorMessage(response.data);
    throw Exception(errorMessage ?? 'Failed to remove profile image');
  }

  /// Extract error message from response data.
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}
