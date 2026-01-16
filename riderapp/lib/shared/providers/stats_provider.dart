import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats_model.dart';
import '../repositories/stats_repository.dart';

/// Stats repository provider
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

/// Dashboard stats state
sealed class DashboardStatsState {
  const DashboardStatsState();
}

class DashboardStatsInitial extends DashboardStatsState {
  const DashboardStatsInitial();
}

class DashboardStatsLoading extends DashboardStatsState {
  const DashboardStatsLoading();
}

class DashboardStatsLoaded extends DashboardStatsState {
  final DashboardStats stats;
  const DashboardStatsLoaded(this.stats);
}

class DashboardStatsError extends DashboardStatsState {
  final String message;
  const DashboardStatsError(this.message);
}

/// Dashboard stats notifier
class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final StatsRepository _repository;

  DashboardStatsNotifier(this._repository) : super(const DashboardStatsInitial());

  /// Fetch dashboard stats
  Future<void> fetchDashboard({int recentLimit = 5}) async {
    state = const DashboardStatsLoading();
    try {
      final stats = await _repository.getDashboard(recentLimit: recentLimit);
      state = DashboardStatsLoaded(stats);
    } on StatsException catch (e) {
      state = DashboardStatsError(e.message);
    } catch (e) {
      state = DashboardStatsError('Failed to load dashboard stats');
    }
  }

  /// Refresh dashboard stats
  Future<void> refresh() async {
    await fetchDashboard();
  }
}

/// Dashboard stats provider
final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return DashboardStatsNotifier(repository);
});

/// User summary state
sealed class UserSummaryState {
  const UserSummaryState();
}

class UserSummaryInitial extends UserSummaryState {
  const UserSummaryInitial();
}

class UserSummaryLoading extends UserSummaryState {
  const UserSummaryLoading();
}

class UserSummaryLoaded extends UserSummaryState {
  final UserSummary summary;
  const UserSummaryLoaded(this.summary);
}

class UserSummaryError extends UserSummaryState {
  final String message;
  const UserSummaryError(this.message);
}

/// User summary notifier
class UserSummaryNotifier extends StateNotifier<UserSummaryState> {
  final StatsRepository _repository;

  UserSummaryNotifier(this._repository) : super(const UserSummaryInitial());

  /// Fetch user summary
  Future<void> fetchUserSummary() async {
    state = const UserSummaryLoading();
    try {
      final summary = await _repository.getUserSummary();
      state = UserSummaryLoaded(summary);
    } on StatsException catch (e) {
      state = UserSummaryError(e.message);
    } catch (e) {
      state = UserSummaryError('Failed to load user summary');
    }
  }

  /// Refresh user summary
  Future<void> refresh() async {
    await fetchUserSummary();
  }
}

/// User summary provider
final userSummaryProvider =
    StateNotifierProvider<UserSummaryNotifier, UserSummaryState>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return UserSummaryNotifier(repository);
});

/// Incident summary state
sealed class IncidentSummaryState {
  const IncidentSummaryState();
}

class IncidentSummaryInitial extends IncidentSummaryState {
  const IncidentSummaryInitial();
}

class IncidentSummaryLoading extends IncidentSummaryState {
  const IncidentSummaryLoading();
}

class IncidentSummaryLoaded extends IncidentSummaryState {
  final IncidentSummary summary;
  const IncidentSummaryLoaded(this.summary);
}

class IncidentSummaryError extends IncidentSummaryState {
  final String message;
  const IncidentSummaryError(this.message);
}

/// Incident summary notifier
class IncidentSummaryNotifier extends StateNotifier<IncidentSummaryState> {
  final StatsRepository _repository;

  IncidentSummaryNotifier(this._repository) : super(const IncidentSummaryInitial());

  /// Fetch incident summary
  Future<void> fetchIncidentSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const IncidentSummaryLoading();
    try {
      final summary = await _repository.getIncidentSummary(
        startDate: startDate,
        endDate: endDate,
      );
      state = IncidentSummaryLoaded(summary);
    } on StatsException catch (e) {
      state = IncidentSummaryError(e.message);
    } catch (e) {
      state = IncidentSummaryError('Failed to load incident summary');
    }
  }

  /// Refresh incident summary
  Future<void> refresh() async {
    await fetchIncidentSummary();
  }
}

/// Incident summary provider
final incidentSummaryProvider =
    StateNotifierProvider<IncidentSummaryNotifier, IncidentSummaryState>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return IncidentSummaryNotifier(repository);
});

/// Simple providers for quick stats access

/// Today's incident count provider
final todayIncidentCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final stats = await repository.getDashboard();
    return stats.incidents.today;
  } catch (e) {
    return 0;
  }
});

/// Pending user count provider
final pendingUserCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final summary = await repository.getUserSummary();
    return summary.pending;
  } catch (e) {
    return 0;
  }
});

/// Total user count provider
final totalUserCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final summary = await repository.getUserSummary();
    return summary.total;
  } catch (e) {
    return 0;
  }
});

/// Total incident count provider
final totalIncidentCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final stats = await repository.getDashboard();
    return stats.incidents.total;
  } catch (e) {
    return 0;
  }
});

/// Resolved incident count provider
final resolvedIncidentCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final stats = await repository.getDashboard();
    return stats.incidents.resolved;
  } catch (e) {
    return 0;
  }
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  try {
    final stats = await repository.getDashboard();
    return stats.unreadNotifications;
  } catch (e) {
    return 0;
  }
});
