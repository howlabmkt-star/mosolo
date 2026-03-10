import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1u8XuGdWFkfdk_hAt--vohXKKMLVj1x0',
    appId: '1:406076684401:web:1c3555c90ebf5fb357c3d0',
    messagingSenderId: '406076684401',
    projectId: 'solo-simkung',
    authDomain: 'solo-simkung.firebaseapp.com',
    storageBucket: 'solo-simkung.firebasestorage.app',
    measurementId: 'G-TM7HKH4MHY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1u8XuGdWFkfdk_hAt--vohXKKMLVj1x0',
    appId: '1:406076684401:web:1c3555c90ebf5fb357c3d0',
    messagingSenderId: '406076684401',
    projectId: 'solo-simkung',
    storageBucket: 'solo-simkung.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1u8XuGdWFkfdk_hAt--vohXKKMLVj1x0',
    appId: '1:406076684401:web:1c3555c90ebf5fb357c3d0',
    messagingSenderId: '406076684401',
    projectId: 'solo-simkung',
    storageBucket: 'solo-simkung.firebasestorage.app',
  );
}
