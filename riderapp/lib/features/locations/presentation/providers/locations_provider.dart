import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/socket/socket_events.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/datasources/locations_remote_datasource.dart';
import '../../data/repositories/locations_repository_impl.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/locations_repository.dart';
import 'locations_state.dart';

/// Provider for LocationsRepository
final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  final apiClient = ApiClient();
  final dataSource = LocationsRemoteDataSource(apiClient);
  return LocationsRepositoryImpl(dataSource);
});

/// Provider for device location state
final deviceLocationProvider =
    StateNotifierProvider<DeviceLocationNotifier, DeviceLocationState>((ref) {
  return DeviceLocationNotifier();
});

/// Provider for location sharing state
final locationSharingProvider =
    StateNotifierProvider<LocationSharingNotifier, LocationSharingState>((ref) {
  final repository = ref.watch(locationsRepositoryProvider);
  final deviceLocationNotifier = ref.read(deviceLocationProvider.notifier);
  final socketService = ref.watch(socketServiceProvider);
  return LocationSharingNotifier(repository, deviceLocationNotifier, socketService);
});

/// Provider for nearby users state
final nearbyUsersProvider =
    StateNotifierProvider<NearbyUsersNotifier, NearbyUsersState>((ref) {
  final repository = ref.watch(locationsRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return NearbyUsersNotifier(repository, socketService);
});

/// Provider for location history state
final locationHistoryProvider =
    StateNotifierProvider<LocationHistoryNotifier, LocationHistoryState>((ref) {
  final repository = ref.watch(locationsRepositoryProvider);
  return LocationHistoryNotifier(repository);
});

/// Notifier for device location
class DeviceLocationNotifier extends StateNotifier<DeviceLocationState> {
  StreamSubscription<Position>? _positionSubscription;

  DeviceLocationNotifier() : super(const DeviceLocationInitial());

  /// Get current location once
  Future<void> getCurrentLocation() async {
    state = const DeviceLocationLoading();

    try {
      final permission = await _checkAndRequestPermission();
      if (permission == LocationPermission.denied) {
        state = const DeviceLocationDenied();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        state = const DeviceLocationDenied(isPermanentlyDenied: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      state = DeviceLocationLoaded(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );
    } catch (e) {
      state = DeviceLocationError(e.toString());
    }
  }

  /// Start listening to location updates
  Future<void> startLocationUpdates({
    int distanceFilter = 10,
  }) async {
    await stopLocationUpdates();

    try {
      final permission = await _checkAndRequestPermission();
      if (permission == LocationPermission.denied) {
        state = const DeviceLocationDenied();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        state = const DeviceLocationDenied(isPermanentlyDenied: true);
        return;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        ),
      ).listen(
        (position) {
          state = DeviceLocationLoaded(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
            speed: position.speed,
            heading: position.heading,
            timestamp: position.timestamp,
          );
        },
        onError: (error) {
          state = DeviceLocationError(error.toString());
        },
      );
    } catch (e) {
      state = DeviceLocationError(e.toString());
    }
  }

  /// Stop listening to location updates
  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Check and request location permission
  Future<LocationPermission> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}

/// Notifier for location sharing
class LocationSharingNotifier extends StateNotifier<LocationSharingState> {
  final LocationsRepository _repository;
  final DeviceLocationNotifier _deviceLocationNotifier;
  final SocketService _socketService;
  Timer? _updateTimer;
  bool _useSocketUpdates = true;

  LocationSharingNotifier(
    this._repository,
    this._deviceLocationNotifier,
    this._socketService,
  ) : super(const LocationSharingInitial()) {
    checkStatus();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocationSharingNotifier] $message');
    }
  }

  /// Check current sharing status
  Future<void> checkStatus() async {
    state = const LocationSharingLoading();

    try {
      final sharingInfo = await _repository.getSharingStatus();
      if (sharingInfo.isSharing) {
        state = LocationSharingActive(sharingInfo: sharingInfo);
        _startPeriodicUpdates();
      } else {
        state = const LocationSharingInactive();
      }
    } catch (e) {
      state = const LocationSharingInactive();
    }
  }

  /// Start location sharing
  Future<void> startSharing({int? durationMinutes}) async {
    state = const LocationSharingStarting();

    try {
      // Get current location first
      await _deviceLocationNotifier.getCurrentLocation();

      final sharingInfo = await _repository.startSharing(
        durationMinutes: durationMinutes,
      );

      state = LocationSharingActive(
        sharingInfo: sharingInfo,
        lastUpdated: DateTime.now(),
      );

      // Start periodic location updates
      _startPeriodicUpdates();
    } catch (e) {
      state = LocationSharingError(e.toString());
    }
  }

  /// Stop location sharing
  Future<void> stopSharing() async {
    state = const LocationSharingStopping();

    try {
      await _repository.stopSharing();
      _stopPeriodicUpdates();
      state = const LocationSharingInactive();
    } catch (e) {
      state = LocationSharingError(e.toString());
    }
  }

  /// Start periodic location updates
  void _startPeriodicUpdates() {
    _stopPeriodicUpdates();

    // Update location every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLocation();
    });

    // Do an immediate update
    _updateLocation();
  }

  /// Stop periodic location updates
  void _stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Update location to server
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Send location update via socket for real-time delivery
      if (_useSocketUpdates && _socketService.isAuthenticated) {
        _socketService.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
        );
        _log('Location sent via socket');
      }

      // Also persist via API
      await _repository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
      );

      final currentState = state;
      if (currentState is LocationSharingActive) {
        state = LocationSharingActive(
          sharingInfo: currentState.sharingInfo,
          currentLocation: UserLocation(
            id: '',
            userId: '',
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
            speed: position.speed,
            heading: position.heading,
            recordedAt: DateTime.now(),
          ),
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      _log('Location update error: $e');
      // Silently fail, will retry on next interval
    }
  }

  /// Enable/disable socket-based location updates
  void setUseSocketUpdates(bool useSocket) {
    _useSocketUpdates = useSocket;
  }

  @override
  void dispose() {
    _stopPeriodicUpdates();
    super.dispose();
  }
}

