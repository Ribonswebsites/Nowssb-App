/// Rebuilt Coupons Home (spec section 4), behind `newui_coupons`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/economy/coupon_screen.dart' show DailyScratchCard;
import '../../features/programs/program_router.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/sections/coupon_banner_section.dart';
import 'coupon_models.dart';
import 'coupon_popups.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import 'coupons_glass.dart';
import 'coupons_motion.dart';

class CouponsHomePage extends StatefulWidget {
  const CouponsHomePage({super.key, this.repo = const DefaultCouponsRepo(), this.banner, this.onAllRewards, this.onScratch, this.animate = true, this.background});

  /// Defaults to the app's original background ([AppBackdrop]); tests stub it.
  final Widget? background;

  /// Hero float loop; off in tests and when the OS asks for reduced motion.
  final bool animate;

  final CouponsRepo repo;

  /// The existing banner (lib/widgets/sections/coupon_banner_section.dart), reused as is.
  final Widget? banner;
  final VoidCallback? onAllRewards, onScratch;

  @override
  State<CouponsHomePage> createState() => _CouponsHomePageState();
}

enum _Load { loading, ready, error, offline }

class _CouponsHomePageState extends State<CouponsHomePage> {
  final _code = TextEditingController();
  var _state = _Load.loading;
  var _all = <NwCoupon>[];
  var _cats = <String>{};
  var _rarity = <String>{};
  String? _codeMsg;
  var _codeOk = false;
  var _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = _Load.loading);
    try {
      final l = await widget.repo.load();
      if (mounted) setState(() => (_all = l, _state = _Load.ready));
    } on CouponsOffline {
      if (mounted) setState(() => _state = _Load.offline);
    } catch (_) {
      if (mounted) setState(() => _state = _Load.error);
    }
  }

  Future<void> _add() async {
    final c = _code.text.trim();
    if (c.isEmpty) {
      setState(() => (_codeMsg = 'Type a coupon code first.', _codeOk = false));
      return;
    }
    setState(() => _adding = true);
    CouponCodeResult r;
    try {
      r = await widget.repo.addCode(c);
    } on CouponsOffline {
      r = const CouponCodeResult(false, "You're offline. Try again when you're connected.");
    } catch (_) {
      r = const CouponCodeResult(false, 'Something went wrong. Try again.');
    }
    if (!mounted) return;
    if (r.ok) {
      HapticFeedback.mediumImpact();
      _code.clear();
      _load();
    }
    setState(() => (_codeMsg = r.message, _codeOk = r.ok, _adding = false));
  }

  List<NwCoupon> get _shown => _all.where((c) {
        if (c.status != CouponStatus.active) return false;
        if (_cats.isNotEmpty && !_cats.contains(c.category)) return false;
        if (_rarity.isNotEmpty && !_rarity.contains(rarityName(c.rarity))) return false;
        return true;
      }).toList();

  void _allRewards() => widget.onAllRewards != null ? widget.onAllRewards!() : Programmes.open(context, Programme.rewards);

  void _scratch() {
    if (widget.onScratch != null) return widget.onScratch!();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFF1A1530),
        appBar: AppBar(title: const Text('Scratch cards')),
        body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: DailyScratchCard()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final newCount = _all.where((c) => c.isNew && c.status == CouponStatus.active).length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GlassTopBar(title: 'My Coupons', actions: [
        IconButton(tooltip: 'How it works', icon: const Icon(Icons.help_outline, color: Colors.white), onPressed: () => showCouponTerms(context)),
        IconButton(tooltip: 'History', icon: const Icon(Icons.history, color: Colors.white), onPressed: () {}),
      ]),
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: GlassBottomBar(left: 'All rewards', right: 'Scratch cards', onLeft: _allRewards, onRight: _scratch),
      body: Stack(children: [
        // The app's original background (video/still); nothing of our own.
        Positioned.fill(child: widget.background ?? const AppBackdrop()),
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 72, 16, 110), children: [
              NGlass(radius: NTokens.rCard, padding: const EdgeInsets.all(6), child: widget.banner ?? const CouponBannerSection()),
              const SizedBox(height: 16),
              MeditationCard(
                title: 'Coupons for you',
                subtitle: 'You have $newCount new coupons. Every purchase earns a free one.',
                image: NCircles.of('lotus'),
                secondary: 'Level up your savings',
                cta: 'How it works',
                onCta: () => showCouponTerms(context),
                dots: 3,
              ),
              const SizedBox(height: 16),
              _codeField(),
              const SizedBox(height: 20),
              const Text('SAVE MORE WITH COUPONS', style: TextStyle(color: NTokens.mint, fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip('Categories', _cats, kCouponCategories, (s) => _cats = s),
                _chip('Rarity', _rarity, [for (final r in CouponRarity.values) rarityName(r)], (s) => _rarity = s),
              ]),
              const SizedBox(height: 14),
              ..._list(),
            ]),
          ),
        ),
      ]),
    );
  }

  List<Widget> _list() {
    switch (_state) {
      case _Load.loading:
        return const [Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(key: Key('coupons-loading'))))];
      case _Load.error:
        return [_StateBox(key: const Key('coupons-error'), icon: Icons.error_outline, text: "Couldn't load your coupons.", onRetry: _load)];
      case _Load.offline:
        return [_StateBox(key: const Key('coupons-offline'), icon: Icons.wifi_off, text: "You're offline. Your coupons will show when you're back.", onRetry: _load)];
      case _Load.ready:
        final l = _shown;
        if (l.isEmpty) {
          return [
            _StateBox(
              key: const Key('coupons-empty'),
              icon: Icons.confirmation_number_outlined,
              text: _all.isEmpty ? 'No coupons yet. Every purchase earns a free one.' : 'No coupons match these filters.',
            ),
          ];
        }
        return [
          for (var i = 0; i < l.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: CalmEntrance(index: i, animate: widget.animate, child: _ticket(l[i], i))),
        ];
    }
  }

  Widget _codeField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NGlass(
          radius: NTokens.rPill,
          padding: const EdgeInsets.only(left: 18, right: 6, top: 4, bottom: 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                key: const Key('coupon-code'),
                controller: _code,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter coupon code', hintStyle: TextStyle(color: NTokens.textLo)),
              ),
            ),
            GlassPill(label: _adding ? 'Adding…' : 'Add coupon', style: PillStyle.white, dense: true, onTap: _adding ? null : _add),
          ]),
        ),
        if (_codeMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(_codeMsg!, style: TextStyle(color: _codeOk ? NTokens.mint : NTokens.coral, fontSize: 13)),
          ),
      ]);

  Widget _ticket(NwCoupon c, int i) => Semantics(
        button: true,
        label: '${c.offer}. ${c.scope}',
        child: CouponListCard(
          label: c.label,
          offer: c.offer,
          image: NCircles.at(i + 4),
          isNew: c.isNew,
          rarity: Rarity.values[c.rarity.index],
          expired: c.status == CouponStatus.expired,
          onTap: () => showCouponDetail(context, c),
        ),
      );

  Widget _chip(String label, Set<String> sel, List<String> opts, void Function(Set<String>) assign) => GlassChip(
        label: sel.isEmpty ? label : '$label · ${sel.length}',
        selected: sel.isNotEmpty,
        dropdown: true,
        onTap: () async {
          final r = await showCouponFilter(context, label, opts, sel);
          if (r != null) setState(() => assign(r));
        },
      );
}

class _StateBox extends StatelessWidget {
  const _StateBox({super.key, required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rCard,
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(icon, color: NTokens.textLo, size: 36),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          if (onRetry != null) ...[const SizedBox(height: 12), GlassPill(label: 'Try again', style: PillStyle.white, onTap: onRetry)],
        ]),
      );
}
