import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

/// Implementation of NotificationsRepository
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedNotifications> getNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getNotifications(page: page, limit: limit);
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String notificationId) {
    return _remoteDataSource.deleteNotification(notificationId);
  }

  @override
  Future<void> clearAllNotifications() {
    return _remoteDataSource.clearAllNotifications();
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }
}
