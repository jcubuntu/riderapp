import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/models/user_model.dart';

/// Auth repository for making API calls
class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorage();

  /// Login with phone and password
  Future<AuthResult> login({
    required String phone,
    required String password,
    String? deviceName,
    String? deviceType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          'password': password,
          if (deviceName != null) 'deviceName': deviceName,
          if (deviceType != null) 'deviceType': deviceType,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>;
        final tokens = responseData['tokens'] as Map<String, dynamic>;

        final user = UserModel.fromJson(userData);
        final accessToken = tokens['accessToken'] as String;
        final refreshToken = tokens['refreshToken'] as String;

        // Save tokens to secure storage
        await _secureStorage.saveAuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await _secureStorage.saveUserId(user.id);
        await _secureStorage.saveUserPhone(user.phone);

        return AuthResult(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        throw AuthException(
          message: data['message'] as String? ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Login failed';
      String? status;

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
        final errors = errorData['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          status = errors['status'] as String?;
        }
      }

      throw AuthException(
        message: message,
        statusCode: e.response?.statusCode,
        status: status,
      );
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String password,
    required String fullName,
    required String phone,
    required String idCardNumber,
    String? affiliation,
    String? address,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'idCardNumber': idCardNumber,
          if (affiliation != null) 'affiliation': affiliation,
          if (address != null) 'address': address,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>;
        final requiresApproval = responseData['requiresApproval'] as bool? ?? true;

        final user = UserModel.fromJson(userData);

        // Save user ID for status checking
        await _secureStorage.saveUserId(user.id);
        await _secureStorage.saveUserPhone(user.phone);

        return AuthResult(
          user: user,
          requiresApproval: requiresApproval,
        );
      } else {
        throw AuthException(
          message: data['message'] as String? ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Registration failed';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AuthException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Refresh access token
  Future<AuthResult> refreshTokens() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw AuthException(message: 'No refresh token available');
      }

      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final tokens = responseData['tokens'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>?;

        final newAccessToken = tokens['accessToken'] as String;
        final newRefreshToken = tokens['refreshToken'] as String;

        // Save new tokens
        await _secureStorage.saveAuthTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        UserModel? user;
        if (userData != null) {
          user = UserModel.fromJson(userData);
        }

        return AuthResult(
          user: user,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
      } else {
        throw AuthException(
          message: data['message'] as String? ?? 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Token refresh failed';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AuthException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();

      await _apiClient.post(
        ApiEndpoints.logout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
        },
      );
    } catch (_) {
      // Ignore errors during logout
    } finally {
      // Clear local storage regardless of API result
      await _secureStorage.onLogout();
    }
  }

  /// Check approval status
  Future<ApprovalStatus> checkApprovalStatus(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.checkStatus,
        queryParameters: {'userId': userId},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final status = responseData['status'] as String;
        final userData = responseData['user'] as Map<String, dynamic>;

        return ApprovalStatus(
          status: status,
          user: UserModel.fromJson(userData),
          approvedAt: responseData['approvedAt'] as String?,
        );
      } else {
        throw AuthException(
          message: data['message'] as String? ?? 'Status check failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Status check failed';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AuthException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final userData = responseData['user'] as Map<String, dynamic>;

        return UserModel.fromJson(userData);
      } else {
        throw AuthException(
          message: data['message'] as String? ?? 'Failed to get user',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Failed to get user';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AuthException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Check if user has stored tokens
  Future<bool> hasStoredTokens() async {
    return await _secureStorage.hasAccessToken();
  }

  /// Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _secureStorage.getUserId();
  }
}

/// Result from auth operations
class AuthResult {
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresApproval;

  AuthResult({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.requiresApproval = false,
  });
}

/// Approval status result
class ApprovalStatus {
  final String status;
  final UserModel user;
  final String? approvedAt;

  ApprovalStatus({
    required this.status,
    required this.user,
    this.approvedAt,
  });
}

/// Auth exception
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? status;

  AuthException({
    required this.message,
    this.statusCode,
    this.status,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  @override
  String toString() => message;
}
