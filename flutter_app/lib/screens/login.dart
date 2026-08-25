/// Branded NowssB sign-in for Google, email/password, and phone OTP.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firebase.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../shell/nav_shell.dart';
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
      'auth/invalid-credential' ||
      'auth/wrong-password' =>
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
      _setError(
          'NowssB sign-in is still starting. Please try again in a moment.');
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
      setState(
          () => _error = 'Enter an email and password to create an account.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Choose a password with at least 6 characters.');
      return;
    }
    await _runAuth(() async {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
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
                  colors: [Color(0x30060C18), Color(0xE8060C18)],
                  stops: [0, .78],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight = (constraints.maxHeight - 32)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final brandToFormGap =
                    (constraints.maxHeight * .14).clamp(42.0, 132.0).toDouble();
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.arrow_back,
                                color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _LoginBrandLockup(),
                        SizedBox(height: brandToFormGap),
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to keep your streak, your words and your path.',
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xC4FFFFFF),
                              height: 1.45),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: i == 2 ? 0 : 4),
                                  child: GestureDetector(
                                    onTap: _busy
                                        ? null
                                        : () => setState(() {
                                              _tab = i;
                                              _clearError();
                                            }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      height: 44,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _tab == i
                                            ? Colors.white
                                            : const Color(0x241B2230),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                            color: const Color(0x22FFFFFF)),
                                      ),
                                      child: Text(
                                        ['Google', 'Email', 'Phone'][i],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _tab == i
                                              ? NwsbColors.ink
                                              : Colors.white,
                                        ),
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
                            label:
                                _busy ? 'Connecting…' : 'Continue with Google',
                            leading: const _GoogleGlyph(),
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
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
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
                            child: const Text('Create a new NowssB account',
                                style: TextStyle(color: NwsbColors.gold)),
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
                              decoration:
                                  _inputDecoration('6-digit verification code'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _AuthButton(
                            label: _busy
                                ? 'Sending…'
                                : phoneCodeSent
                                    ? 'Verify code'
                                    : 'Send code',
                            onTap: _busy
                                ? null
                                : (phoneCodeSent
                                    ? _verifyPhoneCode
                                    : _sendPhoneCode),
                          ),
                          if (phoneCodeSent)
                            TextButton(
                              onPressed: _busy ? null : _sendPhoneCode,
                              child: const Text('Send a new code',
                                  style: TextStyle(color: NwsbColors.gold)),
                            ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFFFB4AB),
                                fontSize: 12,
                                height: 1.35),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                          builder: (_) => const NavShell()),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              foregroundColor: NwsbColors.gold,
                            ),
                            child: const Text(
                              'Explore without account →',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Center(
                          child: Text(
                            'Your account syncs securely across your NowssB devices.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Color(0x72FFFFFF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBrandLockup extends StatelessWidget {
  const _LoginBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/media/image/logo-disc-8b052034.webp',
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(width: 68, height: 68),
          ),
        ),
        const SizedBox(width: 16),
        Container(width: 1, height: 52, color: const Color(0x66FFFFFF)),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NowssB',
              style: TextStyle(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            SizedBox(height: 9),
            Text(
              'BY NOWSBANSIU',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xB3FFFFFF)),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
          fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({required this.label, required this.onTap, this.leading});

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .55,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: leading == null
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
