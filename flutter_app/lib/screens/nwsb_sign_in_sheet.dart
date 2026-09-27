/// The same Google, email, and phone sign-in the welcome screen uses.
/// Pushed over the current page so a successful sign-in returns here.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firebase.dart';
import '../widgets/login_gallery.dart';
import '../widgets/nwsb_icon.dart';

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
  final _phone = TextEditingController();
  final _sms = TextEditingController();
  bool _busy = false;
  bool _create = false;
  bool _showEmail = false;
  bool _showPhone = false;
  String? _error;
  String? _verificationId;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _sms.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!NwsbFirebase.ready) throw 'Firebase is not ready in this build.';
      await action();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LoginGallery(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const NwsbIcon(NwsbMarks.house, color: Colors.white),
                ),
              ),
              const Text(
                'Sign in to NowssB',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'You come straight back to this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
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
                        }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE8D5A3),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_busy ? 'Please wait' : 'Continue with Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() {
                  _showEmail = !_showEmail;
                  _showPhone = false;
                  _error = null;
                }),
                child: const Text('Continue with Email'),
              ),
              if (_showEmail) ...[
                const SizedBox(height: 8),
                _field(_email, 'Email'),
                const SizedBox(height: 8),
                _field(_password, 'Password', obscure: true),
                Row(
                  children: [
                    Checkbox(value: _create, onChanged: (v) => setState(() => _create = v == true)),
                    const Text('Create account', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final email = _email.text.trim();
                            final password = _password.text;
                            if (email.isEmpty || password.length < 6) {
                              throw 'Enter a valid email and a password of at least 6 characters.';
                            }
                            if (_create) {
                              await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
                            } else {
                              await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
                            }
                          }),
                  child: Text(_create ? 'Create account' : 'Sign in'),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => setState(() {
                  _showPhone = !_showPhone;
                  _showEmail = false;
                  _error = null;
                }),
                child: const Text('Continue with Phone'),
              ),
              if (_showPhone) ...[
                const SizedBox(height: 8),
                _field(_phone, 'Phone with country code'),
                if (_verificationId != null) ...[
                  const SizedBox(height: 8),
                  _field(_sms, 'SMS code'),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            if (_verificationId == null) {
                              final phone = _phone.text.trim();
                              if (!RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
                                throw 'Use the full phone number with country code, for example +919876543210.';
                              }
                              await FirebaseAuth.instance.verifyPhoneNumber(
                                phoneNumber: phone,
                                verificationCompleted: (credential) async {
                                  await FirebaseAuth.instance.signInWithCredential(credential);
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop(true);
                                },
                                verificationFailed: (error) {
                                  if (mounted) setState(() => _error = _message(error));
                                },
                                codeSent: (verificationId, _) {
                                  if (mounted) setState(() => _verificationId = verificationId);
                                },
                                codeAutoRetrievalTimeout: (verificationId) {
                                  _verificationId = verificationId;
                                },
                              );
                              return;
                            }
                            final code = _sms.text.trim();
                            if (code.length < 4) throw 'Enter the verification code from SMS.';
                            await FirebaseAuth.instance.signInWithCredential(
                              PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: code),
                            );
                          }),
                  child: Text(_verificationId == null ? 'Send code' : 'Verify code'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFB4AB), height: 1.35)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
      ),
    );
  }
}
