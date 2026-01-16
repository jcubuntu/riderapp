import 'package:equatable/equatable.dart';

import '../../domain/entities/user_location.dart';

/// Base state for location sharing
sealed class LocationSharingState extends Equatable {
  const LocationSharingState();

  @override
  List<Object?> get props => [];
}

class LocationSharingInitial extends LocationSharingState {
  const LocationSharingInitial();
}

class LocationSharingLoading extends LocationSharingState {
  const LocationSharingLoading();
}

class LocationSharingActive extends LocationSharingState {
  final LocationSharingInfo sharingInfo;
  final UserLocation? currentLocation;
  final DateTime? lastUpdated;

  const LocationSharingActive({
    required this.sharingInfo,
    this.currentLocation,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [sharingInfo, currentLocation, lastUpdated];
}

class LocationSharingInactive extends LocationSharingState {
  final UserLocation? lastKnownLocation;

  const LocationSharingInactive({this.lastKnownLocation});

  @override
  List<Object?> get props => [lastKnownLocation];
}

class LocationSharingStarting extends LocationSharingState {
  const LocationSharingStarting();
}

class LocationSharingStopping extends LocationSharingState {
  const LocationSharingStopping();
}

class LocationSharingError extends LocationSharingState {
  final String message;

  const LocationSharingError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Base state for nearby users
sealed class NearbyUsersState extends Equatable {
  const NearbyUsersState();

  @override
  List<Object?> get props => [];
}

class NearbyUsersInitial extends NearbyUsersState {
  const NearbyUsersInitial();
}

class NearbyUsersLoading extends NearbyUsersState {
  const NearbyUsersLoading();
}

class NearbyUsersLoaded extends NearbyUsersState {
  final List<UserLocation> users;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radius;
  final DateTime loadedAt;

  const NearbyUsersLoaded({
    required this.users,
    this.centerLatitude,
    this.centerLongitude,
    this.radius,
    required this.loadedAt,
  });

  /// Get users filtered by role
  List<UserLocation> getUsersByRole(String role) {
    return users.where((u) => u.userRole?.toLowerCase() == role.toLowerCase()).toList();
  }

  /// Get count by role
  Map<String, int> get countByRole {
    final counts = <String, int>{};
    for (final user in users) {
      final role = user.userRole ?? 'unknown';
      counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }

  @override
  List<Object?> get props => [users, centerLatitude, centerLongitude, radius, loadedAt];
}

class NearbyUsersError extends NearbyUsersState {
  final String message;

  const NearbyUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Base state for location history
sealed class LocationHistoryState extends Equatable {
  const LocationHistoryState();

  @override
  List<Object?> get props => [];
}

class LocationHistoryInitial extends LocationHistoryState {
  const LocationHistoryInitial();
}

class LocationHistoryLoading extends LocationHistoryState {
  const LocationHistoryLoading();
}

class LocationHistoryLoaded extends LocationHistoryState {
  final List<UserLocation> locations;
  final DateTime? startDate;
  final DateTime? endDate;

  const LocationHistoryLoaded({
    required this.locations,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [locations, startDate, endDate];
}

class LocationHistoryError extends LocationHistoryState {
  final String message;

  const LocationHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State for current device location
sealed class DeviceLocationState extends Equatable {
  const DeviceLocationState();

  @override
  List<Object?> get props => [];
}

class DeviceLocationInitial extends DeviceLocationState {
  const DeviceLocationInitial();
}

class DeviceLocationLoading extends DeviceLocationState {
  const DeviceLocationLoading();
}

class DeviceLocationLoaded extends DeviceLocationState {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  const DeviceLocationLoaded({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, altitude, speed, heading, timestamp];
}

class DeviceLocationDenied extends DeviceLocationState {
  final bool isPermanentlyDenied;

  const DeviceLocationDenied({this.isPermanentlyDenied = false});

  @override
  List<Object?> get props => [isPermanentlyDenied];
}

class DeviceLocationError extends DeviceLocationState {
  final String message;

  const DeviceLocationError(this.message);

  @override
  List<Object?> get props => [message];
}
