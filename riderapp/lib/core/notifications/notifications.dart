/// Firebase Cloud Messaging and notification handling for RiderApp.
///
/// This module provides:
/// - FCM initialization and token management
/// - Push notification permissions
/// - Foreground and background message handling
/// - Local notification display
/// - Notification tap handling with navigation
///
/// ## Setup Requirements
///
/// ### Android Configuration
/// TODO: Add google-services.json to android/app/
/// TODO: Apply google-services plugin in android/build.gradle:
/// ```gradle
/// buildscript {
///     dependencies {
///         classpath 'com.google.gms:google-services:4.4.0'
///     }
/// }
/// ```
/// TODO: Apply plugin in android/app/build.gradle:
/// ```gradle
/// apply plugin: 'com.google.gms.google-services'
/// ```
///
/// ### iOS Configuration
/// TODO: Add GoogleService-Info.plist to ios/Runner/
/// TODO: Enable Push Notifications capability in Xcode
/// TODO: Enable Background Modes > Remote notifications in Xcode
///
/// ## Usage
///
/// ### Initialize in main.dart:
/// ```dart
/// import 'package:riderapp/core/notifications/notifications.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Set up background handler BEFORE initializing FCM
///   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
///
///   // Initialize FCM service
///   await FcmService().initialize();
///
///   runApp(ProviderScope(child: MyApp()));
/// }
/// ```
///
/// ### Request permissions and register token:
/// ```dart
/// // In your app widget after user is authenticated
/// final notifier = ref.read(notificationProvider.notifier);
///
/// // Initialize FCM
/// await notifier.initialize();
///
/// // Request permission
/// final granted = await notifier.requestPermission();
///
/// // Get token and register with server
/// await notifier.getToken(registerWithServer: true);
/// ```
///
/// ### Handle notification taps:
/// ```dart
/// // Set up callback for notification taps
/// ref.read(notificationProvider.notifier).setNotificationTapCallback((payload) {
///   final route = notifier.getRouteForNotification(payload);
///   if (route != null) {
///     GoRouter.of(context).push(route);
///   }
/// });
/// ```
///
/// ### On logout:
/// ```dart
/// await ref.read(notificationProvider.notifier).deleteToken();
/// ```
library;

export 'fcm_provider.dart';
export 'fcm_service.dart';
export 'notification_handler.dart';
export 'notification_state.dart';
