// File generated based on google-services.json and GoogleService-Info.plist
// Project: makerrobotics-push

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAHv5mmylT3GMv4yF7I2ubh-tJ74w5weZM',
    appId: '1:184531063600:android:c49553ca4e2bac57ef2ef5',
    messagingSenderId: '184531063600',
    projectId: 'makerrobotics-push',
    storageBucket: 'makerrobotics-push.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAd_gRxMVCFj_aayCCoTimNvAta79mPPQ',
    appId: '1:184531063600:ios:1ed18359e988b26cef2ef5',
    messagingSenderId: '184531063600',
    projectId: 'makerrobotics-push',
    storageBucket: 'makerrobotics-push.firebasestorage.app',
    iosBundleId: 'com.makerrobotics.rider',
  );
}
