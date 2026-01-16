import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/pending_user.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_state.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl();
});

// ============================================================================
// User List Provider
// ============================================================================

/// User list state notifier
class UserListNotifier extends StateNotifier<UserListState> {
  final AdminRepository _repository;

  UserListNotifier(this._repository) : super(const UserListInitial());

  /// Current filter
  UserFilter _currentFilter = const UserFilter();

  /// Fetch users with optional filter
  Future<void> fetchUsers({UserFilter? filter}) async {
    state = const UserListLoading();

    if (filter != null) {
      _currentFilter = filter;
    }

    try {
      final paginatedUsers = await _repository.getUsers(
        role: _currentFilter.role,
        status: _currentFilter.status,
        search: _currentFilter.search,
        page: _currentFilter.page,
        limit: _currentFilter.limit,
      );

      state = UserListLoaded(
        paginatedUsers: paginatedUsers,
        filter: _currentFilter,
      );
    } on AdminException catch (e) {
      state = UserListError(e.message);
    } catch (e) {
      state = const UserListError('Failed to load users');
    }
  }

  /// Update filter and refresh
  Future<void> updateFilter(UserFilter filter) async {
    _currentFilter = filter;
    await fetchUsers();
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (state is UserListLoaded) {
      final loaded = state as UserListLoaded;
      if (loaded.paginatedUsers.hasNextPage) {
        _currentFilter = _currentFilter.copyWith(page: _currentFilter.page + 1);
        await fetchUsers();
      }
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (state is UserListLoaded) {
      final loaded = state as UserListLoaded;
      if (loaded.paginatedUsers.hasPreviousPage) {
        _currentFilter = _currentFilter.copyWith(page: _currentFilter.page - 1);
        await fetchUsers();
      }
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    _currentFilter = _currentFilter.copyWith(page: page);
    await fetchUsers();
  }

  /// Search users
  Future<void> search(String query) async {
    _currentFilter = _currentFilter.copyWith(
      search: query.isEmpty ? null : query,
      page: 1,
      clearSearch: query.isEmpty,
    );
    await fetchUsers();
  }

  /// Filter by role
  Future<void> filterByRole(UserRole? role) async {
    _currentFilter = _currentFilter.copyWith(
      role: role,
      page: 1,
      clearRole: role == null,
    );
    await fetchUsers();
  }

  /// Filter by status
  Future<void> filterByStatus(UserStatus? status) async {
    _currentFilter = _currentFilter.copyWith(
      status: status,
      page: 1,
      clearStatus: status == null,
    );
    await fetchUsers();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _currentFilter = const UserFilter();
    await fetchUsers();
  }

  /// Refresh current list
  Future<void> refresh() async {
    await fetchUsers();
  }
}

/// User list provider
final userListProvider =
    StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return UserListNotifier(repository);
});

// ============================================================================
// Pending Approvals Provider
// ============================================================================

/// Pending approvals state notifier
class PendingApprovalsNotifier extends StateNotifier<PendingApprovalsState> {
  final AdminRepository _repository;

  PendingApprovalsNotifier(this._repository)
      : super(const PendingApprovalsInitial());

  /// Fetch pending users
  Future<void> fetchPendingUsers() async {
    state = const PendingApprovalsLoading();

    try {
      final pendingUsers = await _repository.getPendingUsers();
      state = PendingApprovalsLoaded(pendingUsers);
    } on AdminException catch (e) {
      state = PendingApprovalsError(e.message);
    } catch (e) {
      state = const PendingApprovalsError('Failed to load pending approvals');
    }
  }

  /// Refresh pending users
  Future<void> refresh() async {
    await fetchPendingUsers();
  }

  /// Remove user from pending list (after approve/reject)
  void removeUser(String userId) {
    if (state is PendingApprovalsLoaded) {
      final loaded = state as PendingApprovalsLoaded;
      final updatedList =
          loaded.pendingUsers.where((u) => u.id != userId).toList();
      state = PendingApprovalsLoaded(updatedList);
    }
  }
}

/// Pending approvals provider
final pendingApprovalsProvider =
    StateNotifierProvider<PendingApprovalsNotifier, PendingApprovalsState>(
        (ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return PendingApprovalsNotifier(repository);
});

// ============================================================================
// User Detail Provider
// ============================================================================

/// User detail state notifier
class UserDetailNotifier extends StateNotifier<UserDetailState> {
  final AdminRepository _repository;

