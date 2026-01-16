import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import 'notification_handler.dart';

/// Firebase Cloud Messaging service for push notifications.
///
/// Handles:
/// - Firebase initialization
/// - FCM token management
/// - Notification permissions
/// - Local notification display
/// - Background message handling
class FcmService {
  /// Private constructor
  FcmService._internal();

  /// Singleton instance
  static final FcmService _instance = FcmService._internal();

  /// Factory constructor returns singleton
  factory FcmService() => _instance;

  /// Firebase Messaging instance
  late final FirebaseMessaging _messaging;

  /// Local notifications plugin
  late final FlutterLocalNotificationsPlugin _localNotifications;

  /// Secure storage for token persistence
  final SecureStorage _secureStorage = SecureStorage();

  /// API client for server communication
  final ApiClient _apiClient = ApiClient();

  /// Notification handler for processing messages
  late final NotificationHandler _notificationHandler;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Current FCM token
  String? _currentToken;

  // ============================================================================
  // ANDROID NOTIFICATION CHANNEL
  // ============================================================================

  /// High importance notification channel for Android
  static const AndroidNotificationChannel highImportanceChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Default notification channel for Android
  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
    'default_channel',
    'Default Notifications',
    description: 'This channel is used for general notifications.',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Emergency notification channel for Android
  static const AndroidNotificationChannel emergencyChannel =
      AndroidNotificationChannel(
    'emergency_channel',
    'Emergency Notifications',
    description: 'This channel is used for emergency alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Whether Firebase is available
  bool _isFirebaseAvailable = false;

  /// Initialize Firebase and FCM service
  ///
  /// Must be called before using any FCM features.
  /// Typically called in main.dart before runApp().
  /// Returns true if Firebase was initialized successfully.
  Future<bool> initialize() async {
    if (_isInitialized) return _isFirebaseAvailable;

    // Initialize local notifications first (works without Firebase)
    _localNotifications = FlutterLocalNotificationsPlugin();
    _notificationHandler = NotificationHandler(_localNotifications);
    await _initializeLocalNotifications();

    // Create notification channels (Android only)
    await _createNotificationChannels();

    // Try to initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;

      // Set up message handlers
      _setupMessageHandlers();

      _isFirebaseAvailable = true;

      if (kDebugMode) {
        debugPrint('[FCM] Firebase initialized successfully');
      }
    } catch (e) {
      _isFirebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('[FCM] Firebase not available: $e');
        debugPrint('[FCM] Push notifications will be disabled');
        debugPrint('[FCM] To enable, add google-services.json (Android) or GoogleService-Info.plist (iOS)');
      }
    }

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('[FCM] Service initialized (Firebase: $_isFirebaseAvailable)');
    }

    return _isFirebaseAvailable;
  }

  /// Check if Firebase is available
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    // TODO: Enable push notification capability in Xcode
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // macOS initialization settings
    const macOsSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOsSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _notificationHandler.onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Create all channels
    await Future.wait([
      androidPlugin.createNotificationChannel(highImportanceChannel),
      androidPlugin.createNotificationChannel(defaultChannel),
      androidPlugin.createNotificationChannel(emergencyChannel),
    ]);

    if (kDebugMode) {
      debugPrint('[FCM] Android notification channels created');
    }
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle background message tap (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ============================================================================
  // PERMISSIONS
  // ============================================================================

  /// Request notification permissions
  ///
  /// Returns true if permission was granted, false otherwise.
  /// Returns false if Firebase is not available.
  Future<bool> requestPermission() async {
    _ensureInitialized();

    if (!_isFirebaseAvailable) {
      if (kDebugMode) {
        debugPrint('[FCM] Cannot request permission: Firebase not available');
      }
      return false;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (kDebugMode) {
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    }

    // Also request local notification permissions on iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    return isGranted;
  }

  /// Check current permission status
  /// Returns AuthorizationStatus.denied if Firebase is not available.
  Future<AuthorizationStatus> getPermissionStatus() async {
    _ensureInitialized();
    if (!_isFirebaseAvailable) return AuthorizationStatus.denied;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await getPermissionStatus();
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  // ============================================================================
  // TOKEN MANAGEMENT
  // ============================================================================

  /// Get current FCM token
  ///
  /// If no token is cached, fetches a new one from Firebase.
  /// Returns null if Firebase is not available.
  Future<String?> getToken() async {
    _ensureInitialized();

    if (!_isFirebaseAvailable) {
      if (kDebugMode) {
        debugPrint('[FCM] Cannot get token: Firebase not available');
      }
      return null;
    }

    if (_currentToken != null) {
      return _currentToken;
    }

    try {
      // Get APNS token first on iOS (required for FCM token)
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('[FCM] APNS token not available yet');
          }
          return null;
        }
      }

      _currentToken = await _messaging.getToken();

      if (_currentToken != null) {
        await _secureStorage.saveFcmToken(_currentToken!);

        if (kDebugMode) {
          debugPrint('[FCM] Token obtained: ${_currentToken!.substring(0, 20)}...');
        }
      }

      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error getting token: $e');
      }
      return null;
    }
  }

  /// Register FCM token with the server
  ///
  /// Should be called after user login to associate the device token
  /// with the user's account.
  Future<bool> registerTokenWithServer() async {
    _ensureInitialized();

    final token = await getToken();
    if (token == null) {
      if (kDebugMode) {
        debugPrint('[FCM] No token to register');
      }
      return false;
    }

    try {
      final response = await _apiClient.post(
        ApiEndpoints.updateFcmToken,
        data: {
          'fcmToken': token,
          'platform': Platform.operatingSystem,
          'deviceName': await _getDeviceName(),
        },
      );

      final success = response.data['success'] == true;

      if (kDebugMode) {
        debugPrint('[FCM] Token registered with server: $success');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error registering token: $e');
      }
      return false;
    }
  }

  /// Delete FCM token (for logout)
  ///
  /// Removes the token from Firebase and clears local storage.
  Future<void> deleteToken() async {
    _ensureInitialized();

    try {
      if (_isFirebaseAvailable) {
        await _messaging.deleteToken();
      }
      await _secureStorage.deleteFcmToken();
      _currentToken = null;

      if (kDebugMode) {
        debugPrint('[FCM] Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error deleting token: $e');
      }
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) async {
    if (kDebugMode) {
      debugPrint('[FCM] Token refreshed: ${token.substring(0, 20)}...');
    }

    _currentToken = token;
    await _secureStorage.saveFcmToken(token);

    // Re-register with server if user is logged in
    final hasAccessToken = await _secureStorage.hasAccessToken();
    if (hasAccessToken) {
      await registerTokenWithServer();
    }
  }

  // ============================================================================
  // MESSAGE HANDLERS
  // ============================================================================

  /// Handle foreground message
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
      debugPrint('[FCM] Data: ${message.data}');
    }

    _notificationHandler.handleForegroundMessage(message);
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
    }

    _notificationHandler.handleNotificationTap(message);
  }

  /// Check for initial message (app opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    _ensureInitialized();
    if (!_isFirebaseAvailable) return null;
    return _messaging.getInitialMessage();
  }

  // ============================================================================
  // TOPIC SUBSCRIPTION
  // ============================================================================

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    _ensureInitialized();
    if (!_isFirebaseAvailable) return;

    try {
      await _messaging.subscribeToTopic(topic);

      if (kDebugMode) {
        debugPrint('[FCM] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _ensureInitialized();
    if (!_isFirebaseAvailable) return;

    try {
      await _messaging.unsubscribeFromTopic(topic);

      if (kDebugMode) {
        debugPrint('[FCM] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Error unsubscribing from topic: $e');
      }
    }
  }

  // ============================================================================
  // LOCAL NOTIFICATIONS
  // ============================================================================

  /// Show a local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
    String channelName = 'Default Notifications',
  }) async {
    _ensureInitialized();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    _ensureInitialized();
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    _ensureInitialized();
    await _localNotifications.cancelAll();
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'FcmService not initialized. Call FcmService().initialize() first.',
      );
    }
  }

  /// Get device name
  Future<String> _getDeviceName() async {
    if (Platform.isAndroid) {
      return 'Android Device';
    } else if (Platform.isIOS) {
      return 'iOS Device';
    } else if (Platform.isMacOS) {
      return 'macOS Device';
    } else if (Platform.isWindows) {
      return 'Windows Device';
    } else if (Platform.isLinux) {
      return 'Linux Device';
    }
    return 'Unknown Device';
  }

  /// Get notification handler instance
  /// Returns null if Firebase is not available.
  NotificationHandler? get notificationHandler {
    _ensureInitialized();
    if (!_isFirebaseAvailable) return null;
    return _notificationHandler;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current token (cached, may be null)
  String? get currentToken => _currentToken;
}

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================

/// Top-level function to handle background messages.
///
/// Must be a top-level function (not a class method).
/// Called when app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    debugPrint('[FCM Background] Message received: ${message.messageId}');
    debugPrint('[FCM Background] Title: ${message.notification?.title}');
    debugPrint('[FCM Background] Body: ${message.notification?.body}');
    debugPrint('[FCM Background] Data: ${message.data}');
  }

  // Background messages are automatically displayed by the system
  // Additional processing can be done here if needed
}

/// Top-level function for handling notification tap in background.
///
/// Required for flutter_local_notifications background tap handling.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    debugPrint('[FCM Background] Notification tapped: ${notificationResponse.payload}');
  }

  // The notification tap will be handled when the app opens
  // Store the payload for later processing if needed
}
