import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lottie/lottie.dart';

import '../../admin/layout/layout_sections.dart';

import '../../theme/tokens.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../economy/play_billing.dart';
import '../../widgets/hype_rail.dart';
import '../../admin/template/editable.dart';
import '../economy/reward_fx.dart';
import 'gift_show.dart';
import 'gift_unwrap.dart';
import 'spin_wheel.dart';
import '../programs/program_kit.dart';
import '../programs/program_heroes.dart';
import '../programs/program_router.dart';
import '../economy/shop_faces.dart';
import '../programs/gifts_program.dart';
import 'newui/gifts_flag.dart';
import 'newui/gifts_hub_page.dart';

class GiftItem {
  const GiftItem(this.id, this.label, this.cents, {this.productId = ''});
  final String id;
  final String label;

  /// Price in whole rupees from the live settings doc (Play shows the
  /// buyer's own currency at checkout).
  final int cents;
  final String productId;
}

/// Gift cards (Plan 6.3). The live list comes from config/economy
/// (`gifts.cards`); this mirrors the defaults until the summary loads.
const _kGiftDefaults = <GiftItem>[
  GiftItem('stage', 'Stage card', 49, productId: 'nowssb_gift_stage'),
  GiftItem('word', 'Word card', 99, productId: 'nowssb_gift_word'),
  GiftItem('bundle', 'Bundle card', 499, productId: 'nowssb_gift_bundle'),
  GiftItem('basic7', '7-day Basic', 79, productId: 'nowssb_gift_basic7'),
  GiftItem('ebook7', '7-day ebook', 49, productId: 'nowssb_gift_ebook7'),
  GiftItem('standard30', '30-day Standard', 499, productId: 'nowssb_gift_standard30'),
  GiftItem('premium30', '30-day Premium', 999, productId: 'nowssb_gift_premium30'),
  GiftItem('signature3', '3-day Signature', 199, productId: 'nowssb_gift_signature3'),
  GiftItem('ebook30', '30-day ebook pass', 149, productId: 'nowssb_gift_ebook30'),
  GiftItem('restore', 'Streak Restore', 99, productId: 'nowssb_gift_restore'),
];

List<GiftItem> get kGiftCatalog {
  final cards = (((EconomyMirror.instance.summary['config'] as Map?)?['gifts'] as Map?)?['cards'] as List?) ?? const [];
  if (cards.isEmpty) return _kGiftDefaults;
  return [
    for (final c in cards.whereType<Map>())
      GiftItem('${c['id']}', '${c['title']}', (c['priceINR'] as num?)?.toInt() ?? 0, productId: '${c['productId'] ?? ''}'),
  ];
}

/// Maps the gift grid / gallery ids to a gift card id.
String giftCardFor(String itemId) => switch (itemId) {
      'basic' => 'basic7',
      'ebook' => 'ebook7',
      'standard' => 'standard30',
      'premium' => 'premium30',
      'signature' => 'signature3',
      'Word gift' => 'word',
      'Subscription gift' => 'standard30',
      'Signature gift' => 'signature3',
      _ => itemId,
    };

class GiftRecord {
  GiftRecord({
    required this.code,
    required this.itemId,
    required this.label,
    required this.cents,
    required this.status,
    required this.createdAt,
    required this.direction,
    this.note = '',
    this.agentCode = '',
  });

  final String code;
  final String itemId;
  final String label;
  final int cents;
  String status;
  final int createdAt;
  final String direction;
  final String note;
  final String agentCode;
}

/// Gift history, straight from the server (users/{uid}/giftsSent and
/// giftsReceived via the economy summary). Nothing is minted on the phone.
class GiftBook extends ChangeNotifier {
  GiftBook._() {
    EconomyMirror.instance.addListener(notifyListeners);
  }
  static final instance = GiftBook._();

  bool get ready => EconomyMirror.instance.summary.isNotEmpty;

  List<GiftRecord> get items {
    final g = (EconomyMirror.instance.summary['gifts'] as Map?) ?? const {};
    GiftRecord row(Map m, String dir) => GiftRecord(
          code: '${m['code'] ?? ''}',
          itemId: '${m['card'] ?? ''}',
          label: '${m['title'] ?? 'Gift'}',
          cents: 0,
          status: '${m['status'] ?? (dir == 'received' ? 'redeemed' : 'active')}',
          createdAt: (m['at'] as num?)?.toInt() ?? 0,
          direction: dir,
          note: '${m['message'] ?? m['toName'] ?? m['fromName'] ?? ''}',
        );
    return [
      for (final m in ((g['sent'] as List?) ?? const []).whereType<Map>()) row(m, 'sent'),
      for (final m in ((g['received'] as List?) ?? const []).whereType<Map>()) row(m, 'received'),
    ];
  }

