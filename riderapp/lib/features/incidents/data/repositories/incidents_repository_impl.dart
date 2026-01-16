import '../../domain/entities/incident.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../datasources/incidents_remote_datasource.dart';

/// Implementation of the incidents repository
class IncidentsRepositoryImpl implements IIncidentsRepository {
  final IncidentsRemoteDataSource _remoteDataSource;

  IncidentsRepositoryImpl({IncidentsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? IncidentsRemoteDataSource();

  @override
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
  }) {
    return _remoteDataSource.getIncidents(
      page: page,
      limit: limit,
      search: search,
      category: category,
      status: status,
      priority: priority,
      province: province,
      assignedTo: assignedTo,
      reportedBy: reportedBy,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<PaginatedIncidents> getMyIncidents({
    int page = 1,
    int limit = 10,
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) {
    return _remoteDataSource.getMyIncidents(
      page: page,
      limit: limit,
      search: search,
      category: category,
      status: status,
      priority: priority,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<Incident> getIncidentById(String id, {bool includeDetails = true}) {
    return _remoteDataSource.getIncidentById(id, includeDetails: includeDetails);
  }

  @override
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
  }) {
    return _remoteDataSource.createIncident(
      title: title,
      description: description,
      category: category,
      priority: priority,
      locationLat: locationLat,
      locationLng: locationLng,
      locationAddress: locationAddress,
      locationProvince: locationProvince,
      locationDistrict: locationDistrict,
      incidentDate: incidentDate,
      isAnonymous: isAnonymous,
    );
  }

  @override
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
  }) {
    return _remoteDataSource.updateIncident(
      id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      locationLat: locationLat,
      locationLng: locationLng,
      locationAddress: locationAddress,
      locationProvince: locationProvince,
      locationDistrict: locationDistrict,
      incidentDate: incidentDate,
      isAnonymous: isAnonymous,
    );
  }

  @override
  Future<void> deleteIncident(String id) {
    return _remoteDataSource.deleteIncident(id);
  }

  @override
  Future<Incident> updateIncidentStatus(
    String id, {
    required IncidentStatus status,
    String? notes,
  }) {
    return _remoteDataSource.updateIncidentStatus(id, status: status, notes: notes);
  }

  @override
  Future<Incident> assignIncident(String id, {required String assigneeId}) {
    return _remoteDataSource.assignIncident(id, assigneeId: assigneeId);
  }

  @override
  Future<IncidentStats> getIncidentStats() {
    return _remoteDataSource.getIncidentStats();
  }

  @override
  Future<List<IncidentAttachment>> getAttachments(String incidentId) {
    return _remoteDataSource.getAttachments(incidentId);
  }

  @override
  Future<List<IncidentAttachment>> uploadAttachments(
    String incidentId, {
    required List<String> filePaths,
    String? description,
  }) {
    return _remoteDataSource.uploadAttachments(
      incidentId,
      filePaths: filePaths,
      description: description,
    );
  }

  @override
  Future<void> deleteAttachment(String incidentId, String attachmentId) {
    return _remoteDataSource.deleteAttachment(incidentId, attachmentId);
  }
}
