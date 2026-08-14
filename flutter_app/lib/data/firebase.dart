/// Firebase, made optional.
///
/// The website's Firebase config is for a WEB app. An Android build needs its
/// own app registered in the same project (nowssb-34f1b) and its own
/// `google-services.json` — that file cannot be written from here, it comes
/// out of the Firebase console, and until it exists this app has no Firebase
/// to talk to.
///
/// That must not be a crash, and it must not be a blank app. The content
/// contract already has two local stages before Firestore — what ships, and
/// the last copy seen — so an app with no Firebase is simply an app that
/// shows the words it shipped with and does not receive published edits. It
/// runs, it looks right, and it gets live content the moment the file lands.
///
/// [ready] is what the rest of the app asks. Nothing calls Firestore without
/// checking it.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class NwsbFirebase {
  NwsbFirebase._();

  static bool _ready = false;
  static String? _why;

  /// True only if Firebase actually came up. Guard every Firestore, Auth and
  /// Messaging call on this.
  static bool get ready => _ready;

  /// Why it did not, for the diagnostics screen. Null when it did.
  static String? get unavailableReason => _why;

  /// Never throws. A missing google-services.json, a project that refuses,
  /// no network on first run — all of them land here as `ready == false`.
  static Future<void> start() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      _ready = false;
      _why = '$e';
      debugPrint(
        'NowssB: running without Firebase — bundled content only.\n'
        '  $e\n'
        '  Add android/app/google-services.json from the Firebase console '
        '(project nowssb-34f1b) to switch live content on.',
      );
    }
  }
}