  Future<void> load() => EconomyMirror.instance.refresh();
}

/// Buy a gift card on Play and get its NWSB code (Plan 6.3).
Future<void> showGiftCardSheet(BuildContext context, String cardId) async {
  final cards = kGiftCatalog;
  final card = cards.firstWhere((c) => c.id == cardId, orElse: () => cards.first);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _GiftCardSheet(card: card),
  );
}

class _GiftCardSheet extends StatefulWidget {
  const _GiftCardSheet({required this.card});
  final GiftItem card;
  @override
  State<_GiftCardSheet> createState() => _GiftCardSheetState();
}

class _GiftCardSheetState extends State<_GiftCardSheet> {
  final _to = TextEditingController();
  final _from = TextEditingController();
  final _msg = TextEditingController();
  var _design = 'lotus';
  var _busy = false;
  String? _note;
  // Created once, so the price never flashes a loader on rebuild.
  late final Future<String> _price = widget.card.productId.isEmpty ? Future.value('') : PlayCheckout.priceLabel(widget.card.productId);

  static const _designs = <String, List<Color>>{
    'lotus': [Color(0xFF3B1528), Color(0xFFE07A9A)],
    'dawn': [Color(0xFF3A2410), Color(0xFFFFB86B)],
    'gold': [Color(0xFF1A1408), Color(0xFFE4C56A)],
    'night': [Color(0xFF0B1230), Color(0xFF5B8FB8)],
  };

  @override
  void initState() {
    super.initState();
    for (final c in [_to, _from, _msg]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _to.dispose();
    _from.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final r = await PlayCheckout.purchase({
        'kind': 'giftcard',
        'cardId': widget.card.id,
        'toName': _to.text.trim(),
        'fromName': _from.text.trim(),
        'message': _msg.text.trim(),
        'design': _design,
      });
      final granted = (r['granted'] as List?)?.whereType<Map>().firstWhere((g) => g['type'] == 'giftcard', orElse: () => const {}) ?? const {};
      final code = '${granted['code'] ?? ''}';
      if (code.isNotEmpty) await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      Navigator.of(context).pop();
      await openGiftBox(context, box: giftBoxFor(widget.card.id), prize: widget.card.label, itemId: widget.card.id, code: code.isEmpty ? null : code);
    } on EconomyException catch (e) {
      if (mounted) setState(() => _note = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final colors = _designs[_design]!;
    final to = _to.text.trim();
    final from = _from.text.trim();
    final msg = _msg.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xE6101010), Color(0xF5000000)]),
              border: Border(top: BorderSide(color: Color(0x55E4C56A))),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 44, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(9)))),
                  const EditableLabel('gifts_screen.GiftCardSheet', 'SEND A GIFT CARD', style: TextStyle(color: Color(0xFFE4C56A), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  // Live preview: what your friend will see.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    height: 196,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors[0], Colors.black, colors[0]]),
                      border: Border.all(color: colors[1].withValues(alpha: 0.75), width: 1.2),
                      boxShadow: [BoxShadow(color: colors[1].withValues(alpha: 0.28), blurRadius: 28, spreadRadius: -6)],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Opacity(opacity: 0.9, child: EditableImage.asset(giftBoxFor(widget.card.id).asset, height: 92, errorBuilder: (_, __, ___) => const SizedBox(), slot: 'gifts_screen.GiftCardSheet')),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              EditableLabel('gifts_screen.GiftCardSheet', 'NOWSSB GIFT', style: TextStyle(color: colors[1], fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              FutureBuilder<String>(
                                future: _price,
                                builder: (context, snap) => Text(
                                  snap.data == null || snap.data == 'Play price' || snap.data!.isEmpty ? FxBook.instance.formatRupees(widget.card.cents) : snap.data!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Text(widget.card.label, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.05)),
                            const SizedBox(height: 6),
                            Text(to.isEmpty ? 'For someone you choose' : 'For $to', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            SizedBox(
                              width: 220,
                              child: Text(msg.isEmpty ? 'Your message appears here.' : '\u201c$msg\u201d', maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: msg.isEmpty ? const Color(0x66FFFFFF) : Colors.white, fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.3)),
                            ),
                            const SizedBox(height: 4),
                            Text(from.isEmpty ? '' : '\u2014 $from', style: TextStyle(color: colors[1], fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    for (final d in _designs.entries)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _design = d.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(colors: [d.value[0], d.value[1].withValues(alpha: 0.7)]),
                              border: Border.all(color: _design == d.key ? Colors.white : const Color(0x33FFFFFF), width: _design == d.key ? 2 : 1),
                            ),
                            child: Text(d.key[0].toUpperCase() + d.key.substring(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  _field(_to, 'Their name (optional)', Icons.person_outline),
                  _field(_from, 'Your name (optional)', Icons.edit_outlined),
                  _field(_msg, 'A short message (optional)', Icons.chat_bubble_outline, lines: 3),
                  const SizedBox(height: 4),
                  const EditableLabel('gifts_screen.GiftCardSheet',
                      'The code exists only after Google Play accepts the payment. It is valid for a year. Unopened cards can be cancelled within 7 days. Coins cannot be gifted.',
                      style: TextStyle(color: NwsbColors.mist, fontSize: 11.5, height: 1.4)),
                  const SizedBox(height: 14),
                  GoldButton(label: _busy ? 'Waiting for Google Play…' : 'Pay on Play and create the code', onTap: _busy ? null : _buy),
                  if (_note != null) ...[const SizedBox(height: 10), EconomyNote(_note!)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          maxLines: lines,
          maxLength: lines > 1 ? 280 : 40,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: NwsbColors.mist),
            counterText: '',
            prefixIcon: Icon(icon, color: const Color(0xFFE4C56A), size: 18),
            filled: true,
            fillColor: const Color(0x14FFFFFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x33FFFFFF))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x33FFFFFF))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4C56A))),
          ),
        ),
      );
}

