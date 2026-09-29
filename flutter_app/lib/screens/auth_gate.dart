/// Native Flutter authentication gate with the same phone-and-film Welcome
/// composition used by the WebView login screen.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/earn_wallet.dart';
import '../data/firebase.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import '../widgets/app_thinking_loader.dart';
import '../widgets/login_stage.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  static final reopen = ValueNotifier<int>(0);

  static void askForAccount() {
    reopen.value++;
  }

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  static const _googleWebClientId =
      '1024709686012-h1h9glk84uti9cbqpht5d09igdqb8pgu.apps.googleusercontent.com';
  final _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _googleWebClientId,
  );

  bool _busy = false;
  bool _createAccount = false;
  bool _guest = false;
  bool _remember = true;
  bool _obscure = true;
  String? _rewardedUid;
  String? _error;
  String? _notice;
  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    AuthGate.reopen.addListener(_leaveGuest);
    _loadRemember();
  }

  Future<void> _loadRemember() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('nwsb.rememberMe') ?? true;
    if (mounted) setState(() => _remember = remember);
    if (!remember && NwsbFirebase.ready) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _saveRemember() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nwsb.rememberMe', _remember);
  }

  void _leaveGuest() {
    if (mounted) setState(() => _guest = false);
  }

  @override
  void dispose() {
    AuthGate.reopen.removeListener(_leaveGuest);
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    await _saveRemember();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const _AuthMessage(
          'Sign-in is taking too long. Check your connection and try again.',
        ),
      );
    } on _AuthMessage catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() => _run(() async {
        if (!NwsbFirebase.ready) {
          throw const _AuthMessage(
            'Google sign-in is not configured in this build. Use email or continue as a guest.',
          );
        }
        try {
          final account = await _google.signIn();
          if (account == null) return;
          final credentials = await account.authentication;
          if (credentials.idToken == null && credentials.accessToken == null) {
            throw const _AuthMessage(
              'Google did not return a credential. Check the Android app registration and signing certificate in Firebase.',
            );
          }
          await FirebaseAuth.instance.signInWithCredential(
            GoogleAuthProvider.credential(
              accessToken: credentials.accessToken,
              idToken: credentials.idToken,
            ),
          );
        } on PlatformException catch (error) {
          final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
          final blocked = details.contains('10') ||
              details.contains('12500') ||
              details.contains('developer_error') ||
              details.contains('sign_in_failed');
          if (!blocked) rethrow;
          // The plugin path fails when this APK's certificate is not the one
          // Firebase has. The provider flow uses the same project and still
          // completes when that client can sign in through the browser.
          final provider = GoogleAuthProvider()..addScope('email');
          await FirebaseAuth.instance.signInWithProvider(provider);
        }
      });

  Future<void> _emailLogin() => _run(() async {
        if (!NwsbFirebase.ready) {
          throw const _AuthMessage(
            'Email sign-in is unavailable until Firebase is configured in this build.',
          );
        }
        final email = _email.text.trim();
        final password = _password.text;
        if (email.isEmpty || password.length < 6) {
          throw const _AuthMessage(
            'Enter a valid email and a password of at least 6 characters.',
          );
        }
        if (_createAccount) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      });

  Future<void> _sendPhoneCode() => _run(() async {
        if (!NwsbFirebase.ready) {
          throw const _AuthMessage(
            'Phone sign-in is unavailable until Firebase is configured in this build.',
          );
        }
        final phone = _phone.text.trim();
        if (!RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
          throw const _AuthMessage(
            'Use the full phone number with country code, for example +919876543210.',
          );
        }
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          forceResendingToken: _resendToken,
          verificationCompleted: (credential) async {
            try {
              await FirebaseAuth.instance.signInWithCredential(credential);
            } catch (error) {
              if (mounted) setState(() => _error = _friendlyAuthError(error));
            }
          },
          verificationFailed: (error) {
            if (mounted) setState(() => _error = _friendlyAuthError(error));
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _error = null;
              _password.clear();
              _notice = 'Code sent. Enter it and tap Verify.';
            });
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationId = verificationId;
          },
        );
      });

  Future<void> _verifyPhoneCode() => _run(() async {
        final verificationId = _verificationId;
        final code = _password.text.trim();
        if (verificationId == null) {
          throw const _AuthMessage('Request a verification code first.');
        }
        if (code.length < 4) {
          throw const _AuthMessage('Enter the verification code from SMS.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      });

  String _friendlyAuthError(Object error) {
    final code = error is FirebaseAuthException ? error.code : '';
    if (error is PlatformException) {
      // GoogleSignIn reports Android OAuth misconfiguration as the opaque
      // platform error `sign_in_failed` (usually status 10/12500). It is not
      // a connectivity failure and the old generic copy sent users in the
      // wrong direction on every device.
      final details = '${error.code} ${error.message ?? ''}'.toLowerCase();
      if (details.contains('10') ||
          details.contains('12500') ||
          details.contains('developer_error') ||
          details.contains('sign_in_failed')) {
        return 'Google sign-in is not authorised for this Android build. '
            'Add package com.nowssb.app and this build’s SHA-1/SHA-256 '
            'certificates to the NowssB Firebase Android app.';
      }
      return error.message ?? 'Google sign-in could not be completed.';
    }
    switch (code) {
      case 'network-request-failed':
        return 'No network connection is available. Reconnect and try again.';
      case 'invalid-credential':
        return 'The sign-in details are not valid. Check them and try again.';
      case 'wrong-password':
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
      case 'app-not-authorized':
      case 'invalid-api-key':
        return 'This build is not authorised for Firebase sign-in. Check its Android registration and SHA certificate.';
      case 'captcha-check-failed':
        return 'The security check failed. Make sure Google Play services and your network are available.';
      case 'quota-exceeded':
        return 'SMS sign-in is temporarily unavailable. Try email sign-in instead.';
      default:
        if (error is _AuthMessage) return error.message;
        if (error is FirebaseAuthException) {
          return error.message ?? 'Sign-in could not be completed.';
        }
        return 'Sign-in could not be completed. Check your connection and try again.';
    }
  }

  Future<void> _submit() async {
    final raw = _email.text.trim();
    if (!raw.contains('@') && _verificationId != null) {
      await _verifyPhoneCode();
      return;
    }
    if (raw.contains('@')) {
      await _emailLogin();
      return;
    }
    _phone.text = raw;
    await _sendPhoneCode();
  }

  Future<void> _appleLogin() => _run(() async {
        if (!NwsbFirebase.ready) {
          throw const _AuthMessage(
            'Apple sign-in is not configured in this build.',
          );
        }
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        await FirebaseAuth.instance.signInWithProvider(provider);
      });

  Future<void> _forgot() => _run(() async {
        if (!NwsbFirebase.ready) {
          throw const _AuthMessage(
            'Password reset is unavailable until Firebase is configured in this build.',
          );
        }
        final email = _email.text.trim();
        if (!email.contains('@')) {
          throw const _AuthMessage('Enter the email on your account.');
        }
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          setState(() => _notice = 'Reset link sent. Check your email.');
        }
      });

  Widget _buildAuthScreen({String? unavailable}) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: LoginStage(
        id: _email,
        secret: _password,
        busy: _busy,
        obscure: _obscure,
        remember: _remember,
        createAccount: _createAccount,
        codeSent: _verificationId != null && !_email.text.contains('@'),
        error: _error ?? unavailable,
        notice: _notice,
        onSubmit: _submit,
        onGoogle: _googleLogin,
        onApple: _appleLogin,
        onForgot: _forgot,
        onToggleCreate: () => setState(() {
          _createAccount = !_createAccount;
          _error = null;
          _notice = null;
        }),
        onToggleObscure: () => setState(() => _obscure = !_obscure),
        onToggleRemember: () => setState(() => _remember = !_remember),
        onExplore: _busy ? null : () => setState(() => _guest = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_guest) return widget.child;
    if (!NwsbFirebase.ready) {
      return _buildAuthScreen(
        unavailable:
            'Firebase is not ready in this build. You can still explore without an account.',
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: AppThinkingLoader(
                  label: 'Preparing…', state: OrbState.composing),
            ),
          );
        }
        if (snapshot.hasData) {
          final uid = snapshot.data?.uid;
          if (uid != null && _rewardedUid != uid) {
            _rewardedUid = uid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              EarnWallet.instance.onSignedIn();
            });
          }
          return widget.child;
        }
        return _buildAuthScreen();
      },
    );
  }
}


class _AuthMessage implements Exception {
  const _AuthMessage(this.message);
  final String message;
  @override
  String toString() => message;
}
