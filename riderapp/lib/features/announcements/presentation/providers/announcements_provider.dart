import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/announcements_remote_datasource.dart';
import '../../data/repositories/announcements_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcements_repository.dart';
import 'announcements_state.dart';

/// Provider for AnnouncementsRepository
final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  final apiClient = ApiClient();
  final dataSource = AnnouncementsRemoteDataSource(apiClient);
  return AnnouncementsRepositoryImpl(dataSource);
});

/// Provider for announcements list state
final announcementsProvider =
    StateNotifierProvider<AnnouncementsNotifier, AnnouncementsState>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return AnnouncementsNotifier(repository);
});

/// Provider for announcement detail state
final announcementDetailProvider = StateNotifierProvider.family<
    AnnouncementDetailNotifier, AnnouncementDetailState, String>((ref, id) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return AnnouncementDetailNotifier(repository, id);
});

/// Provider for unread count
final unreadAnnouncementsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getUnreadCount();
});

/// Notifier for announcements list
class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final AnnouncementsRepository _repository;
  AnnouncementPriority? _priorityFilter;
  AnnouncementCategory? _categoryFilter;

  AnnouncementsNotifier(this._repository) : super(const AnnouncementsInitial());

  /// Load announcements
  Future<void> loadAnnouncements({bool refresh = false}) async {
    if (refresh || state is AnnouncementsInitial || state is AnnouncementsError) {
      state = const AnnouncementsLoading();
    }

    try {
      final result = await _repository.getAnnouncements(
        page: 1,
        priority: _priorityFilter,
        category: _categoryFilter,
      );

      state = AnnouncementsLoaded(
        announcements: result.announcements,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = AnnouncementsError(e.toString());
    }
  }

  /// Load more announcements
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AnnouncementsLoaded || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getAnnouncements(
        page: currentState.page + 1,
        priority: _priorityFilter,
        category: _categoryFilter,
      );

      state = AnnouncementsLoaded(
        announcements: [...currentState.announcements, ...result.announcements],
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  /// Set priority filter
  void setPriorityFilter(AnnouncementPriority? priority) {
    _priorityFilter = priority;
    loadAnnouncements(refresh: true);
  }

  /// Set category filter
  void setCategoryFilter(AnnouncementCategory? category) {
    _categoryFilter = category;
    loadAnnouncements(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _priorityFilter = null;
    _categoryFilter = null;
    loadAnnouncements(refresh: true);
  }

  /// Mark announcement as read locally
  void markAsReadLocally(String id) {
    final currentState = state;
    if (currentState is AnnouncementsLoaded) {
      final updatedList = currentState.announcements.map((a) {
        if (a.id == id) {
          return a.copyWith(isRead: true);
        }
        return a;
      }).toList();

      state = currentState.copyWith(announcements: updatedList);
    }
  }
}

/// Notifier for announcement detail
class AnnouncementDetailNotifier extends StateNotifier<AnnouncementDetailState> {
  final AnnouncementsRepository _repository;
  final String _id;

  AnnouncementDetailNotifier(this._repository, this._id)
      : super(const AnnouncementDetailInitial()) {
    loadAnnouncement();
  }

  /// Load announcement detail
  Future<void> loadAnnouncement() async {
    state = const AnnouncementDetailLoading();

    try {
      final announcement = await _repository.getAnnouncementById(_id);
      state = AnnouncementDetailLoaded(announcement);

      // Mark as read
      if (!announcement.isRead) {
        await _repository.markAsRead(_id);
      }
    } catch (e) {
      state = AnnouncementDetailError(e.toString());
    }
  }
}
