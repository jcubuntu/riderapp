import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/dashboard_stats_model.dart';

/// Repository for statistics API calls
class StatsRepository {
  final ApiClient _apiClient;

  StatsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const String _statsPrefix = '/stats';

  /// Get dashboard overview statistics (volunteer+)
  Future<DashboardStats> getDashboard({int recentLimit = 5}) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/dashboard',
        queryParameters: {'recentLimit': recentLimit},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        return DashboardStats.fromJson(responseData);
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch dashboard',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch dashboard');
    }
  }

  /// Get incident summary statistics (volunteer+)
  Future<IncidentSummary> getIncidentSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/incidents/summary',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        return IncidentSummary.fromJson(responseData);
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch incident summary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incident summary');
    }
  }

  /// Get incidents by type (volunteer+)
  Future<List<CategoryStats>> getIncidentsByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/incidents/by-type',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final byType = responseData['byType'] as List<dynamic>? ?? [];
        return byType
            .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch incidents by type',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incidents by type');
    }
  }

  /// Get incidents by status (volunteer+)
  Future<List<CategoryStats>> getIncidentsByStatus({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/incidents/by-status',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final byStatus = responseData['byStatus'] as List<dynamic>? ?? [];
        return byStatus
            .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch incidents by status',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incidents by status');
    }
  }

  /// Get incidents by priority (volunteer+)
  Future<List<CategoryStats>> getIncidentsByPriority({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/incidents/by-priority',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final byPriority = responseData['byPriority'] as List<dynamic>? ?? [];
        return byPriority
            .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch incidents by priority',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incidents by priority');
    }
  }

  /// Get incident trend over time (volunteer+)
  Future<List<TrendDataPoint>> getIncidentTrend({
    DateTime? startDate,
    DateTime? endDate,
    String interval = 'daily',
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/incidents/trend',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          'interval': interval,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final trend = responseData['trend'] as List<dynamic>? ?? [];
        return trend
            .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch incident trend',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incident trend');
    }
  }

  /// Get user summary statistics (admin+)
  Future<UserSummary> getUserSummary() async {
    try {
      final response = await _apiClient.get('$_statsPrefix/users/summary');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        return UserSummary.fromJson(responseData);
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch user summary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch user summary');
    }
  }

  /// Get users by role (admin+)
  Future<List<CategoryStats>> getUsersByRole({String? status}) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/users/by-role',
        queryParameters: {
          if (status != null) 'status': status,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final byRole = responseData['byRole'] as List<dynamic>? ?? [];
        return byRole
            .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch users by role',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch users by role');
    }
  }

  /// Get users by status (admin+)
  Future<List<CategoryStats>> getUsersByStatus() async {
    try {
      final response = await _apiClient.get('$_statsPrefix/users/by-status');

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final byStatus = responseData['byStatus'] as List<dynamic>? ?? [];
        return byStatus
            .map((e) => CategoryStats.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch users by status',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch users by status');
    }
  }

  /// Get user registration trend (admin+)
  Future<List<TrendDataPoint>> getUserTrend({
    DateTime? startDate,
    DateTime? endDate,
    String interval = 'daily',
  }) async {
    try {
      final response = await _apiClient.get(
        '$_statsPrefix/users/trend',
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          'interval': interval,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final trend = responseData['trend'] as List<dynamic>? ?? [];
        return trend
            .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw StatsException(
          message: data['message'] as String? ?? 'Failed to fetch user trend',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch user trend');
    }
  }

  /// Handle Dio errors
  StatsException _handleDioError(DioException e, String defaultMessage) {
    final errorData = e.response?.data;
    String message = defaultMessage;

    if (errorData is Map<String, dynamic>) {
      message = errorData['message'] as String? ?? message;
    }

    return StatsException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}

/// Stats exception
class StatsException implements Exception {
  final String message;
  final int? statusCode;

  StatsException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
