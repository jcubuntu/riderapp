import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/user_location.dart';

/// Remote data source for locations API calls
class LocationsRemoteDataSource {
  final ApiClient _apiClient;

  /// API endpoint prefix for locations
  static const String _prefix = '/locations';

  LocationsRemoteDataSource(this._apiClient);

  /// Update user's current location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    final response = await _apiClient.post(
      '$_prefix/update',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (altitude != null) 'altitude': altitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'recordedAt': DateTime.now().toIso8601String(),
      },
    );

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to update location',
      );
    }
  }

  /// Get user's location history
  Future<List<UserLocation>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (limit != null) {
      queryParams['limit'] = limit;
    }

    final response = await _apiClient.get(
      '$_prefix/history',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => UserLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch location history',
    );
  }

  /// Get nearby users (volunteer+ only)
  Future<List<UserLocation>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    final queryParams = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
    if (radius != null) {
      queryParams['radius'] = radius;
    }

    final response = await _apiClient.get(
      '$_prefix/nearby',
      queryParameters: queryParams,
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => UserLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch nearby users',
    );
  }

  /// Get a specific user's location (volunteer+ only)
  Future<UserLocation?> getUserLocation(String userId) async {
    final response = await _apiClient.get('$_prefix/user/$userId');

    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return UserLocation.fromJson(data);
      }
      return null;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch user location',
    );
  }

  /// Start live location sharing
  Future<LocationSharingInfo> startSharing({
    int? durationMinutes,
  }) async {
    final response = await _apiClient.post(
      '$_prefix/share',
      data: {
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      },
    );

    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return LocationSharingInfo.fromJson(data);
      }
      return const LocationSharingInfo(isSharing: true);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to start location sharing',
    );
  }

  /// Stop live location sharing
  Future<void> stopSharing() async {
    final response = await _apiClient.delete('$_prefix/share');

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to stop location sharing',
      );
    }
  }

  /// Get current sharing status
  Future<LocationSharingInfo> getSharingStatus() async {
    final response = await _apiClient.get('$_prefix/share/status');

    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return LocationSharingInfo.fromJson(data);
      }
      return const LocationSharingInfo(isSharing: false);
    }

    return const LocationSharingInfo(isSharing: false);
  }

  /// Get a user's shared location
  Future<UserLocation?> getSharedLocation(String userId) async {
    final response = await _apiClient.get('$_prefix/share/$userId');

    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return UserLocation.fromJson(data);
      }
      return null;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch shared location',
    );
  }

  /// Get all active users on map (police+ only)
  Future<List<UserLocation>> getActiveUsers({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final queryParams = <String, dynamic>{};
    if (latitude != null) {
      queryParams['latitude'] = latitude;
    }
    if (longitude != null) {
      queryParams['longitude'] = longitude;
    }
    if (radius != null) {
      queryParams['radius'] = radius;
    }

    final response = await _apiClient.get(
      '$_prefix/active',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => UserLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch active users',
    );
  }
}
