import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';

/// Authentication states
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - processing auth request
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in and approved
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String accessToken;

  const AuthAuthenticated({
    required this.user,
    required this.accessToken,
  });

  @override
  List<Object?> get props => [user, accessToken];
}

/// Pending approval state - user registered but waiting for approval
class AuthPendingApproval extends AuthState {
  final UserModel user;

  const AuthPendingApproval({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - user is not logged in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state - auth error occurred
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Rejected state - user registration was rejected
class AuthRejected extends AuthState {
  final UserModel user;
  final String? reason;

  const AuthRejected({required this.user, this.reason});

  @override
  List<Object?> get props => [user, reason];
}
