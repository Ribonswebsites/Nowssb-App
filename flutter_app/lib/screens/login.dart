/// Branded NowssB sign-in for Google, email/password, and phone OTP.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firebase.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  int _tab = 0;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;
  String? _verificationId;
  int? _resendToken;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _setError(Object error) {
    if (!mounted) return;
    final code = error is FirebaseAuthException ? error.code : '';
    final message = switch (code) {
      'auth/invalid-credential' || 'auth/wrong-password' =>
        'That email or password is not correct.',
      'auth/user-not-found' => 'No NowssB account exists for that email yet.',
      'auth/email-already-in-use' =>
        'That email already has a NowssB account. Try signing in.',
      'auth/weak-password' => 'Choose a password with at least 6 characters.',
      'auth/invalid-email' => 'Enter a valid email address.',
      'auth/too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'auth/network-request-failed' =>
        'No network connection. Check your connection and try again.',
      'auth/operation-not-allowed' =>
        'This sign-in method is temporarily unavailable.',
      'auth/invalid-verification-code' =>
        'That verification code is not correct.',
      'auth/invalid-phone-number' => 'Enter a valid phone number.',
      'auth/quota-exceeded' =>
        'SMS sign-in is temporarily limited. Try email or Google instead.',
      _ => 'Sign-in could not be completed. Please try again.',
    };
    setState(() => _error = message);
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    if (_busy) return;
    if (!NwsbFirebase.ready) {
      _setError('NowssB sign-in is still starting. Please try again in a moment.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      // A dismissed Google account picker is not a successful login. Only
      // leave the login route after Firebase has a signed-in user.
      if (_auth.currentUser != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (_auth.currentUser == null) {
        setState(() => _error = 'Sign-in was cancelled.');
      }
    } on FirebaseAuthException catch (error) {
      _setError(error);
    } catch (error) {
      _setError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    await _runAuth(() async {
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      if (account == null) return;
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    });
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    await _runAuth(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    });
  }

  Future<void> _createEmailAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter an email and password to create an account.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Choose a password with at least 6 characters.');
      return;
    }
    await _runAuth(() async {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    });
  }

  String get _phoneNumber {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (raw.startsWith('+')) return raw;
    return '+91$raw';
  }

  Future<void> _sendPhoneCode() async {
    final phone = _phoneNumber;
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid phone number.');
      return;
    }
    if (!NwsbFirebase.ready || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (error) {
          _setError(error);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      verificationFailed: (error) {
        _setError(error);
        if (mounted) setState(() => _busy = false);
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _busy = false;
          _error = null;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        if (mounted) setState(() => _busy = false);
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> _verifyPhoneCode() async {
    final verificationId = _verificationId;
    final code = _codeController.text.trim();
    if (verificationId == null) {
      await _sendPhoneCode();
      return;
    }
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    await _runAuth(() async {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _auth.signInWithCredential(credential);
    });
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x8CFFFFFF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0x1AFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneCodeSent = _verificationId != null;
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/login-phone.mp4',
              priority: ClipPriority.feature,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66060C18), Color(0xE6060C18)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/media/image/logo-disc-8b052034.webp',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'NowssB',
                          style: TextStyle(
                            fontSize: 15,
                            letterSpacing: 4,
                            color: NwsbColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Natural Origin of Word Science',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xB3FFFFFF),
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to keep your streak, your words and your path.',
                    style: TextStyle(fontSize: 14, color: Color(0xB3FFFFFF), height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      for (final (i, label) in ['Google', 'Email', 'Phone'].indexed)
                        Expanded(
                          child: GestureDetector(
                            onTap: _busy
                                ? null
                                : () => setState(() {
                                      _tab = i;
                                      _clearError();
                                    }),
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tab == i ? Colors.white : const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _tab == i ? NwsbColors.ink : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0)
                    _AuthButton(
                      label: _busy ? 'Connecting…' : 'Continue with Google',
                      onTap: _busy ? null : _signInWithGoogle,
                    )
                  else if (_tab == 1) ...[
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearError(),
                      decoration: _inputDecoration('Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => _clearError(),
                      decoration: _inputDecoration(
                        'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0x99FFFFFF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AuthButton(
                      label: _busy ? 'Signing in…' : 'Sign in',
                      onTap: _busy ? null : _signInWithEmail,
                    ),
                    TextButton(
                      onPressed: _busy ? null : _createEmailAccount,
                      child: const Text(
                        'Create a new NowssB account',
                        style: TextStyle(color: NwsbColors.gold),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => _clearError(),
                      decoration: _inputDecoration('+91 98765 43210'),
                    ),
                    if (phoneCodeSent) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: _inputDecoration('6-digit verification code'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _AuthButton(
                      label: _busy
                          ? 'Sending…'
                          : phoneCodeSent
                              ? 'Verify code'
                              : 'Send code',
                      onTap: _busy ? null : (phoneCodeSent ? _verifyPhoneCode : _sendPhoneCode),
                    ),
                    if (phoneCodeSent)
                      TextButton(
                        onPressed: _busy ? null : _sendPhoneCode,
                        child: const Text(
                          'Send a new code',
                          style: TextStyle(color: NwsbColors.gold),
                        ),
                      ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 12, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Your account syncs securely across your NowssB devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .55,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: NwsbColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
