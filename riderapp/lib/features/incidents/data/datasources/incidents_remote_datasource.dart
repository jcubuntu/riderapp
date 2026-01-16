import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/incident.dart';

/// Remote data source for incidents
class IncidentsRemoteDataSource {
  final ApiClient _apiClient;

  IncidentsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all incidents (paginated) - for volunteer+ roles
  Future<PaginatedIncidents> getIncidents({
    int page = 1,
    int limit = 10,
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? province,
    String? assignedTo,
    String? reportedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null) {
        queryParams['category'] = category.name;
      }
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (priority != null) {
        queryParams['priority'] = priority.name;
      }
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      if (assignedTo != null && assignedTo.isNotEmpty) {
        queryParams['assignedTo'] = assignedTo;
      }
      if (reportedBy != null && reportedBy.isNotEmpty) {
        queryParams['reportedBy'] = reportedBy;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String();
      }

      final response = await _apiClient.get(
        ApiEndpoints.incidents,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return PaginatedIncidents.fromJson(data);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to fetch incidents',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incidents');
    }
  }

  /// Get current user's incidents (paginated)
  Future<PaginatedIncidents> getMyIncidents({
    int page = 1,
    int limit = 10,
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null) {
        queryParams['category'] = category.name;
      }
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (priority != null) {
        queryParams['priority'] = priority.name;
      }

      final response = await _apiClient.get(
        '${ApiEndpoints.incidents}/my',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return PaginatedIncidents.fromJson(data);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to fetch your incidents',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch your incidents');
    }
  }

  /// Get incident by ID
  Future<Incident> getIncidentById(String id, {bool includeDetails = true}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getIncident(id),
        queryParameters: {'includeDetails': includeDetails.toString()},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final incidentData = data['data'] as Map<String, dynamic>;
        return Incident.fromJson(incidentData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to fetch incident',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch incident');
    }
  }

  /// Create a new incident
  Future<Incident> createIncident({
    required String title,
    required String description,
    IncidentCategory category = IncidentCategory.general,
    IncidentPriority priority = IncidentPriority.medium,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? locationProvince,
    String? locationDistrict,
    DateTime? incidentDate,
    bool isAnonymous = false,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'isAnonymous': isAnonymous,
      };

      if (locationLat != null) {
        requestData['locationLat'] = locationLat;
      }
      if (locationLng != null) {
        requestData['locationLng'] = locationLng;
      }
      if (locationAddress != null && locationAddress.isNotEmpty) {
        requestData['locationAddress'] = locationAddress;
      }
      if (locationProvince != null && locationProvince.isNotEmpty) {
        requestData['locationProvince'] = locationProvince;
      }
      if (locationDistrict != null && locationDistrict.isNotEmpty) {
        requestData['locationDistrict'] = locationDistrict;
      }
      if (incidentDate != null) {
        requestData['incidentDate'] = incidentDate.toIso8601String();
      }

      final response = await _apiClient.post(
        ApiEndpoints.createIncident,
        data: requestData,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final incidentData = data['data'] as Map<String, dynamic>;
        return Incident.fromJson(incidentData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to create incident',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create incident');
    }
  }

  /// Update an incident
  Future<Incident> updateIncident(
    String id, {
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentPriority? priority,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? locationProvince,
    String? locationDistrict,
    DateTime? incidentDate,
    bool? isAnonymous,
  }) async {
    try {
      final requestData = <String, dynamic>{};

      if (title != null) requestData['title'] = title;
      if (description != null) requestData['description'] = description;
      if (category != null) requestData['category'] = category.name;
      if (priority != null) requestData['priority'] = priority.name;
      if (locationLat != null) requestData['locationLat'] = locationLat;
      if (locationLng != null) requestData['locationLng'] = locationLng;
      if (locationAddress != null) requestData['locationAddress'] = locationAddress;
      if (locationProvince != null) requestData['locationProvince'] = locationProvince;
      if (locationDistrict != null) requestData['locationDistrict'] = locationDistrict;
      if (incidentDate != null) {
        requestData['incidentDate'] = incidentDate.toIso8601String();
      }
      if (isAnonymous != null) requestData['isAnonymous'] = isAnonymous;

      final response = await _apiClient.put(
        ApiEndpoints.updateIncident(id),
        data: requestData,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final incidentData = data['data'] as Map<String, dynamic>;
        return Incident.fromJson(incidentData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to update incident',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update incident');
    }
  }

  /// Delete an incident
  Future<void> deleteIncident(String id) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteIncident(id),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to delete incident',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete incident');
    }
  }

  /// Update incident status (police+ roles)
  Future<Incident> updateIncidentStatus(
    String id, {
    required IncidentStatus status,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.updateIncidentStatus(id),
        data: {
          'status': status.name,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final incidentData = data['data'] as Map<String, dynamic>;
        return Incident.fromJson(incidentData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to update status',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update status');
    }
  }

  /// Assign incident to an officer (police+ roles)
  Future<Incident> assignIncident(String id, {required String assigneeId}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.assignIncident(id),
        data: {'assigneeId': assigneeId},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final incidentData = data['data'] as Map<String, dynamic>;
        return Incident.fromJson(incidentData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to assign incident',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to assign incident');
    }
  }

  /// Get incident statistics (volunteer+ roles)
  Future<IncidentStats> getIncidentStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.incidentStats);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final statsData = data['data'] as Map<String, dynamic>;
        return IncidentStats.fromJson(statsData);
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to fetch statistics',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch statistics');
    }
  }

  /// Get attachments for an incident
  Future<List<IncidentAttachment>> getAttachments(String incidentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.getIncident(incidentId)}/attachments',
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final attachmentsData = data['data'] as List<dynamic>? ?? [];
        return attachmentsData
            .map((e) => IncidentAttachment.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to fetch attachments',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to fetch attachments');
    }
  }

  /// Upload attachments to an incident
  Future<List<IncidentAttachment>> uploadAttachments(
    String incidentId, {
    required List<String> filePaths,
    String? description,
  }) async {
    try {
      final formData = FormData();

      for (final path in filePaths) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(path),
          ),
        );
      }

      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }

      final response = await _apiClient.uploadFile(
        '${ApiEndpoints.getIncident(incidentId)}/attachments',
        formData: formData,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final uploaded = responseData['uploaded'] as List<dynamic>? ?? [];
        return uploaded
            .map((e) => IncidentAttachment.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to upload attachments',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to upload attachments');
    }
  }

  /// Delete an attachment
  Future<void> deleteAttachment(String incidentId, String attachmentId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiEndpoints.getIncident(incidentId)}/attachments/$attachmentId',
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw IncidentsException(
          message: data['message'] as String? ?? 'Failed to delete attachment',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete attachment');
    }
  }

  /// Handle Dio errors
  IncidentsException _handleDioError(DioException e, String defaultMessage) {
    final errorData = e.response?.data;
    String message = defaultMessage;

    if (errorData is Map<String, dynamic>) {
      message = errorData['message'] as String? ?? message;
    }

    return IncidentsException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}

/// Exception for incidents operations
class IncidentsException implements Exception {
  final String message;
  final int? statusCode;

  IncidentsException({
    required this.message,
    this.statusCode,
  });

  bool get isNotFound => statusCode == 404;
  bool get isForbidden => statusCode == 403;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
