import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../deep_link/deep_link.dart';
import 'fcm_service.dart';
import 'notification_handler.dart';
import 'notification_state.dart';

/// FCM service provider (singleton)
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

/// Notification state provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  final deepLinkNotifier = ref.watch(deepLinkNotifierProvider.notifier);
  return NotificationNotifier(fcmService, deepLinkNotifier);
});

/// Notification permission status provider
final notificationPermissionProvider = Provider<NotificationPermissionStatus>((ref) {
  return ref.watch(notificationProvider).permissionStatus;
});

/// FCM token provider
final fcmTokenProvider = Provider<String?>((ref) {
  return ref.watch(notificationProvider).fcmToken;
});

/// Are notifications enabled provider
final areNotificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).areNotificationsEnabled;
});

/// Pending notification provider
final pendingNotificationProvider = Provider<NotificationPayload?>((ref) {
  return ref.watch(notificationProvider).pendingNotification;
});

/// Notification notifier for managing FCM state.
///
/// Handles:
/// - FCM initialization
/// - Permission requests
/// - Token management
/// - Server registration
/// - Notification tap handling
/// - Deep link navigation
class NotificationNotifier extends StateNotifier<NotificationState> {
  final FcmService _fcmService;
  final DeepLinkNotifier _deepLinkNotifier;

  NotificationNotifier(this._fcmService, this._deepLinkNotifier)
      : super(NotificationState.initial());

