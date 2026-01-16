import '../../domain/entities/user_location.dart';
import '../../domain/repositories/locations_repository.dart';
import '../datasources/locations_remote_datasource.dart';

/// Implementation of LocationsRepository
class LocationsRepositoryImpl implements LocationsRepository {
  final LocationsRemoteDataSource _remoteDataSource;

  LocationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) {
    return _remoteDataSource.updateLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
    );
  }

  @override
  Future<List<UserLocation>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    return _remoteDataSource.getLocationHistory(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<List<UserLocation>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    return _remoteDataSource.getNearbyUsers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  @override
  Future<UserLocation?> getUserLocation(String userId) {
    return _remoteDataSource.getUserLocation(userId);
  }

  @override
  Future<LocationSharingInfo> startSharing({
    int? durationMinutes,
  }) {
    return _remoteDataSource.startSharing(
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<void> stopSharing() {
    return _remoteDataSource.stopSharing();
  }

  @override
  Future<LocationSharingInfo> getSharingStatus() {
    return _remoteDataSource.getSharingStatus();
  }

  @override
  Future<UserLocation?> getSharedLocation(String userId) {
    return _remoteDataSource.getSharedLocation(userId);
  }

  @override
  Future<List<UserLocation>> getActiveUsers({
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return _remoteDataSource.getActiveUsers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}
