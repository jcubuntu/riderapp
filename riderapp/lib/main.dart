import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/notifications/fcm_service.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up Firebase background message handler
  // IMPORTANT: Must be set BEFORE initializing Firebase
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize secure storage
  await SecureStorage().init();

  // Initialize API client
  await ApiClient().init();

  // Initialize Firebase and FCM service
  // TODO: Ensure google-services.json is in android/app/
  // TODO: Ensure GoogleService-Info.plist is in ios/Runner/
  await FcmService().initialize();

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
