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
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        decoration: const BoxDecoration(
          color: Color(0xF2000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                EditableImage.asset(giftBoxFor(widget.card.id).asset, height: 64, errorBuilder: (_, __, ___) => const SizedBox(width: 64), slot: 'gifts_screen.GiftCardSheet'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.card.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    FutureBuilder<String>(
                      future: widget.card.productId.isEmpty ? Future.value('') : PlayCheckout.priceLabel(widget.card.productId),
                      builder: (context, snap) => Text(
                        snap.data == null || snap.data == 'Play price' || snap.data!.isEmpty ? '\u20b9${widget.card.cents} on Google Play' : '${snap.data} on Google Play',
                        style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              const EditableLabel('gifts_screen.GiftCardSheet',
                  'The code exists only after Google Play accepts the payment. It is valid for a year. Unopened cards can be cancelled within 7 days. Coins cannot be gifted.',
                  style: TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              _field(_to, 'Their name (optional)'),
              _field(_from, 'Your name (optional)'),
              _field(_msg, 'A short message (optional)', lines: 3),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final d in const ['lotus', 'dawn', 'gold', 'night'])
                  ChoiceChip(
                    label: Text(d[0].toUpperCase() + d.substring(1)),
                    selected: _design == d,
                    onSelected: (_) => setState(() => _design = d),
                  ),
              ]),
              const SizedBox(height: 14),
              GoldButton(label: _busy ? 'Waiting for Google Play…' : 'Pay on Play and create the code', onTap: _busy ? null : _buy),
              if (_note != null) ...[const SizedBox(height: 10), EconomyNote(_note!)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c,
          maxLines: lines,
          maxLength: lines > 1 ? 280 : 40,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: NwsbColors.mist), counterText: ''),
        ),
      );
}

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key, this.startOnRedeem = false});
  final bool startOnRedeem;

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  var _tab = 0;
  GiftItem _item = kGiftCatalog.first;
  final _note = TextEditingController();
  final _code = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.startOnRedeem) _tab = 1;
    GiftBook.instance.load();
  }

  @override
  void dispose() {
    _note.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      goodToKnow: kGiftsDisclaimer,
      title: 'NowssB Gifts',
      mark: NwsbMarks.gift,
      action: GestureDetector(
        onTap: () => setState(() => _tab = 3),
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
      child: ListenableBuilder(
        listenable: GiftBook.instance,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const FourBanners(
                splitTitle: 'NowssB Gifts',
                splitCta: 'Send a gift',
                blackTitle: 'A real purchase',
                blackSub: 'The code exists only after Play accepts it.',
              ),
              const SizedBox(height: 12),
              ProgramLink(title: 'NowssB Gifts program', sub: 'Free boxes, gift cards, rules and history', mark: NwsbMarks.gift, page: () => const GiftsProgramPage()),
              const SizedBox(height: 12),
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
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(height: 12),
              ColoredSplitPromoBanner(
                margin: EdgeInsets.zero,
                spec: SplitPromoSpec(
                  title: 'NowssB Gifts',
                  cta: 'Send a gift',
                  leftColor: const Color(0xFF3D2914),
                  rightColor: const Color(0xFFE07A3D),
                  art: SplitPromoArts.redLotus,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              const SizedBox(height: 12),
              const BannerMix(seed: 5),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip('Send', 0),
                  const SizedBox(width: 8),
                  _chip('Redeem', 1),
                  const SizedBox(width: 8),
                  _chip('Sent', 2),
                  const SizedBox(width: 8),
                  _chip('Received', 3),
                ],
              ),
              const SizedBox(height: 14),
              if (_tab == 0) _send(),
              if (_tab == 1) _redeem(),
              if (_tab == 2) _history('sent'),
              if (_tab == 3) _history('received'),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, int index) {
    final on = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tab = index;
          _message = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? NwsbColors.goldLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? NwsbColors.goldLight : const Color(0x33FFFFFF)),
          ),
          child: EditableLabel('gifts_screen.GiftsScreen',
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: on ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _giftMark(String id) {
    switch (id) {
      case 'word':
        return NwsbMarks.word;
      case 'stage':
        return NwsbMarks.stages;
      case 'bundle':
        return NwsbMarks.book;
      case 'basic7':
        return NwsbMarks.sound;
      case 'ebook7':
      case 'ebook30':
        return NwsbMarks.ebook;
      case 'signature3':
        return NwsbMarks.signature;
      case 'restore':
        return NwsbMarks.flame;
      default:
        return NwsbMarks.crown;
    }
  }

  Widget _send() {
    final catalog = kGiftCatalog;
    if (!catalog.any((c) => c.id == _item.id)) _item = catalog.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EconomyNote(
          'A gift is a real Play purchase sent as a code. Coins cannot be gifted. A link on the purchase still earns its commission, and the sale is labeled Gift purchase.',
        ),
        const SizedBox(height: 12),
        for (final item in catalog)
          BlackOffer(
            title: item.label,
            mark: _giftMark(item.id),
            selected: _item.id == item.id,
            progress: _item.id == item.id ? 1 : 0,
            line: _item.id == item.id ? '1 of 1 selected · \u20b9${item.cents}' : '0 of 1 · \u20b9${item.cents}',
            onTap: () => setState(() => _item = item),
          ),
        const SizedBox(height: 8),
        GoldButton(label: 'Write the card and pay on Play', onTap: () => showGiftCardSheet(context, _item.id)),
        if (_message != null) ...[
          const SizedBox(height: 10),
          EconomyNote(_message!),
        ],
      ],
    );
  }

  Widget _redeem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EconomyNote('Enter the code, or open the link they sent. You will see the item before it lands on this account.'),
        const SizedBox(height: 10),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 1.4),
          decoration: const InputDecoration(
            hintText: 'NWSB-XXXX-XXXX',
            hintStyle: TextStyle(color: NwsbColors.mist),
          ),
        ),
        const SizedBox(height: 10),
        GoldButton(
          label: 'Preview and redeem',
          onTap: () async {
            try {
              final result = await EconomyApi.call('redeemGift', {'code': _code.text.trim()});
              if (!mounted) return;
              setState(() => _message = '${(result['granted'] as Map?)?['label'] ?? result['title'] ?? 'Gift'} is on this account.');
              final g = result['granted'];
              await GiftBoxOpening.show(context,
                  box: 'gold',
                  title: '${result['title'] ?? 'A gift for you'}${'${result['fromName'] ?? ''}'.isEmpty ? '' : ' · from ${result['fromName']}'}',
                  items: g is Map ? [Map<String, dynamic>.from(g)] : const []);
            } on EconomyException catch (e) {
              if (!mounted) return;
              setState(() => _message = e.message);
            }
          },
        ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          EconomyNote(_message!),
        ],
      ],
    );
  }

  Widget _history(String direction) {
    final rows = GiftBook.instance.items.where((g) => g.direction == direction).toList();
    if (rows.isEmpty) {
      return EconomyNote(
        direction == 'sent'
            ? 'No gifts sent yet. Create a code and it shows here with its status.'
            : 'No gifts received yet. Redeem a code and it shows here.',
      );
    }
    return Column(
      children: [
        for (final gift in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gift.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(
                        '${gift.code} · ${gift.status}${gift.createdAt > 0 ? ' · ${_date(gift.createdAt)}' : ''}',
                        style: const TextStyle(color: NwsbColors.mist, fontSize: 12),
                      ),
                      if (gift.note.isNotEmpty) Text(gift.note, style: const TextStyle(color: NwsbColors.gold, fontSize: 12)),
                    ],
                  ),
                ),
                if (direction == 'sent' && gift.status == 'active') ...[
                  IconButton(
                    tooltip: 'Copy code',
                    onPressed: () => Clipboard.setData(ClipboardData(text: gift.code)),
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                  ),
                  TextButton(
                    onPressed: () => runEconomy(context, () async {
                      final r = await EconomyApi.call('cancelGift', {'code': gift.code});
                      if (mounted) setState(() => _message = '${r['note'] ?? 'Cancelled.'}');
                    }),
                    child: const EditableLabel('gifts_screen.GiftsScreen', 'Cancel', style: TextStyle(color: NwsbColors.goldLight)),
                  ),
                ],
              ],
            ),
          ),
        if (_message != null) EconomyNote(_message!),
      ],
    );
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day}/${d.month}/${d.year}';
  }
}
