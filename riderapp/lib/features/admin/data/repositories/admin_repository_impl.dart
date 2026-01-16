import '../../../../shared/models/user_model.dart';
import '../../domain/entities/pending_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Implementation of AdminRepository using remote data source
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({AdminRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AdminRemoteDataSource();

  @override
  Future<PaginatedUsers> getUsers({
    UserRole? role,
    UserStatus? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return _remoteDataSource.getUsers(
      role: role,
      status: status,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<List<PendingUser>> getPendingUsers() async {
    return _remoteDataSource.getPendingUsers();
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    return _remoteDataSource.getUserById(userId);
  }

  @override
  Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async {
    return _remoteDataSource.updateUser(userId, data);
  }

  @override
  Future<void> deleteUser(String userId) async {
    return _remoteDataSource.deleteUser(userId);
  }

  @override
  Future<UserModel> updateUserStatus(String userId, UserStatus status) async {
    return _remoteDataSource.updateUserStatus(userId, status);
  }

  @override
  Future<UserModel> changeUserRole(String userId, UserRole role) async {
    return _remoteDataSource.changeUserRole(userId, role);
  }

  @override
  Future<UserModel> approveUser(String userId, {UserRole? assignRole}) async {
    return _remoteDataSource.approveUser(userId, assignRole: assignRole);
  }

  @override
  Future<void> rejectUser(String userId, {String? reason}) async {
    return _remoteDataSource.rejectUser(userId, reason: reason);
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    return _remoteDataSource.getUserStats();
  }
}
