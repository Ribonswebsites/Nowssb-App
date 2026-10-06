/// The same Google, email, and phone sign-in the welcome screen uses.
/// Pushed over the current page so a successful sign-in returns here.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_errors.dart';
import '../data/firebase.dart';
import '../data/remember_me.dart';
import '../data/phone_notifications.dart';
import '../widgets/login_stage.dart';

class NwsbSignInPage extends StatefulWidget {
  const NwsbSignInPage({super.key});

  static Future<bool> open(BuildContext context) {
    if (NwsbFirebase.ready && FirebaseAuth.instance.currentUser != null) {
      return Future<bool>.value(true);
    }
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const NwsbSignInPage(),
      ),
    ).then((value) => value == true && FirebaseAuth.instance.currentUser != null);
  }

  @override
  State<NwsbSignInPage> createState() => _NwsbSignInPageState();
}

class _NwsbSignInPageState extends State<NwsbSignInPage> {
  static const _googleWebClientId =
      '1024709686012-h1h9glk84uti9cbqpht5d09igdqb8pgu.apps.googleusercontent.com';

  final _google = GoogleSignIn(scopes: const ['email'], serverClientId: _googleWebClientId);
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _create = false;
  bool _obscure = true;
  bool _remember = true;
  String? _error;
  String? _notice;
  String? _verificationId;
  // The number the current code was sent to; editing the number drops it.
  String? _codeFor;

  @override
  void dispose() {
    _email.removeListener(_numberChanged);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _numberChanged() {
    if (_verificationId == null || _email.text.trim() == _codeFor) return;
    setState(() {
      _verificationId = null;
      _codeFor = null;
      _notice = null;
      _password.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _email.addListener(_numberChanged);
    RememberMe.read().then((remember) {
      if (!mounted) return;
      setState(() => _remember = remember);
    });
  }

  Future<void> _saveRemember() => RememberMe.write(_remember);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    await _saveRemember();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (!NwsbFirebase.ready) throw 'Firebase is not ready in this build.';
      await action();
      if (FirebaseAuth.instance.currentUser != null) {
        PhoneNotifications.instance.armSession();
      }
      if (mounted && FirebaseAuth.instance.currentUser != null) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) {
    if (error is PlatformException) {
      if (isGoogleConfigError(error)) return googleConfigMessage(error);
      return error.message ?? 'Google sign-in could not be completed.';
    }
    final code = error is FirebaseAuthException ? error.code : '';
    switch (code) {
      case 'network-request-failed':
        return 'No network connection is available. Reconnect and try again.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password. Try again or create an account.';
      case 'user-not-found':
        return 'No account was found for this email.';
      case 'email-already-in-use':
        return 'This email is already registered. Sign in instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-phone-number':
        return 'Enter a valid phone number with its country code.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a little and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      default:
        if (error is FirebaseAuthException && (error.message ?? '').isNotEmpty) {
          return error.message!;
        }
        if (error is String) return error;
        return 'Sign-in could not be completed. Check your connection and try again.';
    }
  }


  Future<void> _submit() => _run(() async {
        final raw = _email.text.trim();
        if (!raw.contains('@') && _verificationId != null && raw == _codeFor) {
          final code = _password.text.trim();
          if (code.length < 4) throw 'Enter the verification code from SMS.';
          await FirebaseAuth.instance.signInWithCredential(
            PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code),
          );
          return;
        }
        if (raw.contains('@')) {
          final password = _password.text;
          if (raw.isEmpty || password.length < 6) {
            throw 'Enter a valid email and a password of at least 6 characters.';
          }
          if (_create) {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(email: raw, password: password);
          } else {
            await FirebaseAuth.instance.signInWithEmailAndPassword(email: raw, password: password);
          }
          return;
        }
        if (!RegExp(r'^\+\d{8,15}$').hasMatch(raw)) {
          throw 'Enter an email, or a phone number with its country code.';
        }
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: raw,
          verificationCompleted: (credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            Navigator.of(context).pop(true);
          },
          verificationFailed: (error) {
            if (mounted) setState(() => _error = _message(error));
          },
          codeSent: (verificationId, _) {
            if (!mounted || _email.text.trim() != raw) return;
            setState(() {
              _verificationId = verificationId;
              _codeFor = raw;
              _password.clear();
              _notice = 'Code sent. Enter it and tap Verify.';
            });
          },
          codeAutoRetrievalTimeout: (verificationId) {
            if (_codeFor == raw) _verificationId = verificationId;
          },
        );
      });

  Future<void> _apple() => _run(() async {
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        await FirebaseAuth.instance.signInWithProvider(provider);
      });

  Future<void> _forgot() => _run(() async {
        final email = _email.text.trim();
        if (!email.contains('@')) throw 'Enter the email on your account.';
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) setState(() => _notice = 'Reset link sent. Check your email.');
      });

  Future<void> _googleLogin() => _run(() async {
        try {
          try {
            await _google.signOut();
          } catch (_) {}
          try {
            await _google.disconnect();
          } catch (_) {}
          final account = await _google.signIn();
          if (account == null) return;
          final credentials = await account.authentication;
          if (credentials.idToken == null && credentials.accessToken == null) {
            throw 'Google did not return a credential.';
          }
          await FirebaseAuth.instance.signInWithCredential(
            GoogleAuthProvider.credential(
              accessToken: credentials.accessToken,
              idToken: credentials.idToken,
            ),
          );
        } on PlatformException catch (error) {
          if (!isGoogleConfigError(error)) rethrow;
          final provider = GoogleAuthProvider()..addScope('email');
          await FirebaseAuth.instance.signInWithProvider(provider);
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: LoginStage(
        id: _email,
        secret: _password,
        busy: _busy,
        obscure: _obscure,
        remember: _remember,
        createAccount: _create,
        codeSent: _verificationId != null && !_email.text.contains('@'),
        error: _error,
        notice: _notice,
        onClose: () => Navigator.of(context).pop(false),
        onSubmit: _submit,
        onGoogle: _googleLogin,
        onApple: _apple,
        onForgot: _forgot,
        onToggleCreate: () => setState(() {
          _create = !_create;
          _error = null;
          _notice = null;
        }),
        onToggleObscure: () => setState(() => _obscure = !_obscure),
        onToggleRemember: () => setState(() => _remember = !_remember),
      ),
    );
  }
}
