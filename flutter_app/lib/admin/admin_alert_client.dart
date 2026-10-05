/// Tells the admins about something this member just did (a word request,
/// a brand-new account). POST /api/admin-alert with the member's own sign-in;
/// the server checks it against Firestore, writes adminAlerts and buzzes the
/// admins' phones. Fire-and-forget: never throws, never blocks the member.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/firebase.dart';

void tellAdmins(String kind, [String id = '']) {
  unawaited(_tell(kind, id));
}

Future<void> _tell(String kind, String id) async {
  try {
    if (!NwsbFirebase.ready) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return;
    final token = await u.getIdToken();
    if (token == null) return;
    await http
        .post(
          Uri.parse('https://nowssb.com/api/admin-alert'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({'kind': kind, 'id': id, 'platform': Platform.isIOS ? 'iOS' : 'Android'}),
        )
        .timeout(const Duration(seconds: 15));
  } catch (_) {}
}