/// The one NowssB Gifts page. Rebuilt Oct 12 (calm, one focus): a single
/// hero gift in a pool of gold light with today's real box state and one
/// Open action, a quiet line of real counts, then the programme tabs
/// (Free Gifts · Send · Received · Sent · Redeem · Rules). No banners,
/// carousels or rails. Opening plays the unwrap moment (gift_unwrap.dart).
class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key, this.startOnRedeem = false, this.initialTab});
  final bool startOnRedeem;
  final String? initialTab;

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final _go = ValueNotifier<void Function(String)?>(null);

  @override
  void initState() {
    super.initState();
    GiftBook.instance.load();
  }

  @override
  void dispose() {
    _go.dispose();
    super.dispose();
  }

  void _tab(String id) => _go.value?.call(id);

  @override
  Widget build(BuildContext context) {
    // Rebuilt page behind `newui_gifts` (on for everyone; remote false = kill switch).
    if (newUiGiftsEnabled()) {
      return GiftsNewUiPage(initialTab: widget.initialTab ?? (widget.startOnRedeem ? 'redeem' : null));
    }
    final offers = [for (final g in kGiftCatalog) GiftOffer(g.id, g.label, 'Gift card', g.cents)];
    return GiftsFace(offers: offers, onClaim: (o) => showGiftCardSheet(context, o.id));
  }

  Widget _retired(BuildContext context) {
    final start = widget.initialTab ?? (widget.startOnRedeem ? 'redeem' : null);
    return EconomyPage(
      title: 'NowssB Gifts',
      mark: NwsbMarks.gift,
      action: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Good to know',
          visualDensity: VisualDensity.compact,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: NwsbColors.plate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: NwsbColors.gold.withValues(alpha: .35))),
              content: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  for (final t in [kGiftsDisclaimer, ...kGiftsRules])
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.45))),
                ]),
              ),
            ),
          ),
          icon: const Icon(Icons.info_outline_rounded, color: NwsbColors.goldLight, size: 20),
        ),
      ]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          _TodayGiftHero(onTab: _tab),
          const SizedBox(height: 16),
          _QuietCounts(onTab: _tab),
          const SizedBox(height: 16),
          // The page's original banner video: the Daily Spin (spin-wheel.mp4).
          const GiftWheel(),
          const SizedBox(height: 20),
          _GiftTabs(initial: start, goRef: _go),
        ],
      ),
    );
  }
}

/// Hero (layout from Ribon's scratch-card ref; colours and art are the
/// original NowssB ones): a frosted glass card with the original gift banner
/// art (assets/gifts/gift-hero.png), one strip with one action.
class _TodayGiftHero extends StatefulWidget {
  const _TodayGiftHero({required this.onTab});
  final void Function(String) onTab;
  @override
  State<_TodayGiftHero> createState() => _TodayGiftHeroState();
}

class _TodayGiftHeroState extends State<_TodayGiftHero> {
  bool _busy = false;

