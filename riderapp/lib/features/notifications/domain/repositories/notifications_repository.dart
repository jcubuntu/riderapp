import '../entities/app_notification.dart';

/// Repository interface for notifications
abstract class NotificationsRepository {
  /// Get paginated list of notifications
  Future<PaginatedNotifications> getNotifications({
    int page = 1,
    int limit = 20,
  });

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Clear all notifications
  Future<void> clearAllNotifications();

  /// Get unread notifications count
  Future<int> getUnreadCount();
}
