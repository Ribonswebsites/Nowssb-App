/// Firebase bootstrap for the NowssB web and Android clients.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class NwsbFirebase {
  NwsbFirebase._();

  static bool _ready = false;
  static String? _why;

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyBly5XnqNnpVom11thjlvT5q_BfxNJBfgQ',
    appId: '1:1024709686012:web:20d425060043141a0b5d79',
    messagingSenderId: '1024709686012',
    projectId: 'nowssb-34f1b',
    authDomain: 'nowssb.com',
    storageBucket: 'nowssb-34f1b.firebasestorage.app',
    measurementId: 'G-KNGQK10PHJ',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyD3r4HfV5ofHzWaQ-tfWvjGbsJAoXupbHo',
    appId: '1:1024709686012:android:a780fb4ab2bd46e90b5d79',
    messagingSenderId: '1024709686012',
    projectId: 'nowssb-34f1b',
    storageBucket: 'nowssb-34f1b.firebasestorage.app',
    authDomain: 'nowssb-34f1b.firebaseapp.com',
  );

  /// True only when Firebase actually initialized for this platform.
  static bool get ready => _ready;

  /// Human-readable initialization failure for diagnostics screens and logs.
  static String? get unavailableReason => _why;

  static FirebaseOptions get options => kIsWeb ? _web : _android;

  /// Initializes Firebase with explicit options so the app works even before a
  /// generated firebase_options.dart or Android Gradle project is present.
  /// Never throws during launch: offline/local content remains available, but
  /// the login screen reports the real reason instead of pretending to work.
  static Future<void> start() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      _ready = true;
      _why = null;
    } catch (error) {
      _ready = false;
      _why = '$error';
      debugPrint('NowssB Firebase initialization failed: $error');
    }
  }
}
