import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';
import '../../domain/entities/pending_user.dart';

// ============================================================================
// User List State
// ============================================================================

/// State for user list management
sealed class UserListState extends Equatable {
  const UserListState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserListInitial extends UserListState {
  const UserListInitial();
}

/// Loading state
class UserListLoading extends UserListState {
  const UserListLoading();
}

/// Loaded state with paginated users
class UserListLoaded extends UserListState {
  final PaginatedUsers paginatedUsers;
  final UserFilter filter;

  const UserListLoaded({
    required this.paginatedUsers,
    required this.filter,
  });

  @override
  List<Object?> get props => [paginatedUsers, filter];
}

/// Error state
class UserListError extends UserListState {
  final String message;

  const UserListError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Pending Approvals State
// ============================================================================

/// State for pending approvals
sealed class PendingApprovalsState extends Equatable {
  const PendingApprovalsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PendingApprovalsInitial extends PendingApprovalsState {
  const PendingApprovalsInitial();
}

/// Loading state
class PendingApprovalsLoading extends PendingApprovalsState {
  const PendingApprovalsLoading();
}

/// Loaded state with pending users
class PendingApprovalsLoaded extends PendingApprovalsState {
  final List<PendingUser> pendingUsers;

  const PendingApprovalsLoaded(this.pendingUsers);

  @override
  List<Object?> get props => [pendingUsers];
}

/// Error state
class PendingApprovalsError extends PendingApprovalsState {
  final String message;

  const PendingApprovalsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// User Detail State
// ============================================================================

/// State for user detail
sealed class UserDetailState extends Equatable {
  const UserDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserDetailInitial extends UserDetailState {
  const UserDetailInitial();
}

/// Loading state
class UserDetailLoading extends UserDetailState {
  const UserDetailLoading();
}

/// Loaded state with user
class UserDetailLoaded extends UserDetailState {
  final UserModel user;

  const UserDetailLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

/// Error state
class UserDetailError extends UserDetailState {
  final String message;

  const UserDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// User Action State
// ============================================================================

/// State for user actions (approve, reject, delete, etc.)
sealed class UserActionState extends Equatable {
  const UserActionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserActionInitial extends UserActionState {
  const UserActionInitial();
}

/// Loading state
class UserActionLoading extends UserActionState {
  final String action;

  const UserActionLoading(this.action);

  @override
  List<Object?> get props => [action];
}

/// Success state
class UserActionSuccess extends UserActionState {
  final String message;
  final UserModel? updatedUser;

  const UserActionSuccess({
    required this.message,
    this.updatedUser,
  });

  @override
  List<Object?> get props => [message, updatedUser];
}

/// Error state
class UserActionError extends UserActionState {
  final String message;

  const UserActionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Admin Stats State
// ============================================================================

/// State for admin statistics
sealed class AdminStatsState extends Equatable {
  const AdminStatsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AdminStatsInitial extends AdminStatsState {
  const AdminStatsInitial();
}

/// Loading state
class AdminStatsLoading extends AdminStatsState {
  const AdminStatsLoading();
}

/// Loaded state with stats
class AdminStatsLoaded extends AdminStatsState {
  final Map<String, dynamic> stats;

  const AdminStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Error state
class AdminStatsError extends AdminStatsState {
  final String message;

  const AdminStatsError(this.message);

  @override
  List<Object?> get props => [message];
}
