/// Complete your profile — shown after the first sign-up, and once to
/// accounts that still miss their details. Name, phone with country code,
/// country, optional date of birth, and the friend's code (prefilled from
/// the link the app was opened or installed from).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../economy/coin_collect.dart';
import '../economy/economy_api.dart';
import 'account_kit.dart';
import 'countries.dart';
import 'profile_details.dart';
import 'referral_capture.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key, required this.uid, this.initial, this.onDone, this.onSkip, this.editing = false});

  final String uid;
  final ProfileDetails? initial;

  /// Called after a successful save (the gate lets the app through).
  final VoidCallback? onDone;

  /// "Not now"; null hides the button.
  final VoidCallback? onSkip;

  /// Opened from Profile to edit (back button instead of Not now).
  final bool editing;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phoneNational ?? '');
  late final _code = TextEditingController(text: ReferralCapture.instance.pending?.code ?? '');
  NwsbCountry? _country;
  NwsbCountry? _dial;
  DateTime? _dob;
  bool _busy = false;
  bool _tried = false;
  String _attachedCode = '';
  String? _codeError;
  String? _codeOk;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _country = countryByCode(i?.country) ?? countryByCode(_localeCountry());
    _dial = countryByCode(i?.phoneCountry) ?? _country;
    _dob = i?.dob;
    unawaited(ReferralCapture.instance.attachedCode(widget.uid).then((c) {
      if (!mounted) return;
      final server = EconomyMirror.instance.referredBy;
      setState(() => _attachedCode = c.isNotEmpty ? c : (server.isNotEmpty ? '•' : ''));
    }));
    ReferralCapture.instance.addListener(_pendingChanged);
  }

  void _pendingChanged() {
    final p = ReferralCapture.instance.pending;
    if (p != null && _code.text.trim().isEmpty && mounted) setState(() => _code.text = p.code);
  }

  String? _localeCountry() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    ReferralCapture.instance.removeListener(_pendingChanged);
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String? get _nameError => _tried ? validateName(_name.text) : null;
  String? get _phoneError => _tried ? validatePhone(_phone.text, _dial) : null;
  String? get _countryError => _tried && _country == null ? 'Choose your country.' : null;
  String? get _dobError => validateDob(_dob);

  int get _filled =>
      (validateName(_name.text) == null ? 1 : 0) +
      (_country != null ? 1 : 0) +
      (validatePhone(_phone.text, _dial) == null ? 1 : 0) +
      (_dob != null ? 1 : 0);

  bool get _fromLink {
    final p = ReferralCapture.instance.pending;
    return p != null && p.code == _code.text.trim().toUpperCase() && p.source != 'typed';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 110),
      lastDate: now,
      helpText: 'Date of birth',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: NwsbColors.gold, onPrimary: Color(0xFF1A1408), surface: Color(0xFF16112B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  bool _serverPaysProfileCoins() {
    final acts = ((EconomyMirror.instance.summary['today'] as Map?)?['actions'] as List?) ?? const [];
    for (final a in acts) {
      if (a is Map && a['id'] == 'profile_complete') {
        final fields = a['verifyFields'];
        return fields is List && fields.contains('phone');
      }
    }
    return false;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _saveError = null;
      _codeError = validateReferralInput(_code.text);
      _codeOk = null;
    });
    if (validateName(_name.text) != null || _country == null || validatePhone(_phone.text, _dial) != null || _dobError != null || _codeError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final details = ProfileDetails(
        name: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        country: _country!.code,
        phoneCountry: _dial!.code,
        phoneNational: _phone.text.replaceAll(RegExp(r'[^0-9]'), ''),
        dob: _dob,
        completed: true,
      );
      await ProfileDetailsStore.instance.save(widget.uid, details);
      final code = _code.text.trim();
      if (code.isNotEmpty && _attachedCode.isEmpty) {
        final p = ReferralCapture.instance.pending;
        final source = p != null && p.code == code.toUpperCase() ? p.source : 'typed';
        final out = await ReferralCapture.instance.attach(widget.uid, code, source: source);
        if (!mounted) return;
        if (!out.attached) {
          setState(() {
            _codeError = out.message;
            _busy = false;
          });
          return; // profile is saved; they can fix or clear the code
        }
        setState(() {
          _attachedCode = code.toUpperCase();
          _codeOk = out.message;
        });
      }
      if (_serverPaysProfileCoins()) unawaited(PendingCoins.instance.offer('profile_complete'));
      if (!mounted) return;
      widget.onDone?.call();
    } catch (_) {
      if (mounted) setState(() => _saveError = 'Could not save right now. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return AccountPage(
      kicker: widget.editing ? 'Your account' : 'Welcome to NowssB',
      title: widget.editing ? 'Your details' : 'Complete your profile',
      onBack: widget.editing ? () => Navigator.maybePop(context) : null,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_saveError != null)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_saveError!, style: const TextStyle(color: AccountColors.error, fontSize: 13))),
        GoldCta(key: const Key('profile-save'), label: widget.editing ? 'Save details' : 'Save and continue', busy: _busy, onTap: _save),
        if (widget.onSkip != null)
          TextButton(
            key: const Key('profile-skip'),
            onPressed: _busy ? null : widget.onSkip,
            child: const Text('Not now', style: TextStyle(color: AccountColors.soft, fontWeight: FontWeight.w600)),
          ),
      ]),
      children: [
        GlassCard(
          glow: AccountColors.violet,
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFF3D58A), Color(0xFFA9843C)]),
                boxShadow: [BoxShadow(color: Color(0x66C8A96E), blurRadius: 18)],
              ),
              child: name.isEmpty
                  ? const Icon(Icons.person_rounded, color: Color(0xFF1A1408), size: 28)
                  : Text(name.characters.first.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF1A1408), fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.isEmpty ? 'Your name here' : name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('So rewards, referrals and payouts reach the right person.',
                    style: TextStyle(color: AccountColors.soft, fontSize: 12.5, height: 1.3)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _filled / 4,
                    minHeight: 6,
                    backgroundColor: const Color(0x1FFFFFFF),
                    valueColor: const AlwaysStoppedAnimation(NwsbColors.gold),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const FieldLabel('Full name'),
        TextField(
          key: const Key('profile-name'),
          controller: _name,
          style: accountFieldStyle,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => setState(() {}),
          decoration: accountInput(hint: 'As you want it on NowssB', error: _nameError),
        ),
        const FieldLabel('Country'),
        CountryField(
          fieldKey: const Key('profile-country'),
          country: _country,
          error: _countryError,
          onPicked: (c) => setState(() {
            _country = c;
            if (_phone.text.trim().isEmpty) _dial = c;
          }),
        ),
        const FieldLabel('Phone number'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            key: const Key('profile-dial'),
            onTap: () async {
              final c = await pickCountry(context, selected: _dial?.code);
              if (c != null) setState(() => _dial = c);
            },
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AccountColors.hairline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_dial?.flag ?? '🌐', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(_dial == null ? '+ code' : '+${_dial!.dial}', style: accountFieldStyle),
                const Icon(Icons.expand_more_rounded, size: 18, color: AccountColors.soft),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('profile-phone'),
              controller: _phone,
              style: accountFieldStyle,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(17)],
              onChanged: (_) => setState(() {}),
              decoration: accountInput(hint: 'Mobile number', error: _phoneError),
            ),
          ),
        ]),
        const FieldLabel('Date of birth', optional: true),
        GestureDetector(
          key: const Key('profile-dob'),
          onTap: _pickDob,
          child: InputDecorator(
            isEmpty: _dob == null,
            decoration: accountInput(
              hint: 'Add your birthday',
              error: _dobError,
              suffix: _dob == null
                  ? const Icon(Icons.cake_outlined, color: AccountColors.soft)
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, color: AccountColors.soft),
                      onPressed: () => setState(() => _dob = null),
                    ),
            ),
            child: _dob == null ? null : Text(_prettyDate(_dob!), style: accountFieldStyle),
          ),
        ),
        const FieldLabel('Friend’s code', optional: true),
        if (_attachedCode.isNotEmpty)
          GlassCard(
            key: const Key('profile-ref-locked'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(Icons.verified_rounded, color: AccountColors.ok),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _codeOk ?? (_attachedCode == '•' ? 'You joined with a friend’s link. It stays with your account.' : 'Joined with code $_attachedCode. It stays with your account.'),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                ),
              ),
            ]),
          )
        else ...[
          TextField(
            key: const Key('profile-ref'),
            controller: _code,
            style: accountFieldStyle.copyWith(letterSpacing: 1.6),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(20)],
            onChanged: (_) => setState(() => _codeError = null),
            decoration: accountInput(
              hint: 'Have a code? Enter it here',
              error: _codeError,
              prefix: const Icon(Icons.card_giftcard_rounded, color: NwsbColors.gold),
            ),
          ),
          if (_fromLink)
            const Padding(
              key: Key('profile-ref-from-link'),
              padding: EdgeInsets.only(left: 6, top: 8),
              child: Row(children: [
                Icon(Icons.link_rounded, size: 16, color: NwsbColors.goldLight),
                SizedBox(width: 6),
                Expanded(child: Text('Added from your friend’s link. It is attached once and can’t be changed later.', style: TextStyle(color: NwsbColors.goldLight, fontSize: 12.5))),
              ]),
            ),
        ],
        const SizedBox(height: 18),
        const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: AccountColors.faint),
          SizedBox(width: 8),
          Expanded(
            child: Text('Your phone and birthday stay private to your account. They are never shown on your public profile.',
                style: TextStyle(color: AccountColors.faint, fontSize: 12, height: 1.4)),
          ),
        ]),
      ],
    );
  }
}

