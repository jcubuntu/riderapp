import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/announcement.dart';

/// Remote data source for announcements API calls
class AnnouncementsRemoteDataSource {
  final ApiClient _apiClient;

  AnnouncementsRemoteDataSource(this._apiClient);

  /// Get list of announcements
  Future<PaginatedAnnouncements> getAnnouncements({
    int page = 1,
    int limit = 10,
    AnnouncementPriority? priority,
    AnnouncementCategory? category,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (priority != null) {
      queryParams['priority'] = priority.name;
    }
    if (category != null) {
      queryParams['category'] = category.name;
    }

    final response = await _apiClient.get(
      ApiEndpoints.announcements,
      queryParameters: queryParams,
    );

    if (response.data['success'] == true) {
      return PaginatedAnnouncements.fromJson(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch announcements',
    );
  }

  /// Get announcement by ID
  Future<Announcement> getAnnouncementById(String id) async {
    final response = await _apiClient.get(
      ApiEndpoints.getAnnouncement(id),
    );

    if (response.data['success'] == true) {
      return Announcement.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch announcement',
    );
  }

  /// Mark announcement as read
  Future<void> markAsRead(String id) async {
    final response = await _apiClient.patch(
      ApiEndpoints.markAnnouncementRead(id),
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to mark as read',
      );
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      ApiEndpoints.unreadAnnouncementsCount,
    );

    if (response.data['success'] == true) {
      return response.data['data']['count'] as int? ?? 0;
    }

    return 0;
  }
}
