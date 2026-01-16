import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/affiliation_model.dart';

/// Repository for affiliations API calls
class AffiliationsRepository {
  final ApiClient _apiClient;

  AffiliationsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get all active affiliations (public)
  Future<List<AffiliationModel>> getAffiliations() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.affiliations);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final affiliationsJson = responseData['affiliations'] as List<dynamic>;

        return affiliationsJson
            .map((json) => AffiliationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw AffiliationsException(
          message: data['message'] as String? ?? 'Failed to load affiliations',
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Failed to load affiliations';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AffiliationsException(message: message);
    }
  }

  /// Get all affiliations including inactive (admin only)
  Future<List<AffiliationModel>> getAffiliationsAdmin() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.affiliationsAdmin);

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final affiliationsJson = responseData['affiliations'] as List<dynamic>;

        return affiliationsJson
            .map((json) => AffiliationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw AffiliationsException(
          message: data['message'] as String? ?? 'Failed to load affiliations',
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Failed to load affiliations';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AffiliationsException(message: message);
    }
  }

  /// Create a new affiliation (admin only)
  Future<AffiliationModel> createAffiliation({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.createAffiliation,
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final affiliationJson = responseData['affiliation'] as Map<String, dynamic>;

        return AffiliationModel.fromJson(affiliationJson);
      } else {
        throw AffiliationsException(
          message: data['message'] as String? ?? 'Failed to create affiliation',
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Failed to create affiliation';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AffiliationsException(message: message);
    }
  }

  /// Delete an affiliation (admin only)
  Future<void> deleteAffiliation(String affiliationId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteAffiliation(affiliationId),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw AffiliationsException(
          message: data['message'] as String? ?? 'Failed to delete affiliation',
        );
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String message = 'Failed to delete affiliation';

      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] as String? ?? message;
      }

      throw AffiliationsException(message: message);
    }
  }
}

/// Exception for affiliations operations
class AffiliationsException implements Exception {
  final String message;

  AffiliationsException({required this.message});

  @override
  String toString() => message;
}
