import 'package:equatable/equatable.dart';

/// SOS alert status
enum SosStatus {
  active,
  resolved,
  cancelled;

  String get displayName {
    switch (this) {
      case SosStatus.active:
        return 'Active';
      case SosStatus.resolved:
        return 'Resolved';
      case SosStatus.cancelled:
        return 'Cancelled';
    }
  }

  static SosStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SosStatus.active;
      case 'resolved':
        return SosStatus.resolved;
      case 'cancelled':
        return SosStatus.cancelled;
      default:
        return SosStatus.active;
    }
  }
}

/// SOS Alert model
class SosAlert extends Equatable {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhone;
  final SosStatus status;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? notes;
  final String? resolvedBy;
  final String? resolutionNotes;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final DateTime? cancelledAt;

  const SosAlert({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhone,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.notes,
    this.resolvedBy,
    this.resolutionNotes,
    required this.triggeredAt,
    this.resolvedAt,
    this.cancelledAt,
  });

  bool get isActive => status == SosStatus.active;
  bool get hasLocation => latitude != null && longitude != null;

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      userName: json['user_name'] as String? ?? json['userName'] as String?,
      userPhone: json['user_phone'] as String? ?? json['userPhone'] as String?,
      status: SosStatus.fromString(json['status'] as String? ?? 'active'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['location_address'] as String? ??
          json['locationAddress'] as String?,
      notes: json['notes'] as String?,
      resolvedBy:
          json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolutionNotes: json['resolution_notes'] as String? ??
          json['resolutionNotes'] as String?,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : json['triggeredAt'] != null
              ? DateTime.parse(json['triggeredAt'] as String)
              : json['created_at'] != null
                  ? DateTime.parse(json['created_at'] as String)
                  : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'] as String)
              : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : json['cancelledAt'] != null
              ? DateTime.parse(json['cancelledAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'status': status.name,
        'latitude': latitude,
        'longitude': longitude,
        'locationAddress': locationAddress,
        'notes': notes,
        'resolvedBy': resolvedBy,
        'resolutionNotes': resolutionNotes,
        'triggeredAt': triggeredAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
      };

  SosAlert copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    SosStatus? status,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? notes,
    String? resolvedBy,
    String? resolutionNotes,
    DateTime? triggeredAt,
    DateTime? resolvedAt,
    DateTime? cancelledAt,
  }) {
    return SosAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      notes: notes ?? this.notes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        status,
        latitude,
        longitude,
        locationAddress,
        notes,
        resolvedBy,
        resolutionNotes,
        triggeredAt,
        resolvedAt,
        cancelledAt,
      ];
}
