import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Generated-like placeholder. Replace with the output of `flutterfire configure`
/// or fill the values manually before shipping.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions sind nur für Android und iOS hinterlegt.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCb97pMDvmzpNeqItwok0WQMrN5KTCyV08',
    appId: '1:691523602914:android:b2bff2a89ed2d1620f11bb',
    messagingSenderId: '691523602914',
    projectId: 'reallifemanhunt-8d625',
    storageBucket: 'reallifemanhunt-8d625.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCH4m6psp8hitZQIvYngsi7MU0gbBJTFS0',
    appId: '1:691523602914:ios:97a838f47ce58ca90f11bb',
    messagingSenderId: '691523602914',
    projectId: 'reallifemanhunt-8d625',
    storageBucket: 'reallifemanhunt-8d625.firebasestorage.app',
    iosBundleId: 'cloud.tonhaeuser.manhunt',
  );
}