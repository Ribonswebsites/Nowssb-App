/// Full-screen NowssB login. The neon portrait is the background.
/// Every pill is glass — no fill colour, no gradient.
library;

import 'dart:math' as math;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../admin/template/editable.dart';
import '../data/settings.dart';

class LoginStage extends StatelessWidget {
  const LoginStage({
    super.key,
    required this.id,
    required this.secret,
    required this.busy,
    required this.obscure,
    required this.remember,
    required this.createAccount,
    required this.codeSent,
    required this.onSubmit,
    required this.onGoogle,
    required this.onApple,
    required this.onForgot,
    required this.onToggleCreate,
    required this.onToggleObscure,
    required this.onToggleRemember,
    this.onExplore,
    this.onClose,
    this.error,
    this.notice,
  });

  final TextEditingController id;
  final TextEditingController secret;
  final bool busy;
  final bool obscure;
  final bool remember;
  final bool createAccount;
  final bool codeSent;
  final String? error;
  final String? notice;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onForgot;
  final VoidCallback onToggleCreate;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleRemember;
  final VoidCallback? onExplore;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).shortestSide >= 600) return _tablet(context);
    final pad = MediaQuery.paddingOf(context);
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF05060C)),
        const Positioned.fill(child: _LoginFilm()),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x22000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.12, 0.22, 0.52, 1],
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(22, pad.top + 56, 22, pad.bottom + 12),
          child: Column(
            children: _form(context, faceGap: (h * 0.22).clamp(120.0, 210.0)),
          ),
        ),
      ],
    );
  }

  /// Tablet: the film at its own shape on the left (never stretched or
  /// cropped behind the form), the form beside it at a phone's width.
  Widget _tablet(BuildContext context) {
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    final w = mq.size.width - pad.horizontal - 48;
    final h = mq.size.height - pad.vertical - 48;
    const ratio = 624 / 1456; // assets/video/login-phone.mp4
    const gap = 40.0;
    const minForm = 380.0;
    var fh = h;
    var fw = fh * ratio;
    if (w - fw - gap < minForm) {
      fw = math.max(200.0, w - gap - minForm);
      fh = fw / ratio;
    }
    final formW = math.min(440.0, w - fw - gap);
    return Stack(
      key: const ValueKey('login-tablet'),
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1424), Color(0xFF05060C), Color(0xFF020308)],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              pad.left + 24, pad.top + 24, pad.right + 24, pad.bottom + 24),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  key: const ValueKey('login-tablet-film'),
                  width: fw,
                  height: fh,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0x2EFFFFFF)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 40,
                          offset: Offset(0, 20))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const RepaintBoundary(child: _LoginFilm()),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  key: const ValueKey('login-tablet-form'),
                  width: formW,
                  height: h,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(children: _form(context, faceGap: 36)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _form(BuildContext context, {required double faceGap}) => [
        if (onClose != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: busy ? null : onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        const EditableLabel(
          'login_stage.LoginStage',
          'NowssB',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 0.95,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        const EditableLabel(
          'login_stage.LoginStage',
          'NATURAL ORIGIN WORD SCIENCE',
          style: TextStyle(
            color: Color(0xE6FFFFFF),
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        const EditableLabel(
          'login_stage.LoginStage',
          'YOUR MIND DESERVES\nBETTER FREQUENCIES',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.45,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: faceGap),
        _GlassField(
          controller: id,
          hint: 'Email or Phone Number',
          icon: Icons.mail_outline,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _GlassField(
          controller: secret,
          hint: codeSent ? 'SMS code' : 'Password',
          onSubmitted: busy ? null : onSubmit,
          icon: codeSent ? Icons.sms_outlined : Icons.lock_outline,
          obscure: codeSent ? false : obscure,
          keyboard:
              codeSent ? TextInputType.number : TextInputType.visiblePassword,
          suffix: codeSent
              ? null
              : IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xCCFFFFFF),
                    size: 20,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: busy ? null : onToggleRemember,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RememberMark(on: remember),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: EditableLabel(
                        'login_stage.LoginStage',
                        'Remember me',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: GestureDetector(
                onTap: busy ? null : onForgot,
                child: const EditableLabel(
                  'login_stage.LoginStage',
                  'Forgot password?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _GlassButton(
          height: 54,
          onTap: busy ? null : onSubmit,
          // Busy: the words only, centred — no orb (Ribon, Nov 18).
          child: busy
              ? const Text(
                  'Loading please wait',
                  key: ValueKey('login-busy-label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                )
              : EditableLabel(
                  'login_stage.LoginStage',
                  codeSent ? 'Verify' : (createAccount ? 'Sign Up' : 'Log In'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFFFB4AB), fontSize: 12, height: 1.35),
          ),
        ],
        if (notice != null) ...[
          const SizedBox(height: 10),
          Text(
            notice!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFE8D5A3), fontSize: 12, height: 1.35),
          ),
        ],
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0x55FFFFFF), height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: EditableLabel(
                'login_stage.LoginStage',
                'OR',
                style: TextStyle(
                    color: Color(0xCCFFFFFF), fontSize: 11, letterSpacing: 2),
              ),
            ),
            Expanded(child: Divider(color: Color(0x55FFFFFF), height: 1)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                height: 48,
                onTap: busy ? null : onGoogle,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleMark(),
                    SizedBox(width: 8),
                    Flexible(
                      child: EditableLabel(
                        'login_stage.LoginStage',
                        'Continue with Google',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassButton(
                height: 48,
                onTap: busy ? null : onApple,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Flexible(
                      child: EditableLabel(
                        'login_stage.LoginStage',
                        'Continue with Apple',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: busy ? null : onToggleCreate,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
              children: [
                TextSpan(
                  text: createAccount
                      ? 'Already have an account?  '
                      : "Don't have an account?  ",
                ),
                TextSpan(
                  text: createAccount ? 'Log In' : 'Sign Up',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (onExplore != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: busy ? null : onExplore,
            child: const EditableLabel(
              'login_stage.LoginStage',
              'Explore without account',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const EditableLabel(
          'login_stage.LoginStage',
          'LISTEN   ·   REPEAT   ·   AWAKEN',
          style: TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ];
}

class _RememberMark extends StatelessWidget {
  const _RememberMark({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? const Color(0xCCFFFFFF) : const Color(0x22000000),
        border: Border.all(color: const Color(0xEEFFFFFF)),
      ),
      child: on
          ? const Icon(Icons.check, size: 12, color: Color(0xFF111111))
          : null,
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          textInputAction:
              onSubmitted != null ? TextInputAction.go : TextInputAction.next,
          onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          autocorrect: false,
          enableSuggestions: !obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            prefixIcon: Icon(icon, color: const Color(0xE6FFFFFF), size: 18),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: _edge,
            enabledBorder: _edge,
            focusedBorder: _edgeOn,
          ),
        ),
      ),
    );
  }

  static const _edge = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(999)),
    borderSide: BorderSide(color: Color(0x66FFFFFF)),
  );
  static const _edgeOn = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(999)),
    borderSide: BorderSide(color: Color(0xCCFFFFFF)),
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton(
      {required this.child, required this.onTap, this.height = 54});

  final Widget child;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: const Color(0x1AFFFFFF),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  static const _svg =
      '<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M17.1 9.2c0-.6-.1-1.2-.2-1.8H9v3.3h4.6c-.2 1-.8 1.9-1.7 2.4v2h2.7c1.6-1.4 2.5-3.6 2.5-5.9z" fill="#4285F4"/>'
      '<path d="M9 18c2.3 0 4.2-.8 5.6-2.1l-2.7-2c-.8.5-1.8.8-2.9.8-2.2 0-4.1-1.5-4.8-3.5H1.4v2.1C2.8 16.1 5.7 18 9 18z" fill="#34A853"/>'
      '<path d="M4.2 11.2c-.2-.5-.3-1-.3-1.6s.1-1.1.3-1.6V5.9H1.4C.5 7.4 0 9.1 0 10.9s.5 3.5 1.4 5l2.8-4.7z" fill="#FBBC05"/>'
      '<path d="M9 3.6c1.2 0 2.3.4 3.2 1.2L14.8 2C13.3.7 11.3 0 9 0 5.7 0 2.8 1.9 1.4 4.6l2.8 2.1C4.9 5.1 6.8 3.6 9 3.6z" fill="#EA4335"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 16, height: 16);
  }
}

/// The portrait the owner sent. The still is painted first so the face is
/// there before the decoder opens, then the same clip moves.
class _LoginFilm extends StatefulWidget {
  const _LoginFilm();

  @override
  State<_LoginFilm> createState() => _LoginFilmState();
}

class _LoginFilmState extends State<_LoginFilm> {
  VideoPlayerController? _film;
  var _ready = false;
  int _gen = 0;

  bool get _motionOn => Settings.instance.fashionPlus;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onMotion);
    if (_motionOn) _open();
  }

  void _onMotion() {
    if (!mounted) return;
    if (_motionOn) {
      if (_film == null) {
        _open();
      } else {
        _film!.play();
      }
    } else {
      _close();
    }
  }

  void _open() {
    final gen = ++_gen;
    final film = VideoPlayerController.asset('assets/video/login-phone.mp4')
      ..setLooping(true)
      ..setVolume(0);
    _film = film;
    // A film that cannot load (no decoder, missing platform) must never
    // take the login screen down; the still backdrop stays instead.
    try {
      film.initialize().then((_) {
        if (!mounted || gen != _gen || !_motionOn) return;
        film.play();
        setState(() => _ready = true);
      }).catchError((Object _) {});
    } catch (_) {}
  }

  void _close() {
    _gen++;
    final film = _film;
    _film = null;
    _ready = false;
    try {
      film?.pause();
      film?.dispose();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onMotion);
    _gen++;
    try {
      _film?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final film = _film;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/video/login-phone-poster.webp',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.05),
        ),
        if (_ready && film != null && film.value.size.width > 0)
          FittedBox(
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.05),
            child: SizedBox(
              width: film.value.size.width,
              height: film.value.size.height,
              child: VideoPlayer(film),
            ),
          ),
      ],
    );
  }
}
