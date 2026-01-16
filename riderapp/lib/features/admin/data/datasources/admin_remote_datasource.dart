import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/entities/pending_user.dart';

/// Exception for admin API errors
class AdminException implements Exception {
  final String message;
  final int? statusCode;

  AdminException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Remote data source for admin operations
class AdminRemoteDataSource {
  final ApiClient _apiClient;

  static const String _usersPrefix = '/users';

  AdminRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all users with optional filters and pagination
  Future<PaginatedUsers> getUsers({
    UserRole? role,
    UserStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (role != null) {
        queryParams['role'] = role == UserRole.superAdmin ? 'super_admin' : role.name;
      }
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(
        _usersPrefix,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        return PaginatedUsers.fromJson(responseData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to fetch users',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch users');
    }
  }

  /// Get pending users waiting for approval
  Future<List<PendingUser>> getPendingUsers() async {
    try {
      final response = await _apiClient.get('$_usersPrefix/pending');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final usersList = responseData['users'] as List<dynamic>? ?? [];
        return usersList
            .map((e) => PendingUser.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to fetch pending users',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch pending users');
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _apiClient.get('$_usersPrefix/$userId');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
        return UserModel.fromJson(userData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to fetch user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch user');
    }
  }

  /// Update user information
  Future<UserModel> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiClient.put(
        '$_usersPrefix/$userId',
        data: updateData,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
        return UserModel.fromJson(userData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to update user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update user');
    }
  }

  /// Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      final response = await _apiClient.delete('$_usersPrefix/$userId');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to delete user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete user');
    }
  }

  /// Update user status (activate/deactivate/suspend)
  Future<UserModel> updateUserStatus(String userId, UserStatus status) async {
    try {
      final response = await _apiClient.patch(
        '$_usersPrefix/$userId/status',
        data: {'status': status.name},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
        return UserModel.fromJson(userData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to update user status',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update user status');
    }
  }

  /// Change user role
  Future<UserModel> changeUserRole(String userId, UserRole role) async {
    try {
      final response = await _apiClient.patch(
        '$_usersPrefix/$userId/role',
        data: {'role': role == UserRole.superAdmin ? 'super_admin' : role.name},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
        return UserModel.fromJson(userData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to change user role',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to change user role');
    }
  }

  /// Approve a pending user
  Future<UserModel> approveUser(String userId, {UserRole? assignRole}) async {
    try {
      final requestData = <String, dynamic>{};
      if (assignRole != null) {
        requestData['role'] = assignRole == UserRole.superAdmin ? 'super_admin' : assignRole.name;
      }

      final response = await _apiClient.post(
        '$_usersPrefix/$userId/approve',
        data: requestData.isNotEmpty ? requestData : null,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>? ?? responseData;
        return UserModel.fromJson(userData);
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to approve user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to approve user');
    }
  }

  /// Reject a pending user
  Future<void> rejectUser(String userId, {String? reason}) async {
    try {
      final response = await _apiClient.post(
        '$_usersPrefix/$userId/reject',
        data: reason != null ? {'reason': reason} : null,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to reject user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to reject user');
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _apiClient.get('$_usersPrefix/stats');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw AdminException(
          message: data['message'] as String? ?? 'Failed to fetch user stats',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch user stats');
    }
  }

  /// Handle Dio errors
  AdminException _handleDioError(DioException e, String defaultMessage) {
    final errorData = e.response?.data;
    String message = defaultMessage;

    if (errorData is Map<String, dynamic>) {
      message = errorData['message'] as String? ?? message;
    }

    return AdminException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
