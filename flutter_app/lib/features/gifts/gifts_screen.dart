import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/brand_top_banner.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../economy/play_billing.dart';
import '../../widgets/four_banners.dart';
import '../../admin/template/editable.dart';
import '../economy/reward_fx.dart';
import 'gift_show.dart';
import '../programs/program_kit.dart';
import '../programs/program_heroes.dart';
import '../programs/program_router.dart';
import '../programs/gifts_program.dart';

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
                                  snap.data == null || snap.data == 'Play price' || snap.data!.isEmpty ? '\u20b9${widget.card.cents}' : snap.data!,
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

/// The one NowssB Gifts page: the gift showcase, Daily Spin, gift cards and
/// boxes on top; the programme tabs (Free Gifts · Send · Received · Sent ·
/// Redeem · Rules) below.
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
    final start = widget.initialTab ?? (widget.startOnRedeem ? 'redeem' : null);
    return EconomyPage(
      goodToKnow: kGiftsDisclaimer,
      title: 'NowssB Gifts',
      mark: NwsbMarks.gift,
      action: GestureDetector(
        // History: switch to Received and scroll the tabs into view.
        onTap: () => _tab('received'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, color: Colors.white, size: 15),
              SizedBox(width: 4),
              EditableLabel('gifts_screen.GiftsScreen', 'History', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        cacheExtent: 1600,
        children: [
          const GiftsHero(),
          const GiftShowcase(),
          const SizedBox(height: 16),
          const GiftWheel(),
          const SizedBox(height: 12),
          const RandomGiftButton(),
          const SizedBox(height: 16),
          const EditableLabel('gifts_screen.GiftsScreen', 'GIFT CARDS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const GiftPlanGrid(),
          const SizedBox(height: 12),
          const GiftOpenCard(),
          const SizedBox(height: 12),
          BrandTopBanner(
            bare: true,
            title: 'NowssB Gifts',
            mark: NwsbMarks.gift,
            onTap: () => showGiftCardSheet(context, kGiftCatalog.first.id),
          ),
          const SizedBox(height: 12),
          ColoredSplitPromoBanner(
            margin: EdgeInsets.zero,
            spec: SplitPromoSpec(
              title: 'Got a code?',
              cta: 'Redeem a gift',
              leftColor: const Color(0xFF3D2914),
              rightColor: const Color(0xFFE07A3D),
              art: SplitPromoArts.redLotus,
              onTap: () => _tab('redeem'),
            ),
          ),
          const SizedBox(height: 12),
          const FourBanners(
            current: Programme.gifts,
            splitTitle: 'NowssB Gifts',
            splitCta: 'Send a gift',
            blackTitle: 'A real purchase',
            blackSub: 'The code exists only after Play accepts it.',
          ),
          const SizedBox(height: 12),
          const BannerMix(seed: 5),
          const SizedBox(height: 16),
          ProgramTabsBlock(spec: kGiftsSpec, initialTab: start, scrollTo: start != null, goRef: _go, showDisclaimer: false),
        ],
      ),
    );
  }
}