String _prettyDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Sits between sign-in and the app: shows [CompleteProfilePage] when the
/// signed-in account is missing its details (unless snoozed), and attaches a
/// waiting referral code as soon as someone is signed in.
class ProfileSetupGate extends StatefulWidget {
  const ProfileSetupGate({super.key, required this.uid, required this.child});
  final String uid;
  final Widget child;

  /// Tests and builds without Firebase: skip the check entirely.
  static bool enabled = true;

  @override
  State<ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends State<ProfileSetupGate> {
  ProfileDetails? _details;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant ProfileSetupGate old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) _check();
  }

  Future<void> _check() async {
    if (!ProfileSetupGate.enabled) return;
    final uid = widget.uid;
    unawaited(ReferralCapture.instance.onSignedIn(uid));
    final d = await ProfileDetailsStore.instance.load(uid);
    if (!mounted || uid != widget.uid || d == null || !d.missing) return;
    // A friend's code waiting always shows the page, so it can be seen.
    if (ReferralCapture.instance.pending == null && await ProfileDetailsStore.instance.snoozed(uid)) return;
    if (!mounted) return;
    setState(() {
      _details = d;
      _show = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return widget.child;
    return CompleteProfilePage(
      key: const Key('profile-setup-gate'),
      uid: widget.uid,
      initial: _details,
      onDone: () => setState(() => _show = false),
      onSkip: () async {
        await ProfileDetailsStore.instance.snooze(widget.uid);
        if (mounted) setState(() => _show = false);
      },
    );
  }
}

/// Profile → Your details: loads what is saved and opens the same page to edit.
class YourDetailsPage extends StatefulWidget {
  const YourDetailsPage({super.key, required this.uid});
  final String uid;

  static Future<void> open(BuildContext context, String uid) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => YourDetailsPage(uid: uid)));

  @override
  State<YourDetailsPage> createState() => _YourDetailsPageState();
}

class _YourDetailsPageState extends State<YourDetailsPage> {
  ProfileDetails? _d;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ProfileDetailsStore.instance.load(widget.uid).then((d) {
      if (mounted) {
        setState(() {
          _d = d;
          _loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AccountColors.bg,
        body: Center(child: CircularProgressIndicator(color: NwsbColors.gold, strokeWidth: 2.4)),
      );
    }
    return CompleteProfilePage(
      uid: widget.uid,
      initial: _d,
      editing: true,
      onDone: () {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Your details are saved.')));
        Navigator.maybePop(context);
      },
    );
  }
}
