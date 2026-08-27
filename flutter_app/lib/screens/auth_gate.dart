/// Native Flutter authentication gate with the same phone-and-film Welcome
/// composition used by the WebView login screen.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';

import '../data/firebase.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _phoneAsset = 'assets/video/login-phone.mp4';
  static const _posterAsset = 'assets/video/login-phone-poster.webp';

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _smsCode = TextEditingController();
  static const _googleWebClientId = '1024709686012-h1h9glk84uti9cbqpht5d09igdqb8pgu.apps.googleusercontent.com';
  final _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: _googleWebClientId,
  );

  late final VideoPlayerController _phoneVideo;
  bool _videoReady = false;
  bool _busy = false;
  bool _createAccount = false;
  bool _showEmail = false;
  bool _showPhone = false;
  bool _guest = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _phoneVideo = VideoPlayerController.asset(_phoneAsset);
    _preparePhoneVideo();
  }

  Future<void> _preparePhoneVideo() async {
    try {
      await _phoneVideo.initialize();
      await _phoneVideo.setLooping(true);
      await _phoneVideo.setVolume(0);
      await _phoneVideo.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // The poster keeps the auth screen useful if a device cannot decode it.
    }
  }

  @override
  void dispose() {
    _phoneVideo.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _smsCode.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
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
            });
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationId = verificationId;
          },
        );
      });

  Future<void> _verifyPhoneCode() => _run(() async {
        final verificationId = _verificationId;
        final code = _smsCode.text.trim();
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

  Widget _buildAuthScreen({String? unavailable}) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight * .96;
          final width = math.min(maxWidth, maxHeight * 720 / 1264);
          final height = width * 1264 / 720;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: LayoutBuilder(
                builder: (context, phoneConstraints) {
                  final w = phoneConstraints.maxWidth;
                  final h = phoneConstraints.maxHeight;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _phoneFilm(),
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(
                          w * .18889,
                          h * .1503,
                          w * .628,
                          h * .7722,
                        ),
                        child: _glassContent(unavailable: unavailable),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _phoneFilm() {
    if (_videoReady) {
      return VideoPlayer(_phoneVideo);
    }
    return Image.asset(
      _posterAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  }

  Widget _glassContent({String? unavailable}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = math.max(0, constraints.maxHeight - 24);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _brandHeader(),
                  SizedBox(height: math.max(28, constraints.maxHeight * .095)),
                  const Text(
                    'Welcome',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Sign in or create your account',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  _googleButton(),
                  _orDivider(),
                  _methodButton(
                    icon: Icons.email_outlined,
                    label: 'Continue with Email',
                    open: _showEmail,
                    onTap: () => setState(() {
                      _showEmail = !_showEmail;
                      if (_showEmail) _showPhone = false;
                      _error = null;
                    }),
                  ),
                  if (_showEmail) _emailForm(),
                  const SizedBox(height: 10),
                  _methodButton(
                    icon: Icons.phone_iphone_outlined,
                    label: 'Continue with Phone',
                    open: _showPhone,
                    onTap: () => setState(() {
                      _showPhone = !_showPhone;
                      if (_showPhone) _showEmail = false;
                      _error = null;
                    }),
                  ),
                  if (_showPhone) _phoneForm(),
                  if (unavailable != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      unavailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 11, height: 1.35),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 11, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _guest = true),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE8D5A3)),
                    child: const Text('Explore without account →'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/icons/logo-disc.webp',
            width: 46,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(width: 46, height: 46),
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 13),
          color: Colors.white24,
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Nowss', style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: 'B', style: TextStyle(fontWeight: FontWeight.w300, color: Colors.white70)),
                ],
              ),
              style: TextStyle(color: Colors.white, fontSize: 21, height: 1.05),
            ),
            SizedBox(height: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'BY ', style: TextStyle(fontWeight: FontWeight.w300)),
                  TextSpan(text: 'NOWSB', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'ANSIU', style: TextStyle(fontWeight: FontWeight.w300)),
                ],
              ),
              style: TextStyle(color: Colors.white54, fontSize: 8.5, letterSpacing: 1.7),
            ),
          ],
        ),
      ],
    );
  }

  Widget _googleButton() {
    return _whiteButton(
      onPressed: _busy ? null : _googleLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GoogleMark(),
          const SizedBox(width: 12),
          const Text('Continue with Google'),
        ],
      ),
    );
  }

  Widget _methodButton({
    required IconData icon,
    required String label,
    required bool open,
    required VoidCallback onTap,
  }) {
    return _whiteButton(
      onPressed: _busy ? null : onTap,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
        ],
      ),
    );
  }

  Widget _whiteButton({required VoidCallback? onPressed, required Widget child}) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white54,
          disabledForegroundColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        child: child,
      ),
    );
  }

  Widget _orDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white24, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2.4)),
          ),
          Expanded(child: Divider(color: Colors.white24, height: 1)),
        ],
      ),
    );
  }

  Widget _emailForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          _field(_email, 'Email address', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _field(_password, 'Password', obscure: true),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _emailLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8D5A3),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(_createAccount ? 'Create account' : 'Sign in with email'),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _createAccount = !_createAccount),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: Text(_createAccount ? 'I already have an account' : 'Create a new account'),
          ),
        ],
      ),
    );
  }

  Widget _phoneForm() {
    final hasCode = _verificationId != null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          _field(_phone, 'Phone number with country code', keyboard: TextInputType.phone),
          if (hasCode) ...[
            const SizedBox(height: 10),
            _field(_smsCode, 'SMS verification code', keyboard: TextInputType.number),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : (hasCode ? _verifyPhoneCode : _sendPhoneCode),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8D5A3),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(hasCode ? 'Verify code' : 'Send code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5A3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_guest) return widget.child;
    if (!NwsbFirebase.ready) {
      return _buildAuthScreen(
        unavailable: 'Firebase is not ready in this build. You can still explore without an account.',
      );
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return widget.child;
        return _buildAuthScreen();
      },
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => const Text(
        'G',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
        ),
      );
}

class _AuthMessage implements Exception {
  const _AuthMessage(this.message);
  final String message;
  @override
  String toString() => message;
}
