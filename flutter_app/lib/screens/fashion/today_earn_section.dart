/// Zen home · "Your day" — one glass card under the greeting (Ribon, Nov 17).
///
/// Top row: the Quick action and the Today x/5 button, moved here from the
/// greeting card and the Begin Your Healing Path card so neither repeats.
/// Under it, one panel with the real numbers: coins, cash earned, words and
/// meanings sold, the target, and Your position (rank, place on this month's
/// sellers board, people under you). Every value is the server's, read
/// through [EconomyMirror] (wallet, payout, sellerStats docs and the summary)
/// or the monthly sellers board; nothing here is made up or counted locally.
library;

import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
import '../../features/circle/circle_screen.dart' show EarnTabsPage;
import '../../features/coins/coins_screen.dart';
import '../../features/earn/earnings_screen.dart';
import '../../features/economy/economy_api.dart';
import '../../features/economy/money.dart';
import '../../features/programs/reference_program.dart' show monthKeyIst;
import '../../features/progress/progress_popup.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';

const _mist = Color(0xB3FFFFFF);
const _faint = Color(0x8CFFFFFF);
const _eyebrow = TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: Color(0xFFE8D5A3));

class TodayEarnSection extends StatelessWidget {
  const TodayEarnSection({super.key, required this.onQuick});

  /// Opens the Quick action sheet (same as the old greeting button).
  final VoidCallback onQuick;

  void _push(BuildContext context, Widget page) {
    AppHaptics.medium();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final m = EconomyMirror.instance;
    return GlassWrap(
      key: const ValueKey('today-earn-section'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('YOUR DAY', style: _eyebrow),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _QuickButton(onTap: onQuick)),
            const SizedBox(width: 10),
            const Expanded(child: TodayProgressButton(light: false, stretch: true)),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0x1FFFFFFF)),
          const SizedBox(height: 12),
          const Text('YOUR EARNINGS', style: _eyebrow),
          const SizedBox(height: 10),
          ListenableBuilder(
            listenable: Listenable.merge([m, FxBook.instance]),
            builder: (context, _) => _panel(context, m),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context, EconomyMirror m) {
    final signedIn = m.live;
    final sold = m.wordsSold;
    final target = m.nextSellerTarget;
    final topRank = signedIn && target <= sold && sold > 0;
    final nextTitle = _rankTitleAt(m, target);
    final targetSub = !signedIn
        ? 'Sign in to see your target'
        : topRank
            ? 'Top rank reached'
            : '${(target - sold).clamp(0, 1 << 31)} more to ${nextTitle ?? 'the next rank'}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _Stat(
            key: const ValueKey('today-earn-coins'),
            icon: const Icon(Icons.toll_rounded, size: 16, color: NwsbColors.goldLight),
            label: 'Coins',
            value: '${m.coins}',
            sub: signedIn ? 'In your wallet' : 'Sign in to collect',
            onTap: () => _push(context, const CoinsScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            key: const ValueKey('today-earn-cash'),
            icon: const NwsbIcon(NwsbMarks.earn, size: 16, color: NwsbColors.goldLight),
            label: 'Cash earned',
            value: FxBook.instance.formatCents(m.lifetimeCents),
            sub: '${FxBook.instance.formatCents(m.cash)} available',
            onTap: () => _push(context, const EarningsScreen()),
          ),
        ),
      ])),
      const SizedBox(height: 10),
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: _Stat(
            key: const ValueKey('today-earn-sold'),
            icon: const NwsbIcon(NwsbMarks.wordBag, size: 16, color: NwsbColors.goldLight),
            label: 'Sold',
            value: '$sold',
            sub: sold == 0 ? 'No sales yet' : 'Words and meanings',
            onTap: () => _push(context, const EarnTabsPage(initialTab: 'sales')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            key: const ValueKey('today-earn-target'),
            icon: const NwsbIcon(NwsbMarks.trending, size: 16, color: NwsbColors.goldLight),
            label: 'Target',
            value: signedIn ? '$sold / $target' : '0',
            sub: targetSub,
            progress: !signedIn || target <= 0 ? 0 : (sold / target).clamp(0.0, 1.0),
            onTap: () => _push(context, const EarnTabsPage(initialTab: 'targets')),
          ),
        ),
      ])),
      const SizedBox(height: 10),
      _PositionButton(mirror: m, onTap: () => _push(context, const EarnTabsPage(initialTab: 'team'))),
    ]);
  }

  /// The rank whose word mark is [words], from the server's rank ladder in
  /// the economy summary (null when the ladder has not loaded).
  static String? _rankTitleAt(EconomyMirror m, int words) {
    final earn = m.summary['earn'];
    final ranks = earn is Map ? earn['ranks'] : null;
    if (ranks is! List) return null;
    for (final r in ranks) {
      if (r is Map && (r['minWords'] as num?)?.toInt() == words) {
        final t = '${r['title'] ?? ''}';
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }
}

/// Dark glass pill, the same shape and type as [TodayProgressButton].
class _QuickButton extends StatefulWidget {
  const _QuickButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<_QuickButton> {
  var _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(999);
    return Semantics(
      button: true,
      label: 'Quick action',
      child: GestureDetector(
        key: const ValueKey('today-earn-quick'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: () {
          AppHaptics.medium();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 110),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: GlassWrap.blurSigma, sigmaY: GlassWrap.blurSigma),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
                decoration: BoxDecoration(
                  color: _down ? const Color(0x33FFFFFF) : GlassWrap.fill,
                  borderRadius: r,
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const NwsbIcon(NwsbMarks.features, size: 15, color: Colors.black, strokeWidth: 1.9),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Quick', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1)),
                      Text('Shortcuts', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _mist, fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.2)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _mist),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
    this.progress,
  });
  final Widget icon;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $value, $sub',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: const Color(0x52000000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                icon,
                const SizedBox(width: 6),
                Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mist, fontSize: 11.5, fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right_rounded, size: 16, color: _faint),
              ]),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
              ),
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0x26FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(NwsbColors.goldLight),
                  ),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 4),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "Your position": rank title, place on this month's sellers board, and
