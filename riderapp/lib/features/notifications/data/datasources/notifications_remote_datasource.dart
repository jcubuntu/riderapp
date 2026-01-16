import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';

/// Remote data source for notifications API calls
class NotificationsRemoteDataSource {
  final ApiClient _apiClient;

  NotificationsRemoteDataSource(this._apiClient);

  /// Get list of notifications
  Future<PaginatedNotifications> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.data['success'] == true) {
      return PaginatedNotifications.fromJson(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch notifications',
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final response = await _apiClient.patch(
      ApiEndpoints.markNotificationRead(notificationId),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to mark notification as read',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final response = await _apiClient.patch(
      ApiEndpoints.markAllNotificationsRead,
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to mark all notifications as read',
      );
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.deleteNotification(notificationId),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to delete notification',
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final response = await _apiClient.delete(
      ApiEndpoints.clearAllNotifications,
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to clear notifications',
      );
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': 1, 'limit': 1},
    );

    if (response.data['success'] == true) {
      return response.data['unreadCount'] as int? ?? 0;
    }

    return 0;
  }
}
