import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Current user provider - derived from auth state
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  if (authState is AuthPendingApproval) {
    return authState.user;
  }
  return null;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Is pending approval provider
final isPendingApprovalProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthPendingApproval;
});

/// User role provider
final userRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});

/// Auth notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorage _secureStorage = SecureStorage();

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Check initial auth status
  Future<void> _checkAuthStatus() async {
    try {
      // Initialize storage
      await _secureStorage.init();

      // Check for stored tokens
      final hasTokens = await _repository.hasStoredTokens();

      if (!hasTokens) {
        state = const AuthUnauthenticated();
        return;
      }

      // Try to refresh tokens and get user
      try {
        final result = await _repository.refreshTokens();
        if (result.user != null) {
          if (result.user!.isApproved) {
            state = AuthAuthenticated(
              user: result.user!,
              accessToken: result.accessToken ?? '',
            );
          } else if (result.user!.isPending) {
            state = AuthPendingApproval(user: result.user!);
          } else if (result.user!.status == UserStatus.rejected) {
            state = AuthRejected(user: result.user!);
          } else {
            state = const AuthUnauthenticated();
          }
        } else {
          // Tokens refreshed but no user - try to get user
          final user = await _repository.getCurrentUser();
          if (user.isApproved) {
            state = AuthAuthenticated(
              user: user,
              accessToken: result.accessToken ?? '',
            );
          } else if (user.isPending) {
            state = AuthPendingApproval(user: user);
          } else if (user.status == UserStatus.rejected) {
            state = AuthRejected(user: user);
          } else {
            state = const AuthUnauthenticated();
          }
        }
      } on AuthException catch (_) {
        // Token refresh failed - check stored user ID for pending status
        final userId = await _repository.getStoredUserId();
        if (userId != null) {
          try {
            final status = await _repository.checkApprovalStatus(userId);
            if (status.user.isApproved) {
              // User was approved - need to login again
              state = const AuthUnauthenticated();
            } else if (status.user.isPending) {
              state = AuthPendingApproval(user: status.user);
            } else if (status.user.status == UserStatus.rejected) {
              state = AuthRejected(user: status.user);
            } else {
              state = const AuthUnauthenticated();
            }
          } catch (_) {
            state = const AuthUnauthenticated();
          }
        } else {
          state = const AuthUnauthenticated();
        }
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Initialize API client (call from main.dart)
  static Future<void> initializeApi() async {
    final secureStorage = SecureStorage();
    await secureStorage.init();
    await ApiClient().init();
  }

  /// Login with phone and password
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      final result = await _repository.login(
        phone: phone,
        password: password,
      );

      if (result.user != null) {
        if (result.user!.isApproved) {
          state = AuthAuthenticated(
            user: result.user!,
            accessToken: result.accessToken ?? '',
          );
        } else if (result.user!.isPending) {
          state = AuthPendingApproval(user: result.user!);
        } else if (result.user!.status == UserStatus.rejected) {
          state = AuthRejected(user: result.user!);
        } else {
          state = const AuthError('Account is not active');
        }
      } else {
        state = const AuthError('Login failed');
      }
    } on AuthException catch (e) {
      if (e.isPending) {
        // Special case: user tried to login but is still pending
        final userId = await _repository.getStoredUserId();
        if (userId != null) {
          try {
            final status = await _repository.checkApprovalStatus(userId);
            state = AuthPendingApproval(user: status.user);
            return;
          } catch (_) {}
        }
        state = AuthError(e.message);
      } else if (e.isRejected) {
        state = AuthError('Your registration was rejected');
      } else if (e.isSuspended) {
        state = AuthError('Your account has been suspended');
      } else {
        state = AuthError(e.message);
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Register new user
  Future<void> register({
    required String password,
    required String fullName,
    required String phone,
    required String idCardNumber,
    required String affiliation,
    required String address,
  }) async {
    state = const AuthLoading();

    try {
      final result = await _repository.register(
        password: password,
        fullName: fullName,
        phone: phone,
        idCardNumber: idCardNumber,
        affiliation: affiliation,
        address: address,
      );

      if (result.user != null) {
        if (result.requiresApproval || result.user!.isPending) {
          state = AuthPendingApproval(user: result.user!);
        } else if (result.user!.isApproved) {
          state = AuthAuthenticated(
            user: result.user!,
            accessToken: result.accessToken ?? '',
          );
        } else {
          state = AuthPendingApproval(user: result.user!);
        }
      } else {
        state = const AuthError('Registration failed');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Check approval status
  Future<void> checkApprovalStatus() async {
    if (state is! AuthPendingApproval) return;

    try {
      final userId = await _repository.getStoredUserId();
      if (userId == null) return;

      final status = await _repository.checkApprovalStatus(userId);

      if (status.user.isApproved) {
        // User has been approved! They need to login again to get tokens
        state = const AuthUnauthenticated();
      } else if (status.user.status == UserStatus.rejected) {
        state = AuthRejected(user: status.user);
      } else {
        // Still pending - update user data
        state = AuthPendingApproval(user: status.user);
      }
    } catch (e) {
      // Ignore errors during status check - keep current state
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AuthLoading();

    try {
      await _repository.logout();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// Update user after profile edit
  void updateUser(UserModel user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(
        user: user,
        accessToken: (state as AuthAuthenticated).accessToken,
      );
    }
  }

  /// Clear error and go back to unauthenticated
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
