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
import '../earn/earn_kit.dart';
import '../../widgets/nwsb_icon.dart';
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
    FocusScope.of(context).unfocus();
    final picked = await pickBirthday(context, initial: _dob);
    if (picked != null && mounted) setState(() => _dob = picked);
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
    final first = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;
    return WhiteCircleBadges(child: AccountPage(
      header: widget.editing ? null : EarnHey(name: first, eyebrow: 'Your NowssB profile', title: first == null ? 'Welcome' : 'Hey, $first', bell: false),
      kicker: widget.editing
          ? 'Your account'
          : (name.trim().isEmpty ? 'Welcome' : 'Hey, ${name.trim().split(RegExp(r'\s+')).first}'),
      title: widget.editing ? 'Your details' : 'Complete your profile',
      subtitle: 'So rewards, referrals and payouts reach the right person.',
      onBack: widget.editing ? () => Navigator.maybePop(context) : null,
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_saveError != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: FieldError(_saveError!)),
        PrimaryBar(key: const Key('profile-save'), label: widget.editing ? 'Save details' : 'Save and continue', busy: _busy, onTap: _save),
        if (widget.onSkip != null) QuietAction(key: const Key('profile-skip'), label: 'Not now', onTap: _busy ? null : widget.onSkip),
      ]),
      children: [
        // The Menu card: white badge (the initial), overline, the name.
        _ProfileHead(
          name: name,
          filled: _filled,
          nameOk: validateName(_name.text) == null,
          countryOk: _country != null,
          phoneOk: validatePhone(_phone.text, _dial) == null,
        ),
        GlassListCard(
          icon: Icons.badge_outlined,
          overline: 'About you',
          title: 'Your details',
          children: [
            TileRow(
              key: const Key('profile-name'),
              leading: const TileBadge(icon: Icons.person_outline_rounded),
              label: 'Full name',
              error: _nameError,
              body: TileInput(
                controller: _name,
                hint: 'As you want it on NowssB',
                caps: TextCapitalization.words,
                autofill: const [AutofillHints.name],
                onChanged: (_) => setState(() {}),
              ),
            ),
            CountryField(
              fieldKey: const Key('profile-country'),
              country: _country,
              error: _countryError,
              onPicked: (c) => setState(() {
                _country = c;
                if (_phone.text.trim().isEmpty) _dial = c;
              }),
            ),
            TileRow(
              key: const Key('profile-phone'),
              leading: _DialPill(
                key: const Key('profile-dial'),
                country: _dial,
                onTap: () async {
                  final c = await pickCountry(context, selected: _dial?.code);
                  if (c != null) setState(() => _dial = c);
                },
              ),
              label: 'Phone number',
              error: _phoneError,
              body: TileInput(
                controller: _phone,
                hint: 'Mobile number',
                keyboard: TextInputType.phone,
                autofill: const [AutofillHints.telephoneNumberNational],
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(17)],
                onChanged: (_) => setState(() {}),
              ),
            ),
            TileRow(
              key: const Key('profile-dob'),
              leading: const TileBadge(icon: Icons.cake_outlined),
              label: 'Date of birth',
              optional: true,
              error: _dobError,
              onTap: _pickDob,
              body: Text(_dob == null ? 'Add your birthday' : _prettyDate(_dob!),
                  style: _dob == null ? const TextStyle(color: Color(0x59FFFFFF), fontSize: 15, fontWeight: FontWeight.w500) : accountFieldStyle),
              trailing: _dob == null
                  ? tileArrow
                  : GestureDetector(
                      key: const Key('profile-dob-clear'),
                      onTap: () => setState(() => _dob = null),
                      child: const Icon(Icons.close_rounded, size: 18, color: kGlassMuted),
                    ),
            ),
          ],
        ),
        GlassListCard(
          icon: Icons.card_giftcard_rounded,
          overline: 'Invited by a friend?',
          title: 'Friend’s code',
          subtitle: _attachedCode.isNotEmpty ? null : 'Optional. It is attached once and can’t be changed later.',
          children: [
            if (_attachedCode.isNotEmpty)
              TileRow(
                key: const Key('profile-ref-locked'),
                leading: const TileBadge(icon: Icons.verified_rounded),
                label: _attachedCode == '•' ? 'Joined with a friend’s link' : 'Code applied · $_attachedCode',
                body: Text(
                  _codeOk ?? 'It stays with your account.',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                ),
                trailing: const CurrentPill(),
              )
            else ...[
              TileRow(
                key: const Key('profile-ref'),
                leading: const TileBadge(icon: Icons.redeem_rounded),
                label: 'Code',
                optional: true,
                error: _codeError,
                body: TileInput(
                  controller: _code,
                  hint: 'Have a code? Enter it here',
                  caps: TextCapitalization.characters,
                  spacing: 1.6,
                  action: TextInputAction.done,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(20)],
                  onChanged: (_) => setState(() => _codeError = null),
                ),
              ),
              if (_fromLink)
                const Padding(
                  key: Key('profile-ref-from-link'),
                  padding: EdgeInsets.fromLTRB(8, 2, 8, 0),
                  child: Row(children: [
                    Icon(Icons.link_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text('Added from your friend’s link.', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600))),
                  ]),
                ),
            ],
          ],
        ),
        const _PrivacyNote('Your phone and birthday stay private to your account. They are never shown on your public profile.'),
      ],
    ));
  }
}

