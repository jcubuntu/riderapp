import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/sos_alert.dart';

/// Remote data source for emergency API calls
class EmergencyRemoteDataSource {
  final ApiClient _apiClient;

  EmergencyRemoteDataSource(this._apiClient);

  /// Get list of emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await _apiClient.get(ApiEndpoints.emergencyContacts);

    if (response.data['success'] == true) {
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to fetch emergency contacts',
    );
  }

  /// Trigger SOS alert
  Future<SosAlert> triggerSos({
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.triggerSos,
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationAddress != null) 'locationAddress': locationAddress,
        if (notes != null) 'notes': notes,
      },
    );

    if (response.data['success'] == true) {
      return SosAlert.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: response.data['message'] ?? 'Failed to trigger SOS',
    );
  }

  /// Cancel SOS alert
  Future<void> cancelSos() async {
    final response = await _apiClient.delete(ApiEndpoints.triggerSos);

    if (response.data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: response.data['message'] ?? 'Failed to cancel SOS',
      );
    }
  }

  /// Get current SOS status
  Future<SosAlert?> getSosStatus() async {
    final response = await _apiClient.get(ApiEndpoints.sosStatus);

    if (response.data['success'] == true) {
      final data = response.data['data'];
      if (data != null && data is Map<String, dynamic>) {
        return SosAlert.fromJson(data);
      }
      return null;
    }

    return null;
  }
}
