import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_service.dart';
import 'notification_state.dart';

/// Notification type constants
abstract final class NotificationType {
  static const String incident = 'incident';
  static const String announcement = 'announcement';
  static const String chat = 'chat';
  static const String emergency = 'emergency';
  static const String approval = 'approval';
  static const String general = 'general';
}

/// Handles notification processing and display.
///
/// Responsible for:
/// - Parsing notification data
/// - Displaying foreground notifications
/// - Processing notification taps
/// - Managing notification payloads
class NotificationHandler {
  /// Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Callback for notification tap
  NotificationTapCallback? onNotificationTapCallback;

  /// Pending notification data (for handling when app opens)
  NotificationPayload? _pendingNotification;

  /// Constructor
  NotificationHandler(this._localNotifications);

  /// Get pending notification and clear it
  NotificationPayload? consumePendingNotification() {
    final pending = _pendingNotification;
    _pendingNotification = null;
    return pending;
  }

  /// Check if there's a pending notification
  bool get hasPendingNotification => _pendingNotification != null;

  // ============================================================================
  // FOREGROUND MESSAGE HANDLING
  // ============================================================================

  /// Handle foreground message
  ///
  /// Shows a local notification when the app is in the foreground.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Parse notification payload
    final payload = NotificationPayload.fromRemoteMessage(message);

    if (kDebugMode) {
      debugPrint('[NotificationHandler] Foreground message: ${payload.type}');
    }

    // Show local notification if there's notification content
    if (notification != null) {
      await _showNotification(
        id: message.hashCode,
        title: notification.title ?? 'RiderApp',
        body: notification.body ?? '',
        payload: payload,
        type: payload.type,
      );
    } else if (data.isNotEmpty) {
      // Data-only message - show notification from data
      final title = data['title'] as String? ?? 'RiderApp';
      final body = data['body'] as String? ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        await _showNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: payload,
          type: payload.type,
        );
      }
    }
  }

  /// Show a local notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationPayload payload,
    required String type,
  }) async {
    // Determine channel based on notification type
    final channel = _getChannelForType(type);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: _getPriorityForType(type),
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      // Use different colors for different notification types
      color: _getColorForType(type),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode(payload.toJson()),
    );
  }

  /// Get notification channel based on type
  AndroidNotificationChannel _getChannelForType(String type) {
    switch (type) {
      case NotificationType.emergency:
        return FcmService.emergencyChannel;
      case NotificationType.incident:
      case NotificationType.approval:
        return FcmService.highImportanceChannel;
      default:
        return FcmService.defaultChannel;
    }
  }

  /// Get notification priority based on type
  Priority _getPriorityForType(String type) {
    switch (type) {
      case NotificationType.emergency:
        return Priority.max;
      case NotificationType.incident:
      case NotificationType.approval:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Get notification color based on type
  Color _getColorForType(String type) {
    switch (type) {
      case NotificationType.emergency:
        return const Color(0xFFFF0000); // Red
      case NotificationType.incident:
        return const Color(0xFFFF9800); // Orange
      case NotificationType.approval:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.chat:
        return const Color(0xFF2196F3); // Blue
      case NotificationType.announcement:
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF6200EE); // Default purple
    }
  }

  // ============================================================================
  // NOTIFICATION TAP HANDLING
  // ============================================================================

  /// Handle notification tap (from FCM)
  void handleNotificationTap(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);

    if (kDebugMode) {
      debugPrint('[NotificationHandler] Notification tapped: ${payload.type}');
    }

    // If callback is set, call it immediately
    if (onNotificationTapCallback != null) {
      onNotificationTapCallback!(payload);
    } else {
      // Store for later processing
      _pendingNotification = payload;
    }
  }

  /// Handle notification tap (from local notification)
  void onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('[NotificationHandler] Local notification tapped: ${response.payload}');
    }

    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final payload = NotificationPayload.fromJson(data);

      // If callback is set, call it immediately
      if (onNotificationTapCallback != null) {
        onNotificationTapCallback!(payload);
      } else {
        // Store for later processing
        _pendingNotification = payload;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationHandler] Error parsing notification payload: $e');
      }
    }
  }

  /// Handle initial message (app opened from notification while terminated)
  void handleInitialMessage(RemoteMessage? message) {
    if (message == null) return;

    final payload = NotificationPayload.fromRemoteMessage(message);

    if (kDebugMode) {
      debugPrint('[NotificationHandler] Initial message: ${payload.type}');
    }

    // Store for later processing (app just started)
    _pendingNotification = payload;
  }

  // ============================================================================
  // NOTIFICATION ACTIONS
  // ============================================================================

  /// Get navigation route for notification
  String? getRouteForNotification(NotificationPayload payload) {
    switch (payload.type) {
      case NotificationType.incident:
        final incidentId = payload.data['incidentId'];
        if (incidentId != null) {
          return '/incidents/$incidentId';
        }
        return '/incidents';

      case NotificationType.chat:
        final conversationId = payload.data['conversationId'];
        if (conversationId != null) {
          return '/chat/$conversationId';
        }
        return '/chat';

      case NotificationType.announcement:
        final announcementId = payload.data['announcementId'];
        if (announcementId != null) {
          return '/announcements/$announcementId';
        }
        return '/announcements';

      case NotificationType.emergency:
        return '/emergency';

      case NotificationType.approval:
        return '/pending-approval';

      default:
        return null;
    }
  }
}

/// Callback type for notification tap events
typedef NotificationTapCallback = void Function(NotificationPayload payload);
