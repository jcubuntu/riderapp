import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

/// Provider for NotificationsRepository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final apiClient = ApiClient();
  final dataSource = NotificationsRemoteDataSource(apiClient);
  return NotificationsRepositoryImpl(dataSource);
});

/// Provider for notifications state
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return NotificationsNotifier(repository);
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.getUnreadCount();
});

/// Notifier for notifications state
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsNotifier(this._repository) : super(const NotificationsInitial());

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationsNotifier] $message');
    }
  }

  /// Load notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh || state is NotificationsInitial || state is NotificationsError) {
      state = const NotificationsLoading();
    }

    try {
      final result = await _repository.getNotifications();

      state = NotificationsLoaded(
        notifications: result.notifications,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        unreadCount: result.unreadCount,
      );

      _log('Loaded ${result.notifications.length} notifications');
    } catch (e) {
      _log('Error loading notifications: $e');
      state = NotificationsError(e.toString());
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! NotificationsLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getNotifications(
        page: currentState.page + 1,
      );

      state = NotificationsLoaded(
        notifications: [...currentState.notifications, ...result.notifications],
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
        unreadCount: result.unreadCount,
      );

      _log('Loaded ${result.notifications.length} more notifications');
    } catch (e) {
      _log('Error loading more notifications: $e');
      state = currentState.copyWith(isLoadingMore: false);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    // Optimistically update the UI
    final updatedNotifications = currentState.notifications.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnreadCount =
        currentState.unreadCount > 0 ? currentState.unreadCount - 1 : 0;

    state = currentState.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    );

    try {
      await _repository.markAsRead(notificationId);
      _log('Marked notification $notificationId as read');
    } catch (e) {
      _log('Error marking notification as read: $e');
      // Revert on error
      state = currentState;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationsLoaded ||
        currentState.isMarkingAllRead ||
        !currentState.hasUnread) {
      return;
    }

    state = currentState.copyWith(isMarkingAllRead: true);

    try {
      await _repository.markAllAsRead();

      // Update all notifications to read
      final updatedNotifications = currentState.notifications.map((n) {
        if (!n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      state = currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
        isMarkingAllRead: false,
      );

      _log('Marked all notifications as read');
    } catch (e) {
      _log('Error marking all notifications as read: $e');
      state = currentState.copyWith(isMarkingAllRead: false);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    // Find the notification to check if it's unread
    final notification = currentState.notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => AppNotification(
        id: '',
        title: '',
        body: '',
        type: NotificationType.system,
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );

    state = currentState.copyWith(deletingId: notificationId);

    try {
      await _repository.deleteNotification(notificationId);

      // Remove from list
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != notificationId)
          .toList();

      // Adjust unread count if the deleted notification was unread
      final newUnreadCount = !notification.isRead && currentState.unreadCount > 0
          ? currentState.unreadCount - 1
          : currentState.unreadCount;

      state = currentState.copyWith(
        notifications: updatedNotifications,
        total: currentState.total - 1,
        unreadCount: newUnreadCount,
        clearDeletingId: true,
      );

      _log('Deleted notification $notificationId');
    } catch (e) {
      _log('Error deleting notification: $e');
      state = currentState.copyWith(clearDeletingId: true);
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final currentState = state;
    if (currentState is! NotificationsLoaded || currentState.isEmpty) {
      return;
    }

    try {
      await _repository.clearAllNotifications();

      state = const NotificationsLoaded(
        notifications: [],
        total: 0,
        page: 1,
        totalPages: 1,
        unreadCount: 0,
      );

      _log('Cleared all notifications');
    } catch (e) {
      _log('Error clearing notifications: $e');
      rethrow;
    }
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }
}