/// The page's head card in the Earn stat shape: the name, a status pill,
/// the big "n / 4" filled in, a white progress line and three chips for the
/// details that matter (name, country, phone).
class _ProfileHead extends StatelessWidget {
  const _ProfileHead({required this.name, required this.filled, required this.nameOk, required this.countryOk, required this.phoneOk});
  final String name;
  final int filled;
  final bool nameOk;
  final bool countryOk;
  final bool phoneOk;

  @override
  Widget build(BuildContext context) {
    final ready = nameOk && countryOk && phoneOk;
    EarnOdd odd(String label, bool ok) => EarnOdd(label, ok ? 'Done' : 'Add', icon: ok ? Icons.check_rounded : Icons.add_rounded);
    return Padding(
      key: const Key('profile-head'),
      padding: const EdgeInsets.only(bottom: 16),
      child: EarnStatCard(
        title: name.isEmpty ? 'Your name here' : name,
        status: EarnStatusPill(ready ? EarnStatus.reached : EarnStatus.ongoing, text: ready ? 'Ready' : 'In progress'),
        left: EarnSide(nameOk ? 'Name added' : 'Add your name', icon: Icons.person_outline_rounded),
        eyebrow: 'Filled in',
        number: '$filled / 4',
        under: filled >= 4 ? 'All done' : '${4 - filled} to go',
        right: EarnSide(phoneOk ? 'Phone added' : 'Add your phone', icon: Icons.phone_iphone_rounded),
        odds: [odd('Name', nameOk), odd('Country', countryOk), odd('Phone', phoneOk)],
      ),
    );
  }
}

/// Flag + calling code in a white pill, where the phone row's circle is.
class _DialPill extends StatelessWidget {
  const _DialPill({super.key, required this.country, required this.onTap});
  final NwsbCountry? country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Calling code',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 10, right: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(country?.flag ?? '🌐', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(country == null ? '+ code' : '+${country!.dial}',
                style: const TextStyle(color: Color(0xFF0B0B10), fontSize: 14, fontWeight: FontWeight.w800)),
            const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF0B0B10)),
          ]),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lock_outline_rounded, size: 15, color: kGlassMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: kGlassMuted, fontSize: 12, height: 1.4))),
      ]),
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
      return AccountPage(
        kicker: 'Your account',
        title: 'Your details',
        onBack: () => Navigator.maybePop(context),
        children: const [LoadingBlock(height: 120), SizedBox(height: 16), LoadingBlock(height: 300)],
      );
    }
    return CompleteProfilePage(
      uid: widget.uid,
      initial: _d,
      editing: true,
      onDone: () {
        showAccountToast(context, 'Your details are saved.');
        Navigator.maybePop(context);
      },
    );
  }
}
