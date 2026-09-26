/// NowssB Earn, Resell Shop, and Networking.
///
/// Coins, listings, and referral codes live in [EarnWallet] on this phone.
/// The cash share of a price is recorded, not charged — a card or UPI
/// capture still needs a payment key.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/earn_wallet.dart';
import '../data/firebase.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EarnScaffold(
      eyebrow: 'NowssB Earn',
      title: 'Coins',
      child: ListenableBuilder(
        listenable: Listenable.merge([
          EarnWallet.instance,
          PracticeProgress.instance,
        ]),
        builder: (context, _) {
          final w = EarnWallet.instance;
          final streak = PracticeProgress.instance.streak;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _BalanceCard(wallet: w, streak: streak),
              const SizedBox(height: 14),
              const _Note(
                'Coins pay at most 30% of a price. The rest is recorded as cash. Charging a card or UPI needs a payment key — nothing is taken from a bank from this screen.',
              ),
              const SizedBox(height: 22),
              const _Eyebrow('HOW YOU EARN'),
              const SizedBox(height: 8),
              const _Rate('Complete login', '+25 once, then +10 each day'),
              const _Rate('Buy a word or meaning', '+8 coins'),
              const _Rate('Buy a package', '+40 coins'),
              const _Rate('Buy a 10-word bundle', '+90 coins'),
              const _Rate('1-day streak', '+10 each day the streak holds'),
              const _Rate('10-day streak', '+100 once'),
              const _Rate('Open the player the first time', '+25 once'),
              const SizedBox(height: 22),
              const _Eyebrow('SPEND'),
              const SizedBox(height: 8),
              _GoldBtn(
                label: 'Buy a word',
                onTap: () => _pickWord(context),
              ),
              const SizedBox(height: 8),
              _GoldBtn(
                label: 'Buy a meaning',
                onTap: () => _pickMeaning(context),
                filled: false,
              ),
              const SizedBox(height: 8),
              _GoldBtn(
                label: '10-word bundle · ₹490',
                onTap: () => _buyBundle(context),
                filled: false,
              ),
              const SizedBox(height: 8),
              _GoldBtn(
                label: 'Meaning package',
                onTap: () => _buyPackage(context),
                filled: false,
              ),
              const SizedBox(height: 18),
              for (final plan in EarnWallet.plans) ...[
                _PlanRow(plan: plan),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _GoldBtn(
                label: streak < 1
                    ? 'Restore streak · ₹${EarnWallet.restorePrice}'
                    : 'Streak is $streak · restore if it breaks',
                onTap: () => _restore(context),
                filled: false,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _GoldBtn(
                      label: 'Resell Shop',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SellShopScreen(),
                        ),
                      ),
                      filled: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GoldBtn(
                      label: 'Network',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NetworkScreen(),
                        ),
                      ),
                      filled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _Eyebrow('ACTIVITY'),
              const SizedBox(height: 8),
              _ActivityList(items: w.activity),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickWord(BuildContext context) async {
    final owned = EarnWallet.instance.owned.map((o) => o.id).toSet();
    final words = ContentStore.instance.library
        .where((w) => !owned.contains('word:${w.key}'))
        .take(80)
        .toList();
    if (words.isEmpty) {
      _toast(context, 'No words left to buy on this phone.');
      return;
    }
    final picked = await showModalBottomSheet<Word>(
      context: context,
      backgroundColor: const Color(0xFF0C1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Buy a word',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final w in words)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(w.word, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  w.deva.isEmpty ? w.benefit : w.deva,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                ),
                trailing: Text(
                  '₹${_ask(w.price)}',
                  style: const TextStyle(color: NwsbColors.goldLight),
                ),
                onTap: () => Navigator.pop(ctx, w),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final price = _ask(picked.price);
    final id = 'word:${picked.key}';
    final err = await showCoinPaySheet(
      context,
      title: picked.word,
      price: price,
      onPay: (use) => EarnWallet.instance.pay(
        title: picked.word,
        price: price,
        useCoins: use,
        kind: 'Word',
        id: id,
        image: picked.img,
      ),
    );
    if (!context.mounted) return;
    _paid(context, err, '${picked.word} is yours.');
  }

  Future<void> _pickMeaning(BuildContext context) async {
    final owned = EarnWallet.instance.owned.map((o) => o.id).toSet();
    final rows = ContentStore.instance.meanings
        .where((m) => !owned.contains('meaning:${m.key}'))
        .take(80)
        .toList();
    if (rows.isEmpty) {
      _toast(context, 'No meanings left to buy on this phone.');
      return;
    }
    final picked = await showModalBottomSheet<Meaning>(
      context: context,
      backgroundColor: const Color(0xFF0C1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'Buy a meaning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final m in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  m.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                ),
                trailing: Text(
                  '₹${_ask(m.price)}',
                  style: const TextStyle(color: NwsbColors.goldLight),
                ),
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final price = _ask(picked.price);
    final err = await showCoinPaySheet(
      context,
      title: picked.name,
      price: price,
      onPay: (use) => EarnWallet.instance.pay(
        title: picked.name,
        price: price,
        useCoins: use,
        kind: 'Meaning',
        id: 'meaning:${picked.key}',
        image: picked.img,
      ),
    );
    if (!context.mounted) return;
    _paid(context, err, '${picked.name} is yours.');
  }

  Future<void> _buyBundle(BuildContext context) async {
    final owned = EarnWallet.instance.owned.map((o) => o.id).toSet();
    final words = ContentStore.instance.library
        .where((w) => !owned.contains('word:${w.key}'))
        .take(10)
        .toList();
    if (words.length < 10) {
      _toast(context, 'You need 10 unowned words for this bundle.');
      return;
    }
    final err = await showCoinPaySheet(
      context,
      title: '10-word bundle',
      price: 490,
      onPay: (use) async {
        final fail = await EarnWallet.instance.pay(
          title: '10-word bundle',
          price: 490,
          useCoins: use,
          kind: 'Bundle',
          id: 'bundle:10',
        );
        if (fail != null) return fail;
        await EarnWallet.instance.rememberOwned([
          for (final w in words)
            OwnedPiece(
              id: 'word:${w.key}',
              title: w.word,
              kind: 'Word',
              price: _ask(w.price),
              image: w.img,
            ),
        ]);
        return null;
      },
    );
    if (!context.mounted) return;
    _paid(context, err, '10 words are in your library.');
  }

  Future<void> _buyPackage(BuildContext context) async {
    final owned = EarnWallet.instance.owned.map((o) => o.id).toSet();
    final rows = ContentStore.instance.meanings
        .where((m) => !owned.contains('meaning:${m.key}'))
        .take(3)
        .toList();
    if (rows.isEmpty) {
      _toast(context, 'No meanings left for a package.');
      return;
    }
    final price = rows.fold<int>(0, (n, m) => n + _ask(m.price));
    final err = await showCoinPaySheet(
      context,
      title: 'Meaning package',
      price: price,
      onPay: (use) async {
        final fail = await EarnWallet.instance.pay(
          title: 'Meaning package',
          price: price,
          useCoins: use,
          kind: 'Package',
          id: 'package:meanings',
        );
        if (fail != null) return fail;
        await EarnWallet.instance.rememberOwned([
          for (final m in rows)
            OwnedPiece(
              id: 'meaning:${m.key}',
              title: m.name,
              kind: 'Meaning',
              price: _ask(m.price),
              image: m.img,
            ),
        ]);
        return null;
      },
    );
    if (!context.mounted) return;
    _paid(context, err, 'Package added to your library.');
  }

  Future<void> _restore(BuildContext context) async {
    final err = await showCoinPaySheet(
      context,
      title: 'Restore streak',
      price: EarnWallet.restorePrice,
      onPay: (use) => EarnWallet.instance.restoreStreak(useCoins: use),
    );
    if (!context.mounted) return;
    _paid(context, err, 'Yesterday is back on the streak.');
  }
}

class SellShopScreen extends StatefulWidget {
  const SellShopScreen({super.key});

  @override
  State<SellShopScreen> createState() => _SellShopScreenState();
}

class _SellShopScreenState extends State<SellShopScreen> {
  Future<void> _accept() async {
    await EarnWallet.instance.acceptTerms();
  }

  Future<void> _list(OwnedPiece piece) async {
    final price = TextEditingController(text: '${piece.price.round() < 1 ? 49 : piece.price.round()}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1220),
        title: Text('List ${piece.title}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: price,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Price in ₹',
            labelStyle: TextStyle(color: NwsbColors.gold),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('List')),
        ],
      ),
    );
    final raw = num.tryParse(price.text.trim()) ?? 0;
    price.dispose();
    if (ok != true || !mounted) return;
    final err = await EarnWallet.instance.listForSale(piece, raw);
    if (!mounted) return;
    _toast(context, err ?? '${piece.title} is listed at ₹${raw.round()}.');
  }

  Future<void> _sell(ResaleListing listing) async {
    final cut = (listing.price * EarnWallet.instance.commissionPercent / 100).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1220),
        title: const Text('Confirm sale', style: TextStyle(color: Colors.white)),
        content: Text(
          'This removes ${listing.title} from your library and pays $cut coins '
          '(${EarnWallet.instance.commissionPercent}% of ₹${listing.price.round()}). '
          'The buyer’s cash is not collected here.',
          style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm sale')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await EarnWallet.instance.confirmSale(listing.id);
    if (!mounted) return;
    _toast(context, err ?? 'Sale recorded. Commission is in your coins.');
  }

  @override
  Widget build(BuildContext context) {
    return _EarnScaffold(
      eyebrow: 'Resell Shop',
      title: 'Sell',
      child: ListenableBuilder(
        listenable: EarnWallet.instance,
        builder: (context, _) {
          final w = EarnWallet.instance;
          final listed = w.listings.map((l) => l.id).toSet();
          final mine = w.owned.where((o) => !listed.contains(o.id)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              const _Note(
                'List a word or meaning you own. Confirming a sale on this phone removes it and pays your commission in coins. Buyer cash needs a payment key, so it is not charged here.',
              ),
              const SizedBox(height: 16),
              const _Eyebrow('TERMS'),
              const SizedBox(height: 8),
              const _Card(
                child: Text(
                  'You can only sell what this profile owns. One listing per item. '
                  'Commission starts at 5% and rises at 100, 300, 500 and 1,000 words sold. '
                  'Each 20 promo posts adds 1%, up to 5% more. '
                  'A confirmed sale is final on this phone. '
                  'NowssB can remove a listing that breaks these terms.',
                  style: TextStyle(color: Color(0xCCFFFFFF), height: 1.45, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              if (!w.termsAccepted)
                _GoldBtn(label: 'Accept terms', onTap: _accept)
              else
                const _Note('Terms accepted on this profile.'),
              const SizedBox(height: 22),
              _Eyebrow('YOUR LISTINGS · ${w.commissionPercent}%'),
              const SizedBox(height: 8),
              if (w.listings.isEmpty)
                const _Note('Nothing listed yet.')
              else
                for (final listing in w.listings) ...[
                  _Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${listing.kind} · ₹${listing.price.round()}',
                                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _GoldBtn(
                          label: 'Confirm sale',
                          expand: false,
                          onTap: () => _sell(listing),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 18),
              const _Eyebrow('OWNED'),
              const SizedBox(height: 8),
              if (mine.isEmpty)
                const _Note('Buy a word or meaning in NowssB Earn, then list it here.')
              else
                for (final piece in mine) ...[
                  _Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                piece.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                piece.kind,
                                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _GoldBtn(
                          label: 'List',
                          expand: false,
                          filled: w.termsAccepted,
                          onTap: w.termsAccepted ? () => _list(piece) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _note;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    _toast(context, 'Copied $value');
  }

  Future<void> _redeem() async {
    final msg = await EarnWallet.instance.redeemCode(_code.text);
    if (!mounted) return;
    setState(() => _note = msg);
  }

  Future<void> _mint() async {
    final err = await EarnWallet.instance.mintInviteCode();
    if (!mounted) return;
    _toast(context, err ?? 'A new invite code is on this profile.');
  }

  Future<void> _post() async {
    await EarnWallet.instance.addPost(_title.text, _body.text);
    _title.clear();
    _body.clear();
    if (!mounted) return;
    _toast(context, 'Post counted. Commission rises every 20 posts.');
  }

  @override
  Widget build(BuildContext context) {
    return _EarnScaffold(
      eyebrow: 'Networking',
      title: 'Promote',
      child: ListenableBuilder(
        listenable: EarnWallet.instance,
        builder: (context, _) {
          final w = EarnWallet.instance;
          final target = w.nextTarget;
          final progress = target == 0 ? 1.0 : (w.wordsSold / target).clamp(0.0, 1.0);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR CODE',
                      style: TextStyle(
                        color: NwsbColors.gold,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      w.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'nowssb.com/r/${w.code}',
                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _GoldBtn(label: 'Copy code', onTap: () => _copy(w.code)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GoldBtn(label: 'Generate another invite code', onTap: _mint, filled: false),
              if (w.inviteCodes.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final code in w.inviteCodes) ...[
                  _Card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        _GoldBtn(label: 'Copy', expand: false, onTap: () => _copy(code), filled: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 18),
              const _Eyebrow('USE A FRIEND’S CODE'),
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('NSB……'),
              ),
              const SizedBox(height: 8),
              _GoldBtn(label: 'Apply code', onTap: _redeem, filled: false),
              if (_note != null) ...[
                const SizedBox(height: 8),
                _Note(_note!),
              ],
              if (w.referredBy.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Note('This profile used ${w.referredBy}.'),
              ],
              if (!NwsbFirebase.ready) ...[
                const SizedBox(height: 8),
                const _Note(
                  'Firebase is not connected on this build, so a friend’s phone cannot be paid yet. No new API key — the existing NowssB Firebase project is enough when it is on.',
                ),
              ],
              const SizedBox(height: 22),
              const _Eyebrow('PROMOTION'),
              const SizedBox(height: 8),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.wordsSold} words sold · ${w.commissionPercent}% · rank ${w.rank}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${w.posts} posts · next word target $target',
                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0x22FFFFFF),
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Ladder(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                child: Text(
                  w.referralSubs >= 5
                      ? '${w.referralSubs} people subscribed with your code. You earn 20% in coins on each one from the 5th onward, plus a free plan or coins if you already hold that plan.'
                      : '${w.referralSubs} subscribed with your code. At 5 you also get 20% of each subscription in coins. Before that: a free plan, or coins if you already have that plan.',
                  style: const TextStyle(color: Color(0xCCFFFFFF), height: 1.4, fontSize: 13),
                ),
              ),
              const SizedBox(height: 22),
              const _Eyebrow('POST'),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDeco('What you are promoting'),
              ),
              const SizedBox(height: 8),
              _GoldBtn(label: 'Publish post', onTap: _post),
              if (w.promoPosts.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final post in w.promoPosts.take(8)) ...[
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.body,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x24FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x24FFFFFF)),
        ),
      );
}

class _Ladder extends StatelessWidget {
  const _Ladder();

  @override
  Widget build(BuildContext context) {
    final sold = EarnWallet.instance.wordsSold;
    const steps = <(int, String)>[
      (0, '5%'),
      (100, '8%'),
      (300, '12%'),
      (500, '15%'),
      (1000, '20%'),
    ];
    return Row(
      children: [
        for (final step in steps)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sold >= step.$1 ? NwsbColors.goldLight : const Color(0x33FFFFFF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.$1 == 0 ? 'Start' : '${step.$1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  step.$2,
                  style: const TextStyle(color: NwsbColors.gold, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan});
  final EarnPlan plan;

  @override
  Widget build(BuildContext context) {
    final current = EarnWallet.instance.holdsPlan(plan.name);
    return _GoldBtn(
      label: current ? '${plan.name} · current' : '${plan.name} · ₹${plan.rupees}',
      filled: !current,
      onTap: current
          ? null
          : () async {
              final err = await showCoinPaySheet(
                context,
                title: plan.name,
                price: plan.rupees,
                onPay: (use) => EarnWallet.instance.pay(
                  title: plan.name,
                  price: plan.rupees,
                  useCoins: use,
                  kind: 'Subscription',
                  id: 'plan:${plan.name}',
                ),
              );
              if (!context.mounted) return;
              _paid(context, err, '${plan.name} is your plan.');
            },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet, required this.streak});
  final EarnWallet wallet;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${wallet.coins}',
            style: const TextStyle(
              color: NwsbColors.goldLight,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'NowssB Coins',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${wallet.plan} · streak $streak · code ${wallet.code}',
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${wallet.wordsSold} sold · ${wallet.commissionPercent}% · ${wallet.referralSubs} referrals · ${wallet.posts} posts',
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});
  final List<EarnActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Note('Nothing yet. Sign in, practice, or buy — it lands here.');
    }
    return Column(
      children: [
        for (final item in items.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.detail,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                        ),
                        Text(
                          _ago(item.at),
                          style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.coins == 0 ? '—' : (item.coins > 0 ? '+${item.coins}' : '${item.coins}'),
                    style: TextStyle(
                      color: item.coins < 0 ? const Color(0xFFFF8A80) : NwsbColors.goldLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<String?> showCoinPaySheet(
  BuildContext context, {
  required String title,
  required num price,
  required Future<String?> Function(bool useCoins) onPay,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0C1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PaySheet(title: title, price: price, onPay: onPay),
  );
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.title, required this.price, required this.onPay});
  final String title;
  final num price;
  final Future<String?> Function(bool useCoins) onPay;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  bool _use = true;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final q = EarnWallet.instance.quote(widget.price);
    final coins = _use ? q.coins : 0;
    final cash = widget.price.round() - coins;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Price ₹${widget.price.round()} · coins up to ${q.maxCoins} (30%)',
            style: const TextStyle(color: Color(0xCCFFFFFF)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _use && q.maxCoins > 0,
            onChanged: q.maxCoins == 0 ? null : (v) => setState(() => _use = v),
            title: Text(
              coins == 0 ? 'No coins applied' : 'Use $coins coins',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Cash recorded ₹${cash < 0 ? 0 : cash}',
              style: const TextStyle(color: NwsbColors.goldLight),
            ),
          ),
          const Text(
            'The cash share is saved as an order. A real card or UPI charge needs Razorpay or Play Billing.',
            style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          _GoldBtn(
            label: _busy ? 'Working…' : 'Confirm',
            onTap: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final err = await widget.onPay(_use && coins > 0);
                    if (!context.mounted) return;
                    Navigator.pop(context, err ?? '');
                  },
          ),
        ],
      ),
    );
  }
}

class _EarnScaffold extends StatelessWidget {
  const _EarnScaffold({
    required this.eyebrow,
    required this.title,
    required this.child,
  });
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: const TextStyle(
                              color: NwsbColors.gold,
                              fontSize: 10,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: child,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.4),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: NwsbColors.gold,
        fontSize: 10,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate(this.title, this.detail);
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.end,
              style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldBtn extends StatelessWidget {
  const _GoldBtn({
    required this.label,
    required this.onTap,
    this.filled = true,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: filled ? NwsbColors.ink : NwsbColors.goldLight,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
    return Material(
      color: filled ? NwsbColors.goldLight : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: filled ? Colors.transparent : const Color(0x44E8D5A3)),
          ),
          alignment: expand ? Alignment.center : null,
          child: labelWidget,
        ),
      ),
    );
  }
}

int _ask(num price) {
  final n = price.round();
  return n > 0 ? n : 49;
}

String _ago(int at) {
  if (at <= 0) return '';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at));
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _paid(BuildContext context, String? err, String ok) {
  if (err == null) return;
  _toast(context, err.isEmpty ? ok : err);
}
