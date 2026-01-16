import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/notifications/fcm_service.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize secure storage
  await SecureStorage().init();

  // Initialize API client
  await ApiClient().init();

  // Initialize Firebase and FCM service (optional - works without Firebase config)
  // If Firebase config files are not present, push notifications will be disabled
  // To enable: add google-services.json (Android) or GoogleService-Info.plist (iOS)
  final firebaseAvailable = await FcmService().initialize();
  if (kDebugMode) {
    debugPrint('[Main] Firebase available: $firebaseAvailable');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('th'),
      child: const ProviderScope(
        child: RiderApp(),
      ),
    ),
  );
}