  /// Initialize FCM service
  ///
  /// Should be called after Flutter is initialized and user is ready.
  Future<void> initialize() async {
    if (state.isInitialized || state.isInitializing) {
      return;
    }

    state = state.copyWith(isInitializing: true, clearError: true);

    try {
      // Initialize FCM service
      await _fcmService.initialize();

      // Get current permission status
      final permissionStatus = await _fcmService.getPermissionStatus();

      // Set up notification tap callback to use deep link handler
      _fcmService.notificationHandler.onNotificationTapCallback = _onNotificationTap;

      // Check for initial message (app opened from notification)
      final initialMessage = await _fcmService.getInitialMessage();
      if (initialMessage != null) {
        _fcmService.notificationHandler.handleInitialMessage(initialMessage);
      }

      // Get pending notification from handler and route through deep link
      final pendingNotification =
          _fcmService.notificationHandler.consumePendingNotification();

      if (pendingNotification != null) {
        // Route through deep link handler for consistent navigation
        _deepLinkNotifier.handleNotificationPayload(pendingNotification);
      }

      state = state.copyWith(
        isInitialized: true,
        isInitializing: false,
        permissionStatus: permissionStatus.toNotificationPermissionStatus(),
        pendingNotification: pendingNotification,
      );

      if (kDebugMode) {
        debugPrint('[FCMProvider] Initialized with permission: $permissionStatus');
      }
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: 'Failed to initialize notifications: $e',
      );

      if (kDebugMode) {
        debugPrint('[FCMProvider] Initialization error: $e');
      }
    }
  }

  /// Handle notification tap by routing through deep link handler
  void _onNotificationTap(NotificationPayload payload) {
    if (kDebugMode) {
      debugPrint('[FCMProvider] Notification tapped: ${payload.type}');
    }

    // Route through deep link handler for navigation
    _deepLinkNotifier.handleNotificationPayload(payload);

    // Also update state for any listeners
    state = state.copyWith(pendingNotification: payload);
  }

  /// Request notification permissions
  ///
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    if (!state.isInitialized) {
      await initialize();
    }

    try {
      final granted = await _fcmService.requestPermission();

      final permissionStatus = await _fcmService.getPermissionStatus();
      state = state.copyWith(
        permissionStatus: permissionStatus.toNotificationPermissionStatus(),
      );

      if (kDebugMode) {
        debugPrint('[FCMProvider] Permission requested: $granted');
      }

      return granted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCMProvider] Permission request error: $e');
      }
      return false;
    }
  }

  /// Get FCM token and optionally register with server
  ///
  /// [registerWithServer] - If true, also registers the token with the API.
  Future<String?> getToken({bool registerWithServer = false}) async {
    if (!state.isInitialized) {
      await initialize();
    }

    try {
      final token = await _fcmService.getToken();

      if (token != null) {
        state = state.copyWith(fcmToken: token);

        if (registerWithServer) {
          await registerTokenWithServer();
        }
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCMProvider] Get token error: $e');
      }
      return null;
    }
  }

  /// Register FCM token with the server
  ///
  /// Should be called after user login.
  Future<bool> registerTokenWithServer() async {
    if (!state.isInitialized) {
      await initialize();
    }

    // Ensure we have a token first
    if (state.fcmToken == null) {
      await getToken();
    }

    try {
      final success = await _fcmService.registerTokenWithServer();

      state = state.copyWith(isTokenRegistered: success);

      if (kDebugMode) {
        debugPrint('[FCMProvider] Token registered: $success');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCMProvider] Register token error: $e');
      }
      return false;
    }
  }

  /// Delete FCM token (for logout)
  ///
  /// Should be called when user logs out.
  Future<void> deleteToken() async {
    if (!state.isInitialized) {
      return;
    }

    try {
      await _fcmService.deleteToken();

      state = state.copyWith(
        fcmToken: null,
        isTokenRegistered: false,
      );

      if (kDebugMode) {
        debugPrint('[FCMProvider] Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCMProvider] Delete token error: $e');
      }
    }
  }

  /// Set up notification tap callback
  ///
  /// The callback will be called when a notification is tapped.
  void setNotificationTapCallback(NotificationTapCallback callback) {
    if (!state.isInitialized) {
      return;
    }

    _fcmService.notificationHandler.onNotificationTapCallback = callback;

    // Check for pending notification
    final pending = _fcmService.notificationHandler.consumePendingNotification();
    if (pending != null) {
      callback(pending);
    }
  }

  /// Clear notification tap callback
  void clearNotificationTapCallback() {
    if (!state.isInitialized) {
      return;
    }

    _fcmService.notificationHandler.onNotificationTapCallback = null;
  }

  /// Set pending notification (for deferred handling)
  void setPendingNotification(NotificationPayload payload) {
    state = state.copyWith(pendingNotification: payload);
  }

  /// Consume pending notification
  NotificationPayload? consumePendingNotification() {
    final pending = state.pendingNotification;
    if (pending != null) {
      state = state.copyWith(clearPendingNotification: true);
    }
    return pending;
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    if (!state.isInitialized) {
      await initialize();
    }

    await _fcmService.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!state.isInitialized) {
      await initialize();
    }

    await _fcmService.unsubscribeFromTopic(topic);
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
  }) async {
    if (!state.isInitialized) {
      await initialize();
    }

    await _fcmService.showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: channelId,
    );
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    if (!state.isInitialized) {
      return;
    }

    await _fcmService.cancelNotification(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!state.isInitialized) {
      return;
    }

    await _fcmService.cancelAllNotifications();
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Get route for a notification
  String? getRouteForNotification(NotificationPayload payload) {
    if (!state.isInitialized) {
      return null;
    }

    return _fcmService.notificationHandler.getRouteForNotification(payload);
  }
}

/// Extension for easy access to notification functions from ref
extension NotificationRefExtension on WidgetRef {
  /// Initialize notifications
  Future<void> initializeNotifications() async {
    await read(notificationProvider.notifier).initialize();
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    return read(notificationProvider.notifier).requestPermission();
  }

  /// Register FCM token with server
  Future<bool> registerFcmToken() async {
    return read(notificationProvider.notifier).registerTokenWithServer();
  }

  /// Delete FCM token (logout)
  Future<void> deleteFcmToken() async {
    await read(notificationProvider.notifier).deleteToken();
  }
}
