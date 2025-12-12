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
    apiKey: '*',
    appId: '*',
    messagingSenderId: '*',
    projectId: '*',
    storageBucket: '*',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '*',
    appId: '*',
    messagingSenderId: '*',
    projectId: '*',
    storageBucket: '*',
    iosBundleId: '*',
  );
}
