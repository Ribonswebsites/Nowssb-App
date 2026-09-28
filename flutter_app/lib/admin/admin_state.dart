/// Who is an admin, decided by the server — never by a flag on the phone.
///
/// Two server-side marks count, the same two the security rules accept:
///   * a document at `admins/{uid}` (what the web studio already uses), or
///   * a custom claim `admin: true` on the sign-in token, set with the
///     Admin SDK (tools/firebase/mark-admin.sh).
///
/// This class only decides what the app SHOWS. What the account can actually
/// WRITE is decided by firestore.rules and storage.rules, which check the
/// same two marks. Hiding a button is a courtesy; the rules are the lock.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firebase.dart';

class AdminState extends ChangeNotifier {
  AdminState._();
  static final AdminState instance = AdminState._();

  bool _isAdmin = false;
  String? _uid;
  String? _email;
  String _how = '';
  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _doc;

  bool get isAdmin => _isAdmin;
  String? get uid => _uid;
  String? get email => _email;

  /// 'admins list', 'sign-in claim' or both — shown on the admin home.
  String get how => _how;

  void start() {
    if (!NwsbFirebase.ready || _auth != null) return;
    _auth = FirebaseAuth.instance.idTokenChanges().listen(_onUser);
  }

  Future<void> _onUser(User? user) async {
    await _doc?.cancel();
    _doc = null;
    _uid = user?.uid;
    _email = user?.email;
    if (user == null) {
      _set(false, '');
      return;
    }
    var claim = false;
    try {
      final token = await user.getIdTokenResult();
      claim = token.claims?['admin'] == true;
    } catch (_) {}
    _doc = FirebaseFirestore.instance
        .doc('admins/${user.uid}')
        .snapshots()
        .listen((snap) {
      final listed = snap.exists;
      _set(
        listed || claim,
        [if (listed) 'admins list', if (claim) 'sign-in claim'].join(' + '),
      );
    }, onError: (_) {
      // The rules refuse the read for anyone who is not on the list.
      _set(claim, claim ? 'sign-in claim' : '');
    });
  }

  void _set(bool v, String how) {
    if (v == _isAdmin && how == _how) return;
    _isAdmin = v;
    _how = how;
    if (!v) EditMode.instance._reset();
    notifyListeners();
  }
}

/// The live template editor's switches. Both are meaningless unless
/// [AdminState.isAdmin] is true, and both reset when it stops being true.
class EditMode extends ChangeNotifier {
  EditMode._();
  static final EditMode instance = EditMode._();

  static const _kFab = 'nwsb_admin_edit_fab';

  bool _on = false;
  bool _fab = true;

  /// Pencil badges on every editable element of the live screen.
  bool get on => _on && AdminState.instance.isAdmin;

  /// The floating "Edit layout" button over the app.
  bool get fabVisible => _fab && AdminState.instance.isAdmin;
  bool get fabPreference => _fab;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fab = p.getBool(_kFab) ?? true;
    } catch (_) {}
  }

  void toggle() => setOn(!_on);

  void setOn(bool v) {
    if (v && !AdminState.instance.isAdmin) return;
    _on = v;
    notifyListeners();
  }

  Future<void> setFab(bool v) async {
    _fab = v;
    if (!v) _on = false;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kFab, v);
    } catch (_) {}
  }

  void _reset() {
    if (!_on) return;
    _on = false;
    notifyListeners();
  }
}
