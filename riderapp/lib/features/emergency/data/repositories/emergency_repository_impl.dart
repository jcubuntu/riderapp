import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_datasource.dart';

/// Implementation of EmergencyRepository
class EmergencyRepositoryImpl implements EmergencyRepository {
  final EmergencyRemoteDataSource _remoteDataSource;

  EmergencyRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() {
    return _remoteDataSource.getEmergencyContacts();
  }

  @override
  Future<SosAlert> triggerSos({
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? notes,
  }) {
    return _remoteDataSource.triggerSos(
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      notes: notes,
    );
  }

  @override
  Future<void> cancelSos() {
    return _remoteDataSource.cancelSos();
  }

  @override
  Future<SosAlert?> getSosStatus() {
    return _remoteDataSource.getSosStatus();
  }
}
