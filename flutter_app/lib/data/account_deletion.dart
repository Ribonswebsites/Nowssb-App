/// In-app account deletion (Google Play policy) and the profile visibility
/// switch the settings page applies for real.
///
/// Deletion: the server endpoint (/api/account/delete, needs
/// FIREBASE_SERVICE_ACCOUNT) removes the Firestore data and the Firebase
/// Auth account. If the server cannot (not configured / offline), the app
/// deletes what firestore.rules let a person delete themselves, files
/// accountDeletionRequests/{uid} so an admin finishes the Auth part, and
/// signs out. Either way all local data on this phone is wiped.
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';

class AccountDeletionResult {
  const AccountDeletionResult({required this.ok, required this.queued, required this.message, this.needsSignIn = false});
  final bool ok;

  /// The server wants a fresh sign-in (older than 5 minutes) before deleting.
  final bool needsSignIn;

  /// True when the Auth account is waiting for an admin (request filed).
  final bool queued;
  final String message;
}

class AccountDeletion {
  AccountDeletion._();

  static const endpoint = 'https://nowssb.com/api/account/delete';

  /// Sub-collections under users/{uid} that the owner may delete (rules).
  static const _ownSubs = [
    'goals', 'tasks', 'conversations', 'coachConversations', 'wishlist', 'notifications', 'inbox',
  ];

  static Future<AccountDeletionResult> deleteMyAccount({String reason = ''}) async {
    if (!NwsbFirebase.ready) {
      return const AccountDeletionResult(ok: false, queued: false, message: 'Sign in first.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return const AccountDeletionResult(ok: false, queued: false, message: 'Sign in first.');
    }
    final uid = user.uid;
    var serverDone = false;
    try {
      final token = await user.getIdToken(true);
      final r = await http
          .post(Uri.parse(endpoint), headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          }, body: jsonEncode({'reason': reason}))
          .timeout(const Duration(seconds: 40));
      serverDone = r.statusCode == 200;
      if (r.statusCode == 401 && r.body.contains('requires-recent-login')) {
        // Nothing is deleted on a stale sign-in, not even the fallback.
        return const AccountDeletionResult(
          ok: false,
          queued: false,
          needsSignIn: true,
          message: 'For your safety, sign out and sign in again, then delete the account. Nothing was deleted.',
        );
      }
      if (!serverDone) debugPrint('NowssB delete account: server ${r.statusCode}');
    } catch (e) {
      debugPrint('NowssB delete account: $e');
    }

    if (!serverDone) {
      final db = FirebaseFirestore.instance;
      try {
        await db.doc('accountDeletionRequests/$uid').set({
          'uid': uid,
          'email': user.email ?? '',
          'reason': reason.length > 300 ? reason.substring(0, 300) : reason,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });
      } catch (e) {
        debugPrint('NowssB deletion request: $e');
        return const AccountDeletionResult(
          ok: false,
          queued: false,
          message: 'Could not reach NowssB. Check your connection and try again, or email nowssbonline@gmail.com.',
        );
      }
      for (final sub in _ownSubs) {
        try {
          final snap = await db.collection('users/$uid/$sub').limit(300).get();
          for (final d in snap.docs) {
            if (sub == 'coachConversations') {
              // Coach messages live one level deeper.
              final msgs = await d.reference.collection('messages').limit(500).get();
              for (final m in msgs.docs) {
                await m.reference.delete().catchError((_) {});
              }
            }
            await d.reference.delete().catchError((_) {});
          }
        } catch (_) {}
      }
      for (final path in ['publicProfiles/$uid', 'users/$uid']) {
        try {
          await db.doc(path).delete();
        } catch (_) {}
      }
    }

    try {
      final p = await SharedPreferences.getInstance();
      await p.clear();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    return serverDone
        ? const AccountDeletionResult(ok: true, queued: false, message: 'Your NowssB account and its data are deleted.')
        : const AccountDeletionResult(
            ok: true,
            queued: true,
            // Honest about the fallback: only what the app may delete itself
            // is gone now; the team removes the rest with the sign-in.
            message: 'Your profile, coach chats, wishlist and notifications are deleted. Your coins, purchases, cards and the sign-in itself are removed by the team within 30 days (request filed). You are signed out.',
          );
  }
}

/// publicProfiles/{uid}.profileVisibility — what the website's Discover and
/// public profile pages read.
class ProfileVisibility {
  ProfileVisibility._();

  static Future<bool?> load() async {
    if (!NwsbFirebase.ready) return null;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    try {
      final d = await FirebaseFirestore.instance.doc('publicProfiles/${u.uid}').get();
      final v = d.data()?['profileVisibility'];
      return v == null ? null : v == 'public';
    } catch (_) {
      return null;
    }
  }

  static Future<bool> set(bool public) async {
    if (!NwsbFirebase.ready) return false;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return false;
    try {
      await FirebaseFirestore.instance.doc('publicProfiles/${u.uid}').set({
        'uid': u.uid,
        'profileVisibility': public ? 'public' : 'private',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('NowssB visibility: $e');
      return false;
    }
  }
}
