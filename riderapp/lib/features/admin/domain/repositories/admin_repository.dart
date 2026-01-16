import '../../../../shared/models/user_model.dart';
import '../entities/pending_user.dart';

/// Abstract repository interface for admin operations
abstract class AdminRepository {
  /// Get all users with optional filters and pagination
  Future<PaginatedUsers> getUsers({
    UserRole? role,
    UserStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  });

  /// Get pending users waiting for approval
  Future<List<PendingUser>> getPendingUsers();

  /// Get user by ID
  Future<UserModel> getUserById(String userId);

  /// Update user information
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data);

  /// Delete user (soft delete)
  Future<void> deleteUser(String userId);

  /// Update user status (activate/deactivate/suspend)
  Future<UserModel> updateUserStatus(String userId, UserStatus status);

  /// Change user role
  Future<UserModel> changeUserRole(String userId, UserRole role);

  /// Approve a pending user
  Future<UserModel> approveUser(String userId, {UserRole? assignRole});

  /// Reject a pending user
  Future<void> rejectUser(String userId, {String? reason});

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats();
}
