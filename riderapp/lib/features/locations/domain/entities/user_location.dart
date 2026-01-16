import 'package:equatable/equatable.dart';

/// User location model representing a location point
class UserLocation extends Equatable {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;
  final DateTime? createdAt;

  /// User information (populated when fetching nearby users)
  final String? userName;
  final String? userPhone;
  final String? userRole;

  const UserLocation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.recordedAt,
    this.createdAt,
    this.userName,
    this.userPhone,
    this.userRole,
  });

  /// Distance from another location in meters (approximate)
  double distanceFrom(double lat, double lng) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) *
            _cos(_toRadians(lat)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : json['recordedAt'] != null
              ? DateTime.parse(json['recordedAt'] as String)
              : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      userName: json['user_name'] as String? ?? json['userName'] as String?,
      userPhone: json['user_phone'] as String? ?? json['userPhone'] as String?,
      userRole: json['user_role'] as String? ?? json['userRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'recordedAt': recordedAt.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'userName': userName,
        'userPhone': userPhone,
        'userRole': userRole,
      };

  UserLocation copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? recordedAt,
    DateTime? createdAt,
    String? userName,
    String? userPhone,
    String? userRole,
  }) {
    return UserLocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        recordedAt,
        createdAt,
        userName,
        userPhone,
        userRole,
      ];
}

/// Location sharing status
enum LocationSharingStatus {
  active,
  inactive;

  String get displayName {
    switch (this) {
      case LocationSharingStatus.active:
        return 'Active';
      case LocationSharingStatus.inactive:
        return 'Inactive';
    }
  }

  static LocationSharingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return LocationSharingStatus.active;
      case 'inactive':
        return LocationSharingStatus.inactive;
      default:
        return LocationSharingStatus.inactive;
    }
  }
}

/// Location sharing info
class LocationSharingInfo extends Equatable {
  final bool isSharing;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? shareId;

  const LocationSharingInfo({
    required this.isSharing,
    this.startedAt,
    this.expiresAt,
    this.shareId,
  });

  factory LocationSharingInfo.fromJson(Map<String, dynamic> json) {
    return LocationSharingInfo(
      isSharing: json['is_sharing'] as bool? ?? json['isSharing'] as bool? ?? false,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : json['startedAt'] != null
              ? DateTime.parse(json['startedAt'] as String)
              : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      shareId: json['share_id'] as String? ?? json['shareId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'isSharing': isSharing,
        'startedAt': startedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'shareId': shareId,
      };

  @override
  List<Object?> get props => [isSharing, startedAt, expiresAt, shareId];
}
