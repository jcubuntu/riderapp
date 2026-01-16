import 'package:equatable/equatable.dart';

/// User roles in the system
enum UserRole {
  rider,
  volunteer,
  police,
  commander,
  admin,
  superAdmin;

  String get displayName {
    switch (this) {
      case UserRole.rider:
        return 'Rider';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.police:
        return 'Police';
      case UserRole.commander:
        return 'Commander';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Get role hierarchy level (higher = more privileges)
  int get level {
    switch (this) {
      case UserRole.rider:
        return 1;
      case UserRole.volunteer:
        return 2;
      case UserRole.police:
        return 3;
      case UserRole.commander:
        return 4;
      case UserRole.admin:
        return 5;
      case UserRole.superAdmin:
        return 6;
    }
  }

  /// Check if this role has at least the given minimum role level
  bool hasMinimumRole(UserRole minRole) => level >= minRole.level;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'rider':
        return UserRole.rider;
      case 'volunteer':
        return UserRole.volunteer;
      case 'police':
        return UserRole.police;
      case 'commander':
        return UserRole.commander;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.rider;
    }
  }
}

/// User account status
enum UserStatus {
  pending,
  approved,
  rejected,
  suspended;

  String get displayName {
    switch (this) {
      case UserStatus.pending:
        return 'Pending Approval';
      case UserStatus.approved:
        return 'Approved';
      case UserStatus.rejected:
        return 'Rejected';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }

  static UserStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return UserStatus.pending;
      case 'approved':
        return UserStatus.approved;
      case 'rejected':
        return UserStatus.rejected;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.pending;
    }
  }
}

/// User model representing a user in the system
class UserModel extends Equatable {
  final String id;
  final String phone;
  final String fullName;
  final String? idCardNumber;
  final String? affiliation;
  final String? address;
  final UserRole role;
  final UserStatus status;
  final String? profileImageUrl;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    this.idCardNumber,
    this.affiliation,
    this.address,
    required this.role,
    required this.status,
    this.profileImageUrl,
    this.approvedAt,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Check if user is approved and can use the app
  bool get isApproved => status == UserStatus.approved;

  /// Check if user is pending approval
  bool get isPending => status == UserStatus.pending;

  /// Check if user is a rider
  bool get isRider => role == UserRole.rider;

  /// Check if user is police
  bool get isPolice => role == UserRole.police;

  /// Check if user is commander
  bool get isCommander => role == UserRole.commander;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is volunteer
  bool get isVolunteer => role == UserRole.volunteer;

  /// Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user can create announcements
  bool get canCreateAnnouncements => role.hasMinimumRole(UserRole.police);

  /// Check if user can approve other users
  bool get canApproveUsers => role.hasMinimumRole(UserRole.police);

  /// Check if user can manage users
  bool get canManageUsers => role.hasMinimumRole(UserRole.commander);

  /// Check if user can manage admins (super admin only)
  bool get canManageAdmins => isSuperAdmin;

  /// Check if user can access system config (super admin only)
  bool get canAccessSystemConfig => isSuperAdmin;

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      idCardNumber: json['id_card_number'] as String? ?? json['idCardNumber'] as String?,
      affiliation: json['affiliation'] as String?,
      address: json['address'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'rider'),
      status: UserStatus.fromString(json['status'] as String? ?? 'pending'),
      profileImageUrl: json['profile_image_url'] as String? ?? json['profileImageUrl'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : json['approvedAt'] != null
              ? DateTime.parse(json['approvedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : json['lastLoginAt'] != null
              ? DateTime.parse(json['lastLoginAt'] as String)
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'id_card_number': idCardNumber,
      'affiliation': affiliation,
      'address': address,
      'role': role.name,
      'status': status.name,
      'profile_image_url': profileImageUrl,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Copy with new values
  UserModel copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? idCardNumber,
    String? affiliation,
    String? address,
    UserRole? role,
    UserStatus? status,
    String? profileImageUrl,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      affiliation: affiliation ?? this.affiliation,
      address: address ?? this.address,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        fullName,
        idCardNumber,
        affiliation,
        address,
        role,
        status,
        profileImageUrl,
        approvedAt,
        createdAt,
        lastLoginAt,
      ];
}