/// how many people sit under you. Opens Earn · My Team.
class _PositionButton extends StatelessWidget {
  const _PositionButton({required this.mirror, required this.onTap});
  final EconomyMirror mirror;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = mirror;
    final uid = m.uid;
    if (!NwsbFirebase.ready || uid == null) return _body(m, null);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _board(monthKeyIst()),
      builder: (context, snap) => _body(m, _placeOf(snap.data?.data(), uid)),
    );
  }

  static final _boards = <String, Stream<DocumentSnapshot<Map<String, dynamic>>>>{};
  static Stream<DocumentSnapshot<Map<String, dynamic>>> _board(String month) =>
      _boards.putIfAbsent(month, () => FirebaseFirestore.instance.doc('leaderboards/sellers_$month').snapshots().asBroadcastStream());

  /// (place, sellers on the board), or null when you are not on it.
  static (int, int)? _placeOf(Map<String, dynamic>? doc, String uid) {
    final raw = doc?['entries'];
    if (raw is! Map) return null;
    int words(Object? v) => v is Map ? ((v['words'] as num?)?.toInt() ?? 0) : 0;
    final ids = raw.keys.map((e) => '$e').toList()..sort((a, b) => words(raw[b]).compareTo(words(raw[a])));
    final i = ids.indexOf(uid);
    return i < 0 ? null : (i + 1, ids.length);
  }

  Widget _body(EconomyMirror m, (int, int)? place) {
    final under = m.teamCount;
    final parts = <String>[
      if (!m.live)
        'Sign in to see your rank'
      else ...[
        place == null ? 'Not on this month\u2019s board' : '#${place.$1} of ${place.$2} this month',
        '$under ${under == 1 ? 'person' : 'people'} under you',
      ],
    ];
    final title = m.live ? m.sellerTier : 'Not ranked yet';
    return Semantics(
      button: true,
      label: 'Your position, $title, ${parts.join(', ')}',
      child: GestureDetector(
        key: const ValueKey('today-earn-position'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0x52000000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: ExcludeSemantics(
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: NwsbColors.goldLight, shape: BoxShape.circle),
                child: const NwsbIcon(NwsbMarks.crown, size: 19, color: Colors.black, strokeWidth: 1.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('Your position', style: TextStyle(color: _mist, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.15)),
                  const SizedBox(height: 2),
                  Text(parts.join(' \u00b7 '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _faint, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.3)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: _mist),
            ]),
          ),
        ),
      ),
    );
  }
}
