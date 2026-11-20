/// Bank / payout details: where NowssB Earn sends your money. Country-aware
/// (India: UPI or account + IFSC; US: routing + account; UK: sort code +
/// account; IBAN countries: IBAN; everywhere: PayPal or Wise). The numbers go
/// to the server once over HTTPS; the page only shows the masked copy back.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/money.dart';
import 'account_kit.dart';
import 'countries.dart';
import 'payout_methods.dart';

class PayoutDetailsPage extends StatefulWidget {
  const PayoutDetailsPage({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PayoutDetailsPage()));

  @override
  State<PayoutDetailsPage> createState() => _PayoutDetailsPageState();
}

class _PayoutDetailsPageState extends State<PayoutDetailsPage> {
  Map<String, dynamic>? _summary;
  String? _loadError;
  bool _editing = false;
  bool _busy = false;
  bool _tried = false;
  String? _serverError;
  String? _savedNote;

  NwsbCountry? _country;
  PayoutMethod? _method;
  String _accountType = 'checking';
  final _holder = TextEditingController();
  final _a = TextEditingController(); // UPI / account no / IBAN / email
  final _a2 = TextEditingController(); // confirm account no
  final _b = TextEditingController(); // IFSC / routing / sort code / BIC
  final _pan = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_holder, _a, _a2, _b, _pan]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _acct {
    final a = _summary?['payoutAccount'];
    return a is Map ? a.map((k, v) => MapEntry('$k', v)) : const {};
  }

  Map<String, dynamic> get _bal {
    final a = _summary?['balances'];
    return a is Map ? a.map((k, v) => MapEntry('$k', v)) : const {};
  }

  List<String>? get _serverMethods {
    final m = _acct['methods'];
    return m is List ? m.map((e) => '$e').toList() : null;
  }

  bool get _hasSaved => _acct['kyc'] == true || '${_acct['masked'] ?? ''}'.isNotEmpty || '${_acct['upi'] ?? ''}'.isNotEmpty;

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final s = await EconomyApi.call('earnSummary');
      if (!mounted) return;
      setState(() {
        _summary = s;
        final saved = '${_acct['country'] ?? ''}';
        _country ??= countryByCode(saved) ?? countryByCode(FxBook.instance.region) ?? countryByCode('IN');
        _editing = !_hasSaved;
        _pickDefaultMethod(prefer: '${_acct['method'] ?? ''}');
        if (_holder.text.isEmpty) _holder.text = '${_acct['legalName'] ?? ''}';
      });
    } on EconomyException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Could not reach NowssB. Check your connection.');
    }
  }

  void _pickDefaultMethod({String prefer = ''}) {
    final list = availableMethods(_country?.code ?? '', _serverMethods);
    final p = PayoutMethod.byId(prefer);
    _method = (p != null && list.contains(p)) ? p : (list.isEmpty ? null : list.first);
  }

  // ── validation ──
  String? _err(String? Function() check) => _tried ? check() : null;

  String? get _holderErr => _err(() => checkHolder(_holder.text));
  String? get _aErr => _err(() {
        switch (_method) {
          case PayoutMethod.upi:
            return checkUpi(_a.text);
          case PayoutMethod.bankIn:
            return checkIndianAccount(_a.text);
          case PayoutMethod.usAch:
            return checkUsAccount(_a.text);
          case PayoutMethod.gbBank:
            return checkGbAccount(_a.text);
          case PayoutMethod.iban:
            return checkIban(_a.text);
          case PayoutMethod.paypal:
          case PayoutMethod.wise:
            return checkEmail(_a.text);
          case null:
            return null;
        }
      });
  bool get _needsConfirm => _method == PayoutMethod.bankIn || _method == PayoutMethod.usAch || _method == PayoutMethod.gbBank;
  String? get _a2Err => _err(() {
        if (!_needsConfirm) return null;
        final x = _a.text.replaceAll(RegExp(r'\s'), '');
        final y = _a2.text.replaceAll(RegExp(r'\s'), '');
        return x == y ? null : 'The two account numbers don’t match.';
      });
  String? get _bErr => _err(() {
        switch (_method) {
          case PayoutMethod.bankIn:
            return checkIfsc(_b.text);
          case PayoutMethod.usAch:
            return checkRouting(_b.text);
          case PayoutMethod.gbBank:
            return checkSortCode(_b.text);
          case PayoutMethod.iban:
            return checkBic(_b.text);
          default:
            return null;
        }
      });
  bool get _india => _country?.code == 'IN';
  String? get _panErr => _err(() => _india ? checkPan(_pan.text) : null);

  bool get _valid {
    final was = _tried;
    _tried = true;
    final ok = _method != null && _holderErr == null && _aErr == null && _a2Err == null && _bErr == null && _panErr == null;
    _tried = was;
    return ok;
  }

  Map<String, dynamic> _payload() {
    final m = _method!;
    final p = <String, dynamic>{'country': _country!.code, 'method': m.id, 'legalName': _holder.text.trim()};
    final a = _a.text.trim();
    final b = _b.text.trim();
    switch (m) {
      case PayoutMethod.upi:
        p['upi'] = a;
      case PayoutMethod.bankIn:
        p['accountNumber'] = a.replaceAll(RegExp(r'\s'), '');
        p['ifsc'] = b.toUpperCase();
      case PayoutMethod.usAch:
        p['accountNumber'] = a.replaceAll(RegExp(r'\D'), '');
        p['routingNumber'] = b.replaceAll(RegExp(r'\D'), '');
        p['accountType'] = _accountType;
      case PayoutMethod.gbBank:
        p['accountNumber'] = a.replaceAll(RegExp(r'\D'), '');
        p['sortCode'] = b.replaceAll(RegExp(r'\D'), '');
      case PayoutMethod.iban:
        p['iban'] = normalizeIban(a);
        if (b.isNotEmpty) p['bic'] = b.toUpperCase();
      case PayoutMethod.paypal:
      case PayoutMethod.wise:
        p['email'] = a.toLowerCase();
    }
    if (_india) p['pan'] = _pan.text.trim().toUpperCase();
    return p;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _serverError = null;
    });
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('savePayoutAccount', _payload());
      if (!mounted) return;
      _a.clear();
      _a2.clear();
      _b.clear();
      _pan.clear();
      _savedNote = '${r['message'] ?? ''}'.isNotEmpty ? '${r['message']}' : 'Saved.';
      _tried = false;
      await _load();
      if (mounted) setState(() => _editing = false);
    } on EconomyException catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } catch (_) {
      if (mounted) setState(() => _serverError = 'Could not save right now. Nothing was sent — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _summary == null && _loadError == null;
    return AccountPage(
      kicker: 'Earn',
      title: 'Bank / payout details',
      subtitle: 'Where NowssB Earn sends your money.',
      onBack: () => Navigator.maybePop(context),
      bottom: _summary != null && _editing
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PrimaryBar(key: const Key('payout-save'), label: 'Save payout details', busy: _busy, onTap: _method == null ? null : _save),
              if (_hasSaved)
                QuietAction(
                  key: const Key('payout-cancel'),
                  label: 'Cancel',
                  onTap: _busy
                      ? null
                      : () => setState(() {
                            _editing = false;
                            _tried = false;
                            _serverError = null;
                          }),
                ),
            ])
          : null,
      children: [
        if (loading) ...[
          const LoadingBlock(height: 200),
          const SizedBox(height: 16),
          const LoadingBlock(height: 260),
        ] else if (_loadError != null)
          GlassListCard(
            icon: Icons.wifi_off_rounded,
            overline: 'Not loaded',
            title: 'Could not open your payout details',
            subtitle: _loadError,
            children: [
              GlassTile(key: const Key('payout-retry'), icon: Icons.refresh_rounded, title: 'Try again', onTap: _load),
            ],
          )
        else ...[
          if (_savedNote != null && !_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Row(children: [
                const CurrentPill(),
                const SizedBox(width: 10),
                Expanded(child: Text(_savedNote!, key: const Key('payout-saved-note'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),
          if (_hasSaved && !_editing) _savedCard() else _form(),
          _whenCard(),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.shield_outlined, size: 15, color: kGlassMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your details go straight to NowssB’s server over an encrypted connection and are shown back only masked. '
                  'NowssB will never ask for your password, PIN, OTP or card number.',
                  style: TextStyle(color: kGlassMuted, fontSize: 12, height: 1.45),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  /// The saved account as a black bank card (the Store / Routine black
  /// banner plate): gold NOWSSB EARN, the masked number big, the holder in
  /// caps, a white Edit pill.
  Widget _savedCard() {
    final a = _acct;
    final c = countryByCode('${a['country'] ?? ''}');
    final method = PayoutMethod.byId('${a['method'] ?? ''}') ?? (c?.code == 'IN' ? PayoutMethod.upi : null);
    final masked = '${a['masked'] ?? ''}'.isNotEmpty ? '${a['masked']}' : '${a['upi'] ?? ''}';
    final ready = a['kyc'] == true;
    final open = _summary?['countryOk'] != false;
    return Container(
      key: const Key('payout-saved-card'),
      margin: const EdgeInsets.only(bottom: 16),
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x29FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('NOWSSB EARN', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: NwsbColors.goldLight)),
          const Spacer(),
          _StatusChip(ready: ready && open, label: !ready ? 'Needs details' : (open ? 'Ready' : 'Not open yet')),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          const _CardChip(),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${method?.label ?? 'Payout account'} · ${c?.name ?? ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0x99FFFFFF), fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
          if (c != null) Text(c.flag, style: const TextStyle(fontSize: 20)),
        ]),
        const SizedBox(height: 16),
        Text(masked.isEmpty ? '••••' : masked,
            key: const Key('payout-masked'),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2.2, height: 1.1)),
        if ('${a['bankLine'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('${a['bankLine']}', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5)),
        ],
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ACCOUNT HOLDER', style: TextStyle(color: kGlassMuted, fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('${a['legalName'] ?? ''}'.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            ]),
          ),
          GestureDetector(
            key: const Key('payout-edit'),
            onTap: () => setState(() {
              _editing = true;
              _savedNote = null;
              _country = c ?? _country;
              _pickDefaultMethod(prefer: method?.id ?? '');
            }),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 16, color: NwsbColors.ink),
                SizedBox(width: 6),
                Text('Edit', style: TextStyle(color: NwsbColors.ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
        if (!open) ...[
          const SizedBox(height: 14),
          const Text('Payouts are not open in your country yet. Your balance stays safe here until they are.',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _form() {
    final methods = availableMethods(_country?.code ?? '', _serverMethods);
    final m = _method;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassListCard(
        icon: Icons.account_balance_outlined,
        overline: 'Payout account',
        title: 'Where should we send your money?',
        subtitle: 'Use an account in your own name. Each payout is checked before it goes out.',
        children: [
          CountryField(
            fieldKey: const Key('payout-country'),
            country: _country,
            onPicked: (c) => setState(() {
              _country = c;
              _tried = false;
              _a.clear();
              _a2.clear();
              _b.clear();
              _pickDefaultMethod();
            }),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text('PAID BY', style: TextStyle(color: kGlassMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final x in methods)
              GlassChoice(
                key: Key('payout-method-${x.id}'),
                label: x.label,
                icon: _methodIcon(x),
                selected: m == x,
                onTap: () => setState(() {
                  _method = x;
                  _tried = false;
                  _a.clear();
                  _a2.clear();
                  _b.clear();
                }),
              ),
          ]),
          if (m != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
              child: Text(m.sub, style: const TextStyle(color: kGlassMuted, fontSize: 12, height: 1.3)),
            ),
        ],
      ),
      if (m != null)
        GlassListCard(
          icon: _methodIcon(m),
          overline: m.label,
          title: 'Account details',
          children: [
            _field('payout-holder', _holder, label: 'Account holder name', icon: Icons.person_outline_rounded, hint: 'Full legal name', error: _holderErr, caps: TextCapitalization.words),
            ..._methodFields(m),
            if (_india) ...[
              _field('payout-pan', _pan,
                  label: 'PAN',
                  icon: Icons.badge_outlined,
                  hint: 'ABCDE1234F',
                  error: _panErr,
                  caps: TextCapitalization.characters,
                  spacing: 1.4,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(10)]),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Text('Indian tax rules need PAN on earnings payouts (TDS). Only the last 4 characters are kept to show you.',
                    style: TextStyle(color: kGlassMuted, fontSize: 12, height: 1.35)),
              ),
            ],
            if (_serverError != null) KeyedSubtree(key: const Key('payout-server-error'), child: FieldError(_serverError!)),
          ],
        ),
    ]);
  }

  IconData _methodIcon(PayoutMethod x) => x == PayoutMethod.upi
      ? Icons.bolt_rounded
      : (x == PayoutMethod.paypal || x == PayoutMethod.wise)
          ? Icons.alternate_email_rounded
          : Icons.account_balance_rounded;

  List<Widget> _methodFields(PayoutMethod m) {
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))];
    Widget again() => _field('payout-account2', _a2,
        label: 'Re-enter account number', icon: Icons.repeat_rounded, hint: 'Same number again', error: _a2Err, keyboard: TextInputType.number, formatters: digits, spacing: 1.2);
    switch (m) {
      case PayoutMethod.upi:
        return [_field('payout-upi', _a, label: 'UPI ID', icon: Icons.alternate_email_rounded, hint: 'name@okhdfcbank', error: _aErr, keyboard: TextInputType.emailAddress)];
      case PayoutMethod.bankIn:
        return [
          _field('payout-account', _a, label: 'Account number', icon: Icons.numbers_rounded, hint: '9–18 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits, spacing: 1.2),
          again(),
          _field('payout-ifsc', _b,
              label: 'IFSC',
              icon: Icons.account_balance_outlined,
              hint: 'HDFC0001234',
              error: _bErr,
              caps: TextCapitalization.characters,
              spacing: 1.2,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(11)]),
        ];
      case PayoutMethod.usAch:
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(children: [
              const Text('ACCOUNT TYPE', style: TextStyle(color: kGlassMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
              const Spacer(),
              GlassChoice(key: const Key('payout-type-checking'), label: 'Checking', selected: _accountType == 'checking', onTap: () => setState(() => _accountType = 'checking')),
              const SizedBox(width: 8),
              GlassChoice(key: const Key('payout-type-savings'), label: 'Savings', selected: _accountType == 'savings', onTap: () => setState(() => _accountType = 'savings')),
            ]),
          ),
          _field('payout-routing', _b,
              label: 'Routing number (ABA)', icon: Icons.route_outlined, hint: '9 digits', error: _bErr, keyboard: TextInputType.number, spacing: 1.2, formatters: [...digits, LengthLimitingTextInputFormatter(11)]),
          _field('payout-account', _a, label: 'Account number', icon: Icons.numbers_rounded, hint: '4–17 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits, spacing: 1.2),
          again(),
        ];
      case PayoutMethod.gbBank:
        return [
          _field('payout-sort', _b,
              label: 'Sort code', icon: Icons.tag_rounded, hint: '12-34-56', error: _bErr, keyboard: TextInputType.number, spacing: 1.2,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), LengthLimitingTextInputFormatter(8)]),
          _field('payout-account', _a, label: 'Account number', icon: Icons.numbers_rounded, hint: '8 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits, spacing: 1.2),
          again(),
        ];
      case PayoutMethod.iban:
        return [
          _field('payout-iban', _a,
              label: 'IBAN', icon: Icons.numbers_rounded, hint: '${_country?.code ?? 'DE'}00 0000 0000 0000 0000 00', error: _aErr, caps: TextCapitalization.characters, spacing: 0.8,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')), LengthLimitingTextInputFormatter(42)]),
          _field('payout-bic', _b,
              label: 'BIC / SWIFT', optional: true, icon: Icons.account_balance_outlined, hint: 'DEUTDEFF', error: _bErr, caps: TextCapitalization.characters, spacing: 1.2,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(11)]),
        ];
      case PayoutMethod.paypal:
      case PayoutMethod.wise:
        return [
          _field('payout-email', _a,
              label: m == PayoutMethod.paypal ? 'PayPal email' : 'Wise email', icon: Icons.mail_outline_rounded, hint: 'you@example.com', error: _aErr, keyboard: TextInputType.emailAddress),
        ];
    }
  }

  Widget _field(String key, TextEditingController c,
      {required String label,
      required IconData icon,
      String? hint,
      String? error,
      bool optional = false,
      double spacing = 0,
      TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.none,
      List<TextInputFormatter>? formatters}) {
    return TileRow(
      key: Key(key),
      leading: TileBadge(icon: icon),
      label: label,
      optional: optional,
      error: error,
      body: TileInput(
        controller: c,
        hint: hint ?? '',
        keyboard: keyboard,
        caps: caps,
        spacing: spacing,
        formatters: formatters,
        onChanged: (_) {
          if (_tried) setState(() {});
        },
      ),
    );
  }

  /// "When you get paid": the Menu card with one black row per step.
  Widget _whenCard() {
    final b = _bal;
    final hold = ((_summary?['lock'] as Map?)?['holdDays'] as num?)?.toInt() ?? 30;
    final min = (b['minPayoutINR'] as num?) ?? 0;
    final day = (b['payoutDay'] as num?)?.toInt() ?? 0;
    final pending = (b['pendingINR'] as num?) ?? 0;
    final available = (b['availableINR'] as num?) ?? 0;
    return GlassListCard(
      key: const Key('payout-when'),
      icon: Icons.schedule_rounded,
      overline: 'How payouts work',
      title: 'When you get paid',
      children: [
        _Step(
            icon: Icons.hourglass_top_rounded,
            title: 'Pending · $hold days',
            body: 'Google Play and Apple can refund a purchase, so each earning waits out the refund window first. A refunded sale is taken back.',
            value: pending > 0 ? FxBook.instance.formatPrice(pending) : null),
        _Step(
            icon: Icons.lock_open_rounded,
            title: 'Available',
            body: 'After the window it becomes yours to withdraw.',
            value: available > 0 ? FxBook.instance.formatPrice(available) : null),
        _Step(
            icon: Icons.outbox_rounded,
            title: 'Request a payout',
            body: min > 0 ? 'From Earnings once at least ${FxBook.instance.formatPrice(min)} is available.' : 'From Earnings once something is available.'),
        _Step(
            icon: Icons.send_rounded,
            title: 'Checked and sent',
            body: day > 0
                ? 'A person checks each request, then it is sent to this account around the ${_ordinal(day)} of the month.'
                : 'A person checks each request, then it is sent to this account.'),
      ],
    );
  }
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return '$n${const {1: 'st', 2: 'nd', 3: 'rd'}[n % 10] ?? 'th'}';
}

/// One step: a black [GlassTile] row that reads, with the amount in a white
/// pill where the arrow would be.
class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body, this.value});
  final IconData icon;
  final String title;
  final String body;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(color: kGlassTile, borderRadius: BorderRadius.circular(20)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TileBadge(icon: icon),
        Container(width: 1, height: 28, margin: const EdgeInsets.fromLTRB(12, 5, 12, 0), color: const Color(0x26FFFFFF)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(color: kGlassMuted, fontSize: 12, height: 1.35)),
          ]),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(value!, style: const TextStyle(color: Color(0xFF0B0B10), fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ready, required this.label});
  final bool ready;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: ready ? Colors.white : const Color(0x1AFFFFFF),
        border: Border.all(color: ready ? Colors.white : const Color(0x1FFFFFFF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ready ? Icons.check_rounded : Icons.schedule_rounded, size: 13, color: ready ? const Color(0xFF0B0B10) : Colors.white),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: ready ? const Color(0xFF0B0B10) : Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// The small gold-edged chip a bank card carries, drawn (no picture).
class _CardChip extends StatelessWidget {
  const _CardChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 27,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)]),
      ),
      child: CustomPaint(painter: _ChipLines()),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawLine(Offset(s.width / 3, 0), Offset(s.width / 3, s.height), p);
    c.drawLine(Offset(s.width * 2 / 3, 0), Offset(s.width * 2 / 3, s.height), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width / 3, s.height * .25, s.width / 3, s.height * .5), const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(_ChipLines old) => false;
}
