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
      kicker: 'NowssB Earn',
      title: 'Bank / payout details',
      onBack: () => Navigator.maybePop(context),
      bottom: _summary != null && _editing
          ? GoldCta(key: const Key('payout-save'), label: 'Save payout details', busy: _busy, onTap: _method == null ? null : _save)
          : null,
      children: [
        if (loading) ...[
          const _Shimmer(height: 150),
          const SizedBox(height: 14),
          const _Shimmer(height: 220),
        ] else if (_loadError != null)
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_loadError!, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
              const SizedBox(height: 12),
              GlassChoice(key: const Key('payout-retry'), label: 'Try again', icon: Icons.refresh_rounded, selected: false, onTap: _load),
            ]),
          )
        else ...[
          if (_savedNote != null && !_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AccountColors.ok, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_savedNote!, key: const Key('payout-saved-note'), style: const TextStyle(color: AccountColors.ok, fontSize: 13))),
              ]),
            ),
          if (_hasSaved && !_editing) _savedCard() else _form(),
          const SizedBox(height: 18),
          _whenCard(),
          const SizedBox(height: 14),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_outlined, size: 16, color: AccountColors.faint),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your details go straight to NowssB’s server over an encrypted connection and are shown back only masked. '
                'NowssB will never ask for your password, PIN, OTP or card number.',
                style: TextStyle(color: AccountColors.faint, fontSize: 12, height: 1.45),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _savedCard() {
    final a = _acct;
    final c = countryByCode('${a['country'] ?? ''}');
    final method = PayoutMethod.byId('${a['method'] ?? ''}') ?? (c?.code == 'IN' ? PayoutMethod.upi : null);
    final masked = '${a['masked'] ?? ''}'.isNotEmpty ? '${a['masked']}' : '${a['upi'] ?? ''}';
    final ready = a['kyc'] == true;
    final open = _summary?['countryOk'] != false;
    return Container(
      key: const Key('payout-saved-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1D63), Color(0xFF140E2E), Color(0xFF0B0816)],
        ),
        border: Border.all(color: NwsbColors.gold.withValues(alpha: 0.45)),
        boxShadow: const [BoxShadow(color: Color(0x403B2585), blurRadius: 30, spreadRadius: -8, offset: Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c?.flag ?? '🌐', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${method?.label ?? 'Payout account'} · ${c?.name ?? ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          _StatusChip(ready: ready && open, label: !ready ? 'Needs details' : (open ? 'Ready' : 'Not open yet')),
        ]),
        const SizedBox(height: 22),
        Text(masked.isEmpty ? '••••' : masked,
            key: const Key('payout-masked'),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
        if ('${a['bankLine'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('${a['bankLine']}', style: const TextStyle(color: AccountColors.soft, fontSize: 13)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: Text('${a['legalName'] ?? ''}'.toUpperCase(),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AccountColors.soft, fontSize: 12.5, letterSpacing: 1.4, fontWeight: FontWeight.w600)),
          ),
          GlassChoice(
            key: const Key('payout-edit'),
            label: 'Edit',
            icon: Icons.edit_outlined,
            selected: false,
            onTap: () => setState(() {
              _editing = true;
              _savedNote = null;
              _country = c ?? _country;
              _pickDefaultMethod(prefer: method?.id ?? '');
            }),
          ),
        ]),
        if (!open) ...[
          const SizedBox(height: 12),
          const Text('Payouts are not open in your country yet. Your balance stays safe here until they are.',
              style: TextStyle(color: AccountColors.soft, fontSize: 12.5, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _form() {
    final methods = availableMethods(_country?.code ?? '', _serverMethods);
    final m = _method;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Where should we send your money?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Use an account in your own name. Each payout is checked before it goes out.',
            style: TextStyle(color: AccountColors.soft, fontSize: 12.5, height: 1.35)),
        const FieldLabel('Country'),
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
        const FieldLabel('Paid by'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in methods)
            GlassChoice(
              key: Key('payout-method-${x.id}'),
              label: x.label,
              icon: x == PayoutMethod.upi
                  ? Icons.bolt_rounded
                  : (x == PayoutMethod.paypal || x == PayoutMethod.wise)
                      ? Icons.alternate_email_rounded
                      : Icons.account_balance_rounded,
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
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(m.sub, style: const TextStyle(color: AccountColors.faint, fontSize: 12)),
          ),
        if (m != null) ...[
          const FieldLabel('Account holder name'),
          _field('payout-holder', _holder, hint: 'Full legal name', error: _holderErr, caps: TextCapitalization.words),
          ..._methodFields(m),
          if (_india) ...[
            const FieldLabel('PAN'),
            _field('payout-pan', _pan,
                hint: 'ABCDE1234F',
                error: _panErr,
                caps: TextCapitalization.characters,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(10)]),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text('Indian tax rules need PAN on earnings payouts (TDS). Only the last 4 characters are kept to show you.',
                  style: TextStyle(color: AccountColors.faint, fontSize: 12, height: 1.35)),
            ),
          ],
        ],
        if (_serverError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_serverError!, key: const Key('payout-server-error'), style: const TextStyle(color: AccountColors.error, fontSize: 13, height: 1.35)),
          ),
        if (_hasSaved)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('payout-cancel'),
              onPressed: () => setState(() {
                _editing = false;
                _tried = false;
                _serverError = null;
              }),
              child: const Text('Cancel', style: TextStyle(color: AccountColors.soft)),
            ),
          ),
      ]),
    );
  }

  List<Widget> _methodFields(PayoutMethod m) {
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))];
    switch (m) {
      case PayoutMethod.upi:
        return [const FieldLabel('UPI ID'), _field('payout-upi', _a, hint: 'name@okhdfcbank', error: _aErr, keyboard: TextInputType.emailAddress)];
      case PayoutMethod.bankIn:
        return [
          const FieldLabel('Account number'),
          _field('payout-account', _a, hint: '9–18 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits),
          const FieldLabel('Re-enter account number'),
          _field('payout-account2', _a2, hint: 'Same number again', error: _a2Err, keyboard: TextInputType.number, formatters: digits),
          const FieldLabel('IFSC'),
          _field('payout-ifsc', _b,
              hint: 'HDFC0001234',
              error: _bErr,
              caps: TextCapitalization.characters,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(11)]),
        ];
      case PayoutMethod.usAch:
        return [
          const FieldLabel('Account type'),
          Wrap(spacing: 8, children: [
            GlassChoice(key: const Key('payout-type-checking'), label: 'Checking', selected: _accountType == 'checking', onTap: () => setState(() => _accountType = 'checking')),
            GlassChoice(key: const Key('payout-type-savings'), label: 'Savings', selected: _accountType == 'savings', onTap: () => setState(() => _accountType = 'savings')),
          ]),
          const FieldLabel('Routing number (ABA)'),
          _field('payout-routing', _b, hint: '9 digits', error: _bErr, keyboard: TextInputType.number, formatters: [...digits, LengthLimitingTextInputFormatter(11)]),
          const FieldLabel('Account number'),
          _field('payout-account', _a, hint: '4–17 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits),
          const FieldLabel('Re-enter account number'),
          _field('payout-account2', _a2, hint: 'Same number again', error: _a2Err, keyboard: TextInputType.number, formatters: digits),
        ];
      case PayoutMethod.gbBank:
        return [
          const FieldLabel('Sort code'),
          _field('payout-sort', _b, hint: '12-34-56', error: _bErr, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), LengthLimitingTextInputFormatter(8)]),
          const FieldLabel('Account number'),
          _field('payout-account', _a, hint: '8 digits', error: _aErr, keyboard: TextInputType.number, formatters: digits),
          const FieldLabel('Re-enter account number'),
          _field('payout-account2', _a2, hint: 'Same number again', error: _a2Err, keyboard: TextInputType.number, formatters: digits),
        ];
      case PayoutMethod.iban:
        return [
          const FieldLabel('IBAN'),
          _field('payout-iban', _a, hint: '${_country?.code ?? 'DE'}00 0000 0000 0000 0000 00', error: _aErr, caps: TextCapitalization.characters,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')), LengthLimitingTextInputFormatter(42)]),
          const FieldLabel('BIC / SWIFT', optional: true),
          _field('payout-bic', _b, hint: 'DEUTDEFF', error: _bErr, caps: TextCapitalization.characters,
              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(11)]),
        ];
      case PayoutMethod.paypal:
      case PayoutMethod.wise:
        return [
          FieldLabel(m == PayoutMethod.paypal ? 'PayPal email' : 'Wise email'),
          _field('payout-email', _a, hint: 'you@example.com', error: _aErr, keyboard: TextInputType.emailAddress),
        ];
    }
  }

  Widget _field(String key, TextEditingController c,
      {String? hint, String? error, TextInputType? keyboard, TextCapitalization caps = TextCapitalization.none, List<TextInputFormatter>? formatters}) {
    return TextField(
      key: Key(key),
      controller: c,
      style: accountFieldStyle,
      cursorColor: NwsbColors.gold,
      keyboardType: keyboard,
      textCapitalization: caps,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: formatters,
      onChanged: (_) {
        if (_tried) setState(() {});
      },
      decoration: accountInput(hint: hint, error: error),
    );
  }

  Widget _whenCard() {
    final b = _bal;
    final hold = ((_summary?['lock'] as Map?)?['holdDays'] as num?)?.toInt() ?? 30;
    final min = (b['minPayoutINR'] as num?) ?? 0;
    final day = (b['payoutDay'] as num?)?.toInt() ?? 0;
    final pending = (b['pendingINR'] as num?) ?? 0;
    final available = (b['availableINR'] as num?) ?? 0;
    return GlassCard(
      key: const Key('payout-when'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('When you get paid', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _Step(n: '1', title: 'Pending · $hold days', body: 'Google Play and Apple can refund a purchase, so each earning waits out the refund window first. A refunded sale is taken back.',
            value: pending > 0 ? FxBook.instance.formatPrice(pending) : null),
        _Step(n: '2', title: 'Available', body: 'After the window it becomes yours to withdraw.', value: available > 0 ? FxBook.instance.formatPrice(available) : null),
        _Step(
            n: '3',
            title: 'Request a payout',
            body: min > 0 ? 'From Earnings once at least ${FxBook.instance.formatPrice(min)} is available.' : 'From Earnings once something is available.'),
        _Step(
            n: '4',
            title: 'Checked and sent',
            body: day > 0
                ? 'A person checks each request, then it is sent to this account around the ${_ordinal(day)} of the month.'
                : 'A person checks each request, then it is sent to this account.',
            last: true),
      ]),
    );
  }
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return '$n${const {1: 'st', 2: 'nd', 3: 'rd'}[n % 10] ?? 'th'}';
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body, this.value, this.last = false});
  final String n;
  final String title;
  final String body;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: NwsbColors.gold.withValues(alpha: 0.18), border: Border.all(color: NwsbColors.gold)),
            child: Text(n, style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          if (!last) Expanded(child: Container(width: 1.4, margin: const EdgeInsets.symmetric(vertical: 4), color: NwsbColors.gold.withValues(alpha: 0.35))),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                if (value != null) Text(value!, style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ]),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(color: AccountColors.soft, fontSize: 12.5, height: 1.4)),
            ]),
          ),
        ),
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
    final c = ready ? AccountColors.ok : NwsbColors.goldLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: c.withValues(alpha: 0.14), border: Border.all(color: c.withValues(alpha: 0.6))),
      child: Text(label, style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0x12FFFFFF), border: Border.all(color: const Color(0x1AFFFFFF))),
    );
  }
}
