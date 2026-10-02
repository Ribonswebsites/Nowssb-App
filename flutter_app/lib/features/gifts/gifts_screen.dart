import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'gift_show.dart';

class GiftItem {
  const GiftItem(this.id, this.label, this.cents);
  final String id;
  final String label;
  final int cents;
}

const kGiftCatalog = <GiftItem>[
  GiftItem('word', 'A word', 99),
  GiftItem('meaning', 'A meaning', 99),
  GiftItem('bundle', '10-word bundle', 999),
  GiftItem('resonance', 'Resonance', 499),
  GiftItem('frequency', 'Frequency', 999),
  GiftItem('frequency_x', 'Frequency X', 1999),
];

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

  Map<String, dynamic> toJson() => {
        'code': code,
        'itemId': itemId,
        'label': label,
        'cents': cents,
        'status': status,
        'createdAt': createdAt,
        'direction': direction,
        'note': note,
        'agentCode': agentCode,
      };

  static GiftRecord fromJson(Map<String, dynamic> json) => GiftRecord(
        code: json['code'] as String? ?? '',
        itemId: json['itemId'] as String? ?? '',
        label: json['label'] as String? ?? 'Gift',
        cents: (json['cents'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'unredeemed',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        direction: json['direction'] as String? ?? 'sent',
        note: json['note'] as String? ?? '',
        agentCode: json['agentCode'] as String? ?? '',
      );
}

class GiftBook extends ChangeNotifier {
  GiftBook._();
  static final instance = GiftBook._();

  static const _key = 'nwsb_gifts_v1';
  final List<GiftRecord> items = [];
  var ready = false;

  Future<void> load() async {
    if (ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        items
          ..clear()
          ..addAll(list.map((e) => GiftRecord.fromJson(Map<String, dynamic>.from(e as Map))));
      }
    } catch (_) {}
    _expire();
    ready = true;
    notifyListeners();
  }

  void _expire() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const window = 90 * 24 * 60 * 60 * 1000;
    for (final gift in items) {
      if (gift.status == 'unredeemed' && now - gift.createdAt > window) {
        gift.status = 'expired';
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<GiftRecord> send(GiftItem item, {String note = ''}) async {
    await load();
    final code = _code();
    final agent = EconomyMirror.instance.code;
    final gift = GiftRecord(
      code: code,
      itemId: item.id,
      label: item.label,
      cents: item.cents,
      status: 'unredeemed',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      direction: 'sent',
      note: note,
      agentCode: agent,
    );
    items.insert(0, gift);
    await _save();
    return gift;
  }

  Future<String> redeem(String raw) async {
    await load();
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return 'Enter the gift code.';
    GiftRecord? hit;
    for (final gift in items) {
      if (gift.code == code) {
        hit = gift;
        break;
      }
    }
    if (hit == null) return 'That code is not on this phone yet. Ask the sender to share it again.';
    if (hit.status == 'redeemed') return 'This gift is already open.';
    if (hit.status == 'expired') return 'This gift expired. Unopened gifts last 90 days.';
    hit.status = 'redeemed';
    items.insert(
      0,
      GiftRecord(
        code: hit.code,
        itemId: hit.itemId,
        label: hit.label,
        cents: hit.cents,
        status: 'redeemed',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        direction: 'received',
        note: hit.note,
        agentCode: hit.agentCode,
      ),
    );
    await _save();
    return '';
  }

  Future<GiftRecord> award(String itemId, String label, {int cents = 0}) async {
    await load();
    final gift = GiftRecord(
      code: _code(),
      itemId: itemId,
      label: label,
      cents: cents,
      status: 'redeemed',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      direction: 'received',
    );
    items.insert(0, gift);
    await _save();
    return gift;
  }

  String _code() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    final body = List.generate(6, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
    return 'GFT$body';
  }
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
              Text('History', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
              const GiftShowcase(),
              const SizedBox(height: 16),
              const GiftWheel(),
              const SizedBox(height: 12),
              const RandomGiftButton(),
              const SizedBox(height: 16),
              const Text('GIFT CARDS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
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
      case 'meaning':
        return NwsbMarks.meaning;
      case 'bundle':
        return NwsbMarks.book;
      case 'resonance':
        return NwsbMarks.sound;
      case 'frequency':
        return NwsbMarks.stages;
      default:
        return NwsbMarks.crown;
    }
  }

  Widget _send() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EconomyNote(
          'A gift is a real Play purchase sent as a code. Coins cannot be gifted. An agent code on the purchase still earns its commission, and the sale is labeled Gift purchase.',
        ),
        const SizedBox(height: 12),
        for (final item in kGiftCatalog)
          BlackOffer(
            title: item.label,
            mark: _giftMark(item.id),
            selected: _item.id == item.id,
            progress: _item.id == item.id ? 1 : 0,
            line: _item.id == item.id
                ? '1 of 1 selected · ${FxBook.instance.formatCents(item.cents)}'
                : '0 of 1 · ${FxBook.instance.formatCents(item.cents)}',
            onTap: () => setState(() => _item = item),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'A note for them (optional)',
            hintStyle: TextStyle(color: NwsbColors.mist),
          ),
        ),
        const SizedBox(height: 10),
        GoldButton(
          label: 'Pay on Play and create the code',
          onTap: () async {
            final sku = switch (_item.id) {
              'word' => 'nwsb_word',
              'meaning' => 'nwsb_meaning',
              'bundle' => 'nwsb_bundle_10',
              'resonance' => 'nwsb_sub_resonance',
              'frequency' => 'nwsb_sub_frequency',
              _ => 'nwsb_sub_frequency_x',
            };
            try {
              final result = await PlayCheckout.buy(
                callable: 'issueGift',
                productId: sku,
                payload: {'itemId': _item.id, 'note': _note.text.trim()},
              );
              final code = '${result['code'] ?? ''}';
              if (code.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: code));
              }
              if (!mounted) return;
              setState(() => _message = code.isEmpty
                  ? 'Play took the payment, but no code came back.'
                  : 'Code $code copied. It expires in 90 days if it stays unopened.');
            } on EconomyException catch (e) {
              if (!mounted) return;
              if (!EconomyApi.isMissing(e) && !e.message.toLowerCase().contains('play')) {
                setState(() => _message = e.message);
                return;
              }
              final gift = await GiftBook.instance.send(_item, note: _note.text.trim());
              if (!mounted) return;
              setState(() => _message = 'Code ${gift.code} saved on this phone.');
              final box = _item.id == 'frequency_x' || _item.id == 'bundle'
                  ? kGiftBoxes[2]
                  : _item.id == 'frequency' || _item.id == 'resonance'
                      ? kGiftBoxes[1]
                      : kGiftBoxes[0];
              await openGiftBox(context, box: box, prize: _item.label, itemId: _item.id, code: gift.code);
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
            hintText: 'GFT••••••',
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
              setState(() => _message = '${result['label'] ?? 'Gift'} is on this account.');
            } on EconomyException catch (e) {
              if (!mounted) return;
              if (!EconomyApi.isMissing(e)) {
                setState(() => _message = e.message);
                return;
              }
              final local = await GiftBook.instance.redeem(_code.text);
              if (!mounted) return;
              setState(() => _message = local.isEmpty ? 'That gift is on this account.' : local);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gift.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text(
                  '${gift.code} · ${gift.status} · ${FxBook.instance.formatCents(gift.cents)}',
                  style: const TextStyle(color: NwsbColors.mist, fontSize: 12),
                ),
                if (gift.agentCode.isNotEmpty)
                  Text(
                    'Gift purchase · agent ${gift.agentCode}',
                    style: const TextStyle(color: NwsbColors.gold, fontSize: 12),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