/// Notifier for nearby users
class NearbyUsersNotifier extends StateNotifier<NearbyUsersState> {
  final LocationsRepository _repository;
  final SocketService _socketService;
  bool _isSubscribed = false;

  NearbyUsersNotifier(this._repository, this._socketService)
      : super(const NearbyUsersInitial()) {
    _setupSocketListeners();
  }

  /// Setup socket listeners for real-time location updates
  void _setupSocketListeners() {
    // Listen for individual user location updates
    _socketService.on(SocketEvents.locationUpdated, _handleLocationUpdated);

    // Listen for users who started sharing
    _socketService.on(SocketEvents.locationSharingStarted, _handleUserStartedSharing);

    // Listen for users who stopped sharing
    _socketService.on(SocketEvents.locationSharingStopped, _handleUserStoppedSharing);

    // Listen for nearby users response
    _socketService.on(SocketEvents.nearbyUsers, _handleNearbyUsersResponse);
  }

  /// Handle location update from another user
  void _handleLocationUpdated(dynamic data) {
    try {
      final locationData = data as Map<String, dynamic>?;
      if (locationData == null) return;

      final currentState = state;
      if (currentState is! NearbyUsersLoaded) return;

      final newLocation = UserLocation.fromJson(locationData);
      final existingIndex = currentState.users.indexWhere(
        (u) => u.userId == newLocation.userId,
      );

      if (existingIndex >= 0) {
        // Update existing user
        final updatedUsers = [...currentState.users];
        updatedUsers[existingIndex] = newLocation;
        state = NearbyUsersLoaded(
          users: updatedUsers,
          centerLatitude: currentState.centerLatitude,
          centerLongitude: currentState.centerLongitude,
          radius: currentState.radius,
          loadedAt: currentState.loadedAt,
        );
      } else if (currentState.centerLatitude != null &&
          currentState.centerLongitude != null) {
        // Check if new user is within radius and add
        final distance = newLocation.distanceFrom(
          currentState.centerLatitude!,
          currentState.centerLongitude!,
        );
        final radius = currentState.radius ?? 5000.0; // Default 5km
        if (distance <= radius) {
          state = NearbyUsersLoaded(
            users: [...currentState.users, newLocation],
            centerLatitude: currentState.centerLatitude,
            centerLongitude: currentState.centerLongitude,
            radius: currentState.radius,
            loadedAt: currentState.loadedAt,
          );
        }
      }

      _log('User location updated: ${newLocation.userId}');
    } catch (e) {
      _log('Error handling location update: $e');
    }
  }

  /// Handle user started sharing location
  void _handleUserStartedSharing(dynamic data) {
    try {
      final locationData = data as Map<String, dynamic>?;
      if (locationData == null) return;

      final newLocation = UserLocation.fromJson(locationData);
      final currentState = state;

      if (currentState is NearbyUsersLoaded) {
        // Check if within radius
        if (currentState.centerLatitude != null &&
            currentState.centerLongitude != null) {
          final distance = newLocation.distanceFrom(
            currentState.centerLatitude!,
            currentState.centerLongitude!,
          );
          final radius = currentState.radius ?? 5000.0;
          if (distance <= radius) {
            // Add to list if not already there
            if (!currentState.users.any((u) => u.userId == newLocation.userId)) {
              state = NearbyUsersLoaded(
                users: [...currentState.users, newLocation],
                centerLatitude: currentState.centerLatitude,
                centerLongitude: currentState.centerLongitude,
                radius: currentState.radius,
                loadedAt: currentState.loadedAt,
              );
            }
          }
        }
      }

      _log('User started sharing: ${newLocation.userId}');
    } catch (e) {
      _log('Error handling user started sharing: $e');
    }
  }