  Future<void> _open(bool opened) async {
    if (opened) return widget.onTab('free');
    if (_busy || EconomyMirror.instance.summary.isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await EconomyApi.call('openDailyBox');
      if (mounted) await GiftUnwrapMoment.show(context, title: '${r['title'] ?? 'Today\u2019s gift'}', items: giftItemsIn(r));
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    }
    await EconomyMirror.instance.refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final s = EconomyMirror.instance.summary;
        final opened = sMap(s['today'])['boxOpened'] != null;
        final waiting = giftsWaiting(s);
        return Column(children: [
          GestureDetector(
            onTap: () => _open(opened),
            child: GlassWrap(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(fit: StackFit.expand, children: [
                    EditableImage.asset('assets/gifts/gift-hero.png', fit: BoxFit.cover, alignment: const Alignment(0, -.75), slot: 'gifts_screen.GiftsHero',
                        errorBuilder: (_, __, ___) => const SizedBox()),
                    IgnorePointer(child: Opacity(opacity: .6, child: Lottie.asset(kGiftSparkleLottie, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _busy ? 'Opening\u2026' : opened ? 'Opened today' : 'Tap to open',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NwsbColors.goldLight, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: .4),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => widget.onTab('free'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(color: NwsbColors.gold.withValues(alpha: .14), border: Border.all(color: NwsbColors.gold.withValues(alpha: .45)), borderRadius: BorderRadius.circular(30)),
              child: Text('$waiting waiting', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]);
      },
    );
  }
}

/// Three real numbers, no cards: unopened boxes, received, sent.
class _QuietCounts extends StatelessWidget {
  const _QuietCounts({required this.onTab});
  final void Function(String) onTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GiftBook.instance,
      builder: (context, _) {
        final s = EconomyMirror.instance.summary;
        final boxes = giftsWaiting(s);
        final items = GiftBook.instance.items;
        final rec = items.where((g) => g.direction == 'received').length;
        final sent = items.where((g) => g.direction == 'sent').length;
        Widget cell(String n, String label, String tab, String img) => Expanded(
              child: GestureDetector(
                onTap: () => onTab(tab),
                child: Container(
                  height: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x26FFFFFF))),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(img, fit: BoxFit.cover),
                    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xFA000000)], stops: [.15, .8]))),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n, style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                        Text(label, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
        return Row(children: [
          cell('$boxes', 'Waiting', 'free', 'assets/gifts/box-gold.webp'),
          cell('$rec', 'Received', 'received', 'assets/gifts/box-black.webp'),
          cell('$sent', 'Sent', 'sent', 'assets/gifts/box-black.webp'),
        ]);
      },
    );
  }
}

/// One real source for "waiting": unopened server boxes plus today's box
/// if it is still closed. Used by the pill and the Waiting tile.
int giftsWaiting(Map<String, dynamic> s) =>
    sList(s['boxes']).length + (s.isNotEmpty && sMap(s['today'])['boxOpened'] == null ? 1 : 0);

/// Items the server granted, from a reward response (gift box effect,
/// items list, granted map or plain coins).
List<Map<String, dynamic>> giftItemsIn(Map<String, dynamic> r) {
  List<Map<String, dynamic>> asItems(Object? v) => sList(v);
  var items = asItems(r['items']);
  for (final e in sList(r['effects'])) {
    if (items.isEmpty && e['kind'] == 'giftbox') items = asItems(e['items']);
  }
  if (items.isEmpty && r['granted'] is Map) items = [sMap(r['granted'])];
  final coins = coinsIn(r);
  if (items.isEmpty && coins > 0) items = [{'type': 'coins', 'coins': coins, 'label': '$coins coins'}];
  return items;
}

/// Calm tab switcher: one compact horizontal pill row, then the real tab.
class _GiftTabs extends StatefulWidget {
  const _GiftTabs({this.initial, required this.goRef});
  final String? initial;
  final ValueNotifier<void Function(String)?> goRef;
  @override
  State<_GiftTabs> createState() => _GiftTabsState();
}

class _GiftTabsState extends State<_GiftTabs> {
  static final _tabs = kGiftsSpec.tabs.where((t) => t.id != 'rules').toList();
  late String _id = _tabs.any((t) => t.id == widget.initial) ? widget.initial! : 'free';
  final _anchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.goRef.value = _go;
    if (widget.initial != null) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _go(String id) {
    if (id == 'rules') id = 'free';
    setState(() => _id = id);
    _reveal();
  }

  void _reveal() {
    final c = _anchor.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tabs.firstWhere((t) => t.id == _id);
    return ProgramTabsScope(
      go: _go,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          key: _anchor,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: NwsbColors.plate.withValues(alpha: .55), border: Border.all(color: NwsbColors.gold.withValues(alpha: .25)), borderRadius: BorderRadius.circular(30)),
          child: Row(children: [
            for (final t in _tabs)
              Expanded(
                child: GestureDetector(
                  onTap: () => _go(t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.id == _id ? NwsbColors.gold : Colors.transparent, borderRadius: BorderRadius.circular(26)),
                    child: Text(t.title,
                        maxLines: 1,
                        style: TextStyle(color: t.id == _id ? NwsbColors.plate : NwsbColors.mist, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        ListenableBuilder(
          listenable: EconomyMirror.instance,
          builder: (context, _) {
            final s = EconomyMirror.instance.summary;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ...layoutChildren(context, 'gifts.program.${tab.id}', tab.build(context, s)),
            ]);
          },
        ),
      ]),
    );
  }
}
