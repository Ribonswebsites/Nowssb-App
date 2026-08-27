/// Native Flutter authentication gate. It deliberately uses no looping video:
/// users always receive either the app, a clear sign-in form, or an error.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firebase.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _google = GoogleSignIn(scopes: const ['email']);
  bool _busy = false;
  bool _createAccount = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const _AuthMessage(
          'Sign-in is taking too long. Please check your connection and try again.',
        ),
      );
    } on _AuthMessage catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign-in could not be completed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleLogin() => _run(() async {
    if (!NwsbFirebase.ready) {
      throw const _AuthMessage('Sign-in is not configured in this build yet. Use a build that includes the Firebase platform configuration.');
    }
    final account = await _google.signIn();
    if (account == null) return;
    final credentials = await account.authentication;
    if (credentials.idToken == null && credentials.accessToken == null) {
      throw const _AuthMessage('Google did not return a sign-in credential. Confirm the app package and signing certificate are registered in Firebase.');
    }
    await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(
      accessToken: credentials.accessToken,
      idToken: credentials.idToken,
    ));
  });

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'No network connection is available. Reconnect and try again.';
      case 'invalid-credential':
      case 'account-exists-with-different-credential':
        return 'This account needs a different sign-in method. Try the email option below.';
      case 'operation-not-allowed':
        return 'This sign-in method has not been enabled in Firebase for this app yet.';
      case 'app-not-authorized':
        return 'This app is not authorised for Google sign-in. Confirm the package ID and signing certificate in Firebase.';
      default:
        return error.message ?? 'Sign-in could not be completed.';
    }
  }

  Future<void> _emailLogin() => _run(() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      throw const _AuthMessage('Enter an email and a password of at least 6 characters.');
    }
    if (_createAccount) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    } else {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    }
  });

  @override
  Widget build(BuildContext context) {
    if (!NwsbFirebase.ready) return widget.child;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return widget.child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('NowssB', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                    const SizedBox(height: 10),
                    const Text('Sign in to save your practice, progress, and Personal Coach history.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.45)),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _busy ? null : _googleLogin,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Continue with Google'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Row(children: [Expanded(child: Divider(color: Colors.white24)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: Colors.white54))), Expanded(child: Divider(color: Colors.white24))])),
                    _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_password, 'Password', obscure: true),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFB4AB), height: 1.35))),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _emailLogin,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF28282E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_createAccount ? 'Create account' : 'Sign in with email'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() { _createAccount = !_createAccount; _error = null; }),
                      child: Text(_createAccount ? 'I already have an account' : 'Create a new account'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label, {bool obscure = false, TextInputType? keyboard}) => TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60), filled: true, fillColor: const Color(0xFF141416), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white24))),
      );
}

class _AuthMessage implements Exception {
  const _AuthMessage(this.message);
  final String message;
  @override
  String toString() => message;
}
