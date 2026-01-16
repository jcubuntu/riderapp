import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_handler.dart';

/// Notification permission status
enum NotificationPermissionStatus {
  /// Permission not yet requested
  notDetermined,

  /// Permission granted
  granted,

  /// Permission denied
  denied,

  /// Permission granted provisionally (iOS)
  provisional,
}

/// Extension to convert Firebase AuthorizationStatus
extension AuthorizationStatusExtension on AuthorizationStatus {
  NotificationPermissionStatus toNotificationPermissionStatus() {
    switch (this) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
    }
  }
}

/// Notification state for the FCM provider.
///
/// Tracks:
/// - FCM initialization status
/// - Notification permission status
/// - Current FCM token
/// - Pending notifications
class NotificationState extends Equatable {
  /// Whether FCM has been initialized
  final bool isInitialized;

  /// Whether FCM is currently initializing
  final bool isInitializing;

  /// Notification permission status
  final NotificationPermissionStatus permissionStatus;

  /// Current FCM token
  final String? fcmToken;

  /// Whether token has been registered with server
  final bool isTokenRegistered;

  /// Pending notification payload (to be handled on app ready)
  final NotificationPayload? pendingNotification;

  /// Error message if initialization failed
  final String? error;

  const NotificationState({
    this.isInitialized = false,
    this.isInitializing = false,
    this.permissionStatus = NotificationPermissionStatus.notDetermined,
    this.fcmToken,
    this.isTokenRegistered = false,
    this.pendingNotification,
    this.error,
  });

  /// Create initial state
  factory NotificationState.initial() => const NotificationState();

  /// Create loading state
  factory NotificationState.initializing() => const NotificationState(
        isInitializing: true,
      );

  /// Create initialized state
  factory NotificationState.initialized({
    required NotificationPermissionStatus permissionStatus,
    String? fcmToken,
  }) =>
      NotificationState(
        isInitialized: true,
        permissionStatus: permissionStatus,
        fcmToken: fcmToken,
      );

  /// Create error state
  factory NotificationState.error(String message) => NotificationState(
        error: message,
      );

  /// Copy with modifications
  NotificationState copyWith({
    bool? isInitialized,
    bool? isInitializing,
    NotificationPermissionStatus? permissionStatus,
    String? fcmToken,
    bool? isTokenRegistered,
    NotificationPayload? pendingNotification,
    String? error,
    bool clearPendingNotification = false,
    bool clearError = false,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isInitializing: isInitializing ?? this.isInitializing,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      fcmToken: fcmToken ?? this.fcmToken,
      isTokenRegistered: isTokenRegistered ?? this.isTokenRegistered,
      pendingNotification:
          clearPendingNotification ? null : (pendingNotification ?? this.pendingNotification),
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether notifications are enabled
  bool get areNotificationsEnabled =>
      permissionStatus == NotificationPermissionStatus.granted ||
      permissionStatus == NotificationPermissionStatus.provisional;

  /// Whether there's a pending notification
  bool get hasPendingNotification => pendingNotification != null;

  /// Whether there's an error
  bool get hasError => error != null;

  @override
  List<Object?> get props => [
        isInitialized,
        isInitializing,
        permissionStatus,
        fcmToken,
        isTokenRegistered,
        pendingNotification,
        error,
      ];
}

/// Notification payload data.
///
/// Represents the data extracted from a push notification.
class NotificationPayload extends Equatable {
  /// Unique notification ID
  final String? id;

  /// Notification type (incident, chat, announcement, etc.)
  final String type;

  /// Notification title
  final String? title;

  /// Notification body
  final String? body;

  /// Additional data payload
  final Map<String, dynamic> data;

  /// Timestamp when notification was received
  final DateTime receivedAt;

  const NotificationPayload({
    this.id,
    required this.type,
    this.title,
    this.body,
    this.data = const {},
    required this.receivedAt,
  });

  /// Create from Firebase RemoteMessage
  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return NotificationPayload(
      id: message.messageId,
      type: data['type'] as String? ?? NotificationType.general,
      title: notification?.title ?? data['title'] as String?,
      body: notification?.body ?? data['body'] as String?,
      data: Map<String, dynamic>.from(data),
      receivedAt: message.sentTime ?? DateTime.now(),
    );
  }

  /// Create from JSON map
  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      id: json['id'] as String?,
      type: json['type'] as String? ?? NotificationType.general,
      title: json['title'] as String?,
      body: json['body'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      receivedAt: json['receivedAt'] != null
          ? DateTime.parse(json['receivedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, type, title, body, data, receivedAt];

  @override
  String toString() {
    return 'NotificationPayload(id: $id, type: $type, title: $title)';
  }
}
