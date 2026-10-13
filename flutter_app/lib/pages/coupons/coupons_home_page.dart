/// Rebuilt Coupons Home (spec section 4), behind `newui_coupons`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/economy/coupon_screen.dart' show DailyScratchCard;
import '../../features/programs/program_router.dart';
import '../../widgets/sections/coupon_banner_section.dart';
import 'coupon_models.dart';
import 'coupon_popups.dart';
import 'coupons_glass.dart';
import 'coupons_motion.dart';

class CouponsHomePage extends StatefulWidget {
  const CouponsHomePage({super.key, this.repo = const DefaultCouponsRepo(), this.banner, this.onAllRewards, this.onScratch, this.animate = true});

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
      backgroundColor: const Color(0xFF1A1530),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Coupons', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: 'How it works', icon: const Icon(Icons.help_outline), onPressed: () => showCouponTerms(context)),
          IconButton(tooltip: 'History', icon: const Icon(Icons.history), onPressed: () {}),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
      body: Stack(children: [
        Positioned.fill(child: CouponsAura(animate: widget.animate)),
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            CouponGlass(radius: 22, padding: const EdgeInsets.all(6), child: widget.banner ?? const CouponBannerSection()),
            const SizedBox(height: 14),
            _Hero(newCount: newCount, animate: widget.animate),
            const SizedBox(height: 14),
            _codeField(),
            const SizedBox(height: 18),
            const Text('Save more with coupons', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Categories', _cats, kCouponCategories, (s) => _cats = s),
              _chip('Rarity', _rarity, [for (final r in CouponRarity.values) rarityName(r)], (s) => _rarity = s),
            ]),
            const SizedBox(height: 12),
            ..._list(),
          ]),
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
            Padding(padding: const EdgeInsets.only(bottom: 12), child: CalmEntrance(index: i, animate: widget.animate, child: _Ticket(c: l[i], onTap: () => showCouponDetail(context, l[i])))),
        ];
    }
  }

  Widget _codeField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CouponGlass(
          radius: 16,
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                key: const Key('coupon-code'),
                controller: _code,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter coupon code', hintStyle: TextStyle(color: Colors.white54)),
              ),
            ),
            TextButton(onPressed: _adding ? null : _add, child: Text(_adding ? 'Adding…' : 'Add coupon')),
          ]),
        ),
        if (_codeMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6),
            child: Text(_codeMsg!, style: TextStyle(color: _codeOk ? const Color(0xFF7CE3A6) : const Color(0xFFFF8A8A), fontSize: 13)),
          ),
      ]);

  Widget _chip(String label, Set<String> sel, List<String> opts, void Function(Set<String>) assign) => CouponGlass(
        radius: 20,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () async {
            final r = await showCouponFilter(context, label, opts, sel);
            if (r != null) setState(() => assign(r));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(sel.isEmpty ? label : '$label · ${sel.length}', style: const TextStyle(color: Colors.white)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
            ]),
          ),
        ),
      );

  Widget _bottomBar() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CouponGlass(
            lite: false,
            radius: 24,
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: _barBtn('All rewards', Icons.card_giftcard, _allRewards)),
              const SizedBox(width: 8),
              Expanded(child: _barBtn('Scratch cards', Icons.auto_awesome, _scratch)),
            ]),
          ),
        ),
      );

  Widget _barBtn(String t, IconData i, VoidCallback onTap) => CouponGlass(
        radius: 18,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(i, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Flexible(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      );
}

class _Hero extends StatefulWidget {
  const _Hero({required this.newCount, this.animate = true});
  final int newCount;
  final bool animate;
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduce && widget.animate) _a.repeat(reverse: true);
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CouponGlass(
        radius: 28,
        tint: kCouponViolet,
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          const Text('✦ Level up your savings', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('COUPONS FOR YOU', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          CouponGlass(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text('You have ${widget.newCount} new coupons', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 120,
            width: 200,
            child: AnimatedBuilder(animation: _a, builder: (_, __) => CustomPaint(painter: CouponArtPainter(t: _a.value))),
          ),
        ]),
      );
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.c, required this.onTap});
  final NwCoupon c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = rarityAccent(c.rarity);
    return Semantics(
      button: true,
      label: '${c.offer}. ${c.scope}',
      child: PressScale(
        onTap: onTap,
        child: CouponGlass(
          clipper: const TicketClipper(),
          tint: a,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [a, a.withValues(alpha: 0.4)])),
                child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 30),
              ),
              if (c.isNew)
                Positioned(
                  top: -6,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(10)),
                    child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(c.offer, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                Text(c.scope, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('View details >', style: TextStyle(color: Color(0xFF7FB2FF), fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({super.key, required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => CouponGlass(
        radius: 22,
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(icon, color: Colors.white70, size: 36),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          if (onRetry != null) ...[const SizedBox(height: 10), primaryPill('Try again', onRetry!)],
        ]),
      );
}
