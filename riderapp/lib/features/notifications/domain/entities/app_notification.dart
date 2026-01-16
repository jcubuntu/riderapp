import 'package:equatable/equatable.dart';

/// Notification types in the system
enum NotificationType {
  chat,
  incident,
  announcement,
  sos,
  approval,
  system;

  /// Get display name for the notification type
  String get displayName {
    switch (this) {
      case NotificationType.chat:
        return 'Chat';
      case NotificationType.incident:
        return 'Incident';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.sos:
        return 'SOS';
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.system:
        return 'System';
    }
  }

  /// Parse from string
  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'chat':
        return NotificationType.chat;
      case 'incident':
        return NotificationType.incident;
      case 'announcement':
        return NotificationType.announcement;
      case 'sos':
        return NotificationType.sos;
      case 'approval':
        return NotificationType.approval;
      case 'system':
      default:
        return NotificationType.system;
    }
  }
}

/// App notification model
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Check if notification has a target to navigate to
  bool get hasTarget => targetId != null && targetId!.isNotEmpty;

  /// Create from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'system'),
      targetId: json['target_id'] as String? ?? json['targetId'] as String?,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'targetId': targetId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  /// Copy with new values
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        targetId,
        isRead,
        createdAt,
        readAt,
      ];
}

/// Paginated notifications result
class PaginatedNotifications extends Equatable {
  final List<AppNotification> notifications;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final int unreadCount;

  const PaginatedNotifications({
    required this.notifications,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.unreadCount = 0,
  });

  bool get hasNextPage => page < totalPages;

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedNotifications(
      notifications: data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int? ?? 0,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      totalPages: pagination['totalPages'] as int? ?? 1,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [notifications, total, page, limit, totalPages, unreadCount];
}