  UserDetailNotifier(this._repository) : super(const UserDetailInitial());

  /// Fetch user by ID
  Future<void> fetchUser(String userId) async {
    state = const UserDetailLoading();

    try {
      final user = await _repository.getUserById(userId);
      state = UserDetailLoaded(user);
    } on AdminException catch (e) {
      state = UserDetailError(e.message);
    } catch (e) {
      state = const UserDetailError('Failed to load user details');
    }
  }

  /// Update user in state
  void updateUser(UserModel user) {
    state = UserDetailLoaded(user);
  }

  /// Clear state
  void clear() {
    state = const UserDetailInitial();
  }
}

/// User detail provider
final userDetailProvider =
    StateNotifierProvider<UserDetailNotifier, UserDetailState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return UserDetailNotifier(repository);
});

// ============================================================================
// User Action Provider
// ============================================================================

/// User action state notifier
class UserActionNotifier extends StateNotifier<UserActionState> {
  final AdminRepository _repository;

  UserActionNotifier(this._repository) : super(const UserActionInitial());

  /// Approve a user
  Future<bool> approveUser(String userId, {UserRole? assignRole}) async {
    state = const UserActionLoading('approving');

    try {
      final user = await _repository.approveUser(userId, assignRole: assignRole);
      state = UserActionSuccess(
        message: 'User approved successfully',
        updatedUser: user,
      );
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to approve user');
      return false;
    }
  }

  /// Reject a user
  Future<bool> rejectUser(String userId, {String? reason}) async {
    state = const UserActionLoading('rejecting');

    try {
      await _repository.rejectUser(userId, reason: reason);
      state = const UserActionSuccess(message: 'User rejected successfully');
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to reject user');
      return false;
    }
  }

  /// Update user status
  Future<bool> updateUserStatus(String userId, UserStatus status) async {
    state = const UserActionLoading('updating status');

    try {
      final user = await _repository.updateUserStatus(userId, status);
      state = UserActionSuccess(
        message: 'User status updated successfully',
        updatedUser: user,
      );
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to update user status');
      return false;
    }
  }

  /// Change user role
  Future<bool> changeUserRole(String userId, UserRole role) async {
    state = const UserActionLoading('changing role');

    try {
      final user = await _repository.changeUserRole(userId, role);
      state = UserActionSuccess(
        message: 'User role changed successfully',
        updatedUser: user,
      );
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to change user role');
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    state = const UserActionLoading('deleting');

    try {
      await _repository.deleteUser(userId);
      state = const UserActionSuccess(message: 'User deleted successfully');
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to delete user');
      return false;
    }
  }

  /// Update user information
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    state = const UserActionLoading('updating');

    try {
      final user = await _repository.updateUser(userId, data);
      state = UserActionSuccess(
        message: 'User updated successfully',
        updatedUser: user,
      );
      return true;
    } on AdminException catch (e) {
      state = UserActionError(e.message);
      return false;
    } catch (e) {
      state = const UserActionError('Failed to update user');
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const UserActionInitial();
  }
}

/// User action provider
final userActionProvider =
    StateNotifierProvider<UserActionNotifier, UserActionState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return UserActionNotifier(repository);
});

// ============================================================================
// Admin Stats Provider
// ============================================================================

/// Admin stats state notifier
class AdminStatsNotifier extends StateNotifier<AdminStatsState> {
  final AdminRepository _repository;

  AdminStatsNotifier(this._repository) : super(const AdminStatsInitial());

  /// Fetch admin stats
  Future<void> fetchStats() async {
    state = const AdminStatsLoading();

    try {
      final stats = await _repository.getUserStats();
      state = AdminStatsLoaded(stats);
    } on AdminException catch (e) {
      state = AdminStatsError(e.message);
    } catch (e) {
      state = const AdminStatsError('Failed to load statistics');
    }
  }

  /// Refresh stats
  Future<void> refresh() async {
    await fetchStats();
  }
}

/// Admin stats provider
final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AdminStatsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminStatsNotifier(repository);
});

// ============================================================================
// Simple Providers
// ============================================================================

/// Pending count provider
final pendingUserCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  try {
    final pendingUsers = await repository.getPendingUsers();
    return pendingUsers.length;
  } catch (e) {
    return 0;
  }
});

/// Total user count provider
final totalUserCountAdminProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  try {
    final paginatedUsers = await repository.getUsers(limit: 1);
    return paginatedUsers.total;
  } catch (e) {
    return 0;
  }
});
