import '../entities/user_location.dart';

/// Abstract repository interface for locations features
abstract class LocationsRepository {
  /// Update user's current location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  });

  /// Get user's location history
  Future<List<UserLocation>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get nearby users (volunteer+ only)
  Future<List<UserLocation>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  });

  /// Get a specific user's location (volunteer+ only)
  Future<UserLocation?> getUserLocation(String userId);

  /// Start live location sharing
  Future<LocationSharingInfo> startSharing({
    int? durationMinutes,
  });

  /// Stop live location sharing
  Future<void> stopSharing();

  /// Get current sharing status
  Future<LocationSharingInfo> getSharingStatus();

  /// Get a user's shared location (by share link or user id)
  Future<UserLocation?> getSharedLocation(String userId);

  /// Get all active users on map (police+ only)
  Future<List<UserLocation>> getActiveUsers({
    double? latitude,
    double? longitude,
    double? radius,
  });
}