  /// Handle user stopped sharing location
  void _handleUserStoppedSharing(dynamic data) {
    try {
      final stopData = data as Map<String, dynamic>?;
      final userId = stopData?['userId'] as String?;
      if (userId == null) return;

      final currentState = state;
      if (currentState is NearbyUsersLoaded) {
        final updatedUsers = currentState.users
            .where((u) => u.userId != userId)
            .toList();

        state = NearbyUsersLoaded(
          users: updatedUsers,
          centerLatitude: currentState.centerLatitude,
          centerLongitude: currentState.centerLongitude,
          radius: currentState.radius,
          loadedAt: currentState.loadedAt,
        );
      }

      _log('User stopped sharing: $userId');
    } catch (e) {
      _log('Error handling user stopped sharing: $e');
    }
  }

  /// Handle nearby users response from socket
  void _handleNearbyUsersResponse(dynamic data) {
    try {
      final usersData = data as List<dynamic>?;
      if (usersData == null) return;

      final users = usersData
          .map((u) => UserLocation.fromJson(u as Map<String, dynamic>))
          .toList();

      final currentState = state;
      state = NearbyUsersLoaded(
        users: users,
        centerLatitude: currentState is NearbyUsersLoaded
            ? currentState.centerLatitude
            : null,
        centerLongitude: currentState is NearbyUsersLoaded
            ? currentState.centerLongitude
            : null,
        radius: currentState is NearbyUsersLoaded ? currentState.radius : null,
        loadedAt: DateTime.now(),
      );

      _log('Nearby users loaded via socket: ${users.length} users');
    } catch (e) {
      _log('Error handling nearby users response: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[NearbyUsersNotifier] $message');
    }
  }

  /// Subscribe to real-time location updates for an area
  void subscribeToArea({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    _socketService.subscribeToLocations(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
    _isSubscribed = true;
    _log('Subscribed to area: ($latitude, $longitude) radius: $radius');
  }

  /// Unsubscribe from location updates
  void unsubscribeFromArea() {
    if (_isSubscribed) {
      _socketService.unsubscribeFromLocations();
      _isSubscribed = false;
      _log('Unsubscribed from location updates');
    }
  }

  /// Request nearby users via socket (faster than HTTP)
  void requestNearbyUsersViaSocket({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    _socketService.requestNearbyUsers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Load nearby users
  Future<void> loadNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    state = const NearbyUsersLoading();

    try {
      final users = await _repository.getNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      state = NearbyUsersLoaded(
        users: users,
        centerLatitude: latitude,
        centerLongitude: longitude,
        radius: radius,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      state = NearbyUsersError(e.toString());
    }
  }

  /// Load active users (police+ only)
  Future<void> loadActiveUsers({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    state = const NearbyUsersLoading();

    try {
      final users = await _repository.getActiveUsers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      state = NearbyUsersLoaded(
        users: users,
        centerLatitude: latitude,
        centerLongitude: longitude,
        radius: radius,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      state = NearbyUsersError(e.toString());
    }
  }

  /// Refresh nearby users
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is NearbyUsersLoaded &&
        currentState.centerLatitude != null &&
        currentState.centerLongitude != null) {
      await loadNearbyUsers(
        latitude: currentState.centerLatitude!,
        longitude: currentState.centerLongitude!,
        radius: currentState.radius,
      );
    }
  }

  @override
  void dispose() {
    // Unsubscribe from location updates
    unsubscribeFromArea();

    // Remove socket listeners
    _socketService.off(SocketEvents.locationUpdated, _handleLocationUpdated);
    _socketService.off(SocketEvents.locationSharingStarted, _handleUserStartedSharing);
    _socketService.off(SocketEvents.locationSharingStopped, _handleUserStoppedSharing);
    _socketService.off(SocketEvents.nearbyUsers, _handleNearbyUsersResponse);

    super.dispose();
  }
}

/// Notifier for location history
class LocationHistoryNotifier extends StateNotifier<LocationHistoryState> {
  final LocationsRepository _repository;

  LocationHistoryNotifier(this._repository)
      : super(const LocationHistoryInitial());

  /// Load location history
  Future<void> loadHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    state = const LocationHistoryLoading();

    try {
      final locations = await _repository.getLocationHistory(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      state = LocationHistoryLoaded(
        locations: locations,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = LocationHistoryError(e.toString());
    }
  }
}
