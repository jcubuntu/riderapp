import '../entities/incident.dart';

/// Abstract repository interface for incidents
abstract class IIncidentsRepository {
  /// Get all incidents (for volunteer+ roles)
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
  });

  /// Get current user's incidents
  Future<PaginatedIncidents> getMyIncidents({
    int page = 1,
    int limit = 10,
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  });

  /// Get incident by ID
  Future<Incident> getIncidentById(String id, {bool includeDetails = true});

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
  });

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
  });

  /// Delete an incident
  Future<void> deleteIncident(String id);

  /// Update incident status (police+ roles)
  Future<Incident> updateIncidentStatus(
    String id, {
    required IncidentStatus status,
    String? notes,
  });

  /// Assign incident to an officer (police+ roles)
  Future<Incident> assignIncident(String id, {required String assigneeId});

  /// Get incident statistics
  Future<IncidentStats> getIncidentStats();

  /// Get attachments for an incident
  Future<List<IncidentAttachment>> getAttachments(String incidentId);

  /// Upload attachments to an incident
  Future<List<IncidentAttachment>> uploadAttachments(
    String incidentId, {
    required List<String> filePaths,
    String? description,
  });

  /// Delete an attachment
  Future<void> deleteAttachment(String incidentId, String attachmentId);
}
