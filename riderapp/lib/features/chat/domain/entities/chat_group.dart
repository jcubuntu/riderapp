import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';

/// Entity representing a role-based chat group
class ChatGroup extends Equatable {
  final String id;
  final String title;
  final String minimumRole;
  final int participantCount;
  final bool isJoined;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatGroup({
    required this.id,
    required this.title,
    required this.minimumRole,
    required this.participantCount,
    this.isJoined = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user with given role can access this group
  bool canAccess(UserRole userRole) {
    final minRole = UserRole.fromString(minimumRole);
    return userRole.hasMinimumRole(minRole);
  }

  /// Get the minimum role as UserRole enum
  UserRole get minimumRoleEnum => UserRole.fromString(minimumRole);

  /// Get localization key for access description
  String get accessDescriptionKey => 'chat.groupAccess.$minimumRole';

  /// Get icon for the group based on minimum role
  String get roleIcon {
    switch (minimumRole) {
      case 'rider':
        return 'G'; // General
      case 'volunteer':
        return 'V'; // Volunteer
      case 'police':
        return 'P'; // Police
      case 'commander':
        return 'C'; // Commander
      case 'admin':
        return 'A'; // Admin
      default:
        return 'G';
    }
  }

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      minimumRole: json['minimumRole'] as String? ?? json['minimum_role'] as String? ?? 'rider',
      participantCount: json['participantCount'] as int? ?? json['participant_count'] as int? ?? 0,
      isJoined: json['isJoined'] as bool? ?? json['is_joined'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'minimumRole': minimumRole,
      'participantCount': participantCount,
      'isJoined': isJoined,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatGroup copyWith({
    String? id,
    String? title,
    String? minimumRole,
    int? participantCount,
    bool? isJoined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      minimumRole: minimumRole ?? this.minimumRole,
      participantCount: participantCount ?? this.participantCount,
      isJoined: isJoined ?? this.isJoined,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        minimumRole,
        participantCount,
        isJoined,
        createdAt,
        updatedAt,
      ];
}
