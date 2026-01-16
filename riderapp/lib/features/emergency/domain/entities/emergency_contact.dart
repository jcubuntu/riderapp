import 'package:equatable/equatable.dart';

/// Emergency contact category
enum EmergencyContactCategory {
  police,
  hospital,
  fire,
  rescue,
  insurance,
  other;

  String get displayName {
    switch (this) {
      case EmergencyContactCategory.police:
        return 'Police';
      case EmergencyContactCategory.hospital:
        return 'Hospital';
      case EmergencyContactCategory.fire:
        return 'Fire Department';
      case EmergencyContactCategory.rescue:
        return 'Rescue';
      case EmergencyContactCategory.insurance:
        return 'Insurance';
      case EmergencyContactCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case EmergencyContactCategory.police:
        return 'local_police';
      case EmergencyContactCategory.hospital:
        return 'local_hospital';
      case EmergencyContactCategory.fire:
        return 'local_fire_department';
      case EmergencyContactCategory.rescue:
        return 'health_and_safety';
      case EmergencyContactCategory.insurance:
        return 'shield';
      case EmergencyContactCategory.other:
        return 'phone';
    }
  }

  static EmergencyContactCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'police':
        return EmergencyContactCategory.police;
      case 'hospital':
        return EmergencyContactCategory.hospital;
      case 'fire':
        return EmergencyContactCategory.fire;
      case 'rescue':
        return EmergencyContactCategory.rescue;
      case 'insurance':
        return EmergencyContactCategory.insurance;
      case 'other':
      default:
        return EmergencyContactCategory.other;
    }
  }
}

/// Emergency contact model
class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phone;
  final EmergencyContactCategory category;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    this.description,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a priority contact (police emergency number)
  bool get isPriorityContact =>
      category == EmergencyContactCategory.police && isDefault;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      category: EmergencyContactCategory.fromString(
        json['category'] as String? ?? 'other',
      ),
      description: json['description'] as String?,
      isDefault:
          json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      sortOrder:
          json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'category': category.name,
      'description': description,
      'isDefault': isDefault,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    EmergencyContactCategory? category,
    String? description,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        category,
        description,
        isDefault,
        isActive,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
