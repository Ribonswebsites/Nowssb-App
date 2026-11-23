/// The NowssB Earn layout (Ribon, Nov 23, redo): the sports-betting
/// reference one-to-one, in the NowssB glass (dark panes, white ink, our
/// gold where the reference is yellow, black for emphasis). Every icon sits
/// in a WHITE CIRCLE badge.
///
///  * [EarnHey]          round avatar, "Hey," over the bold name, a bell.
///  * [EarnBalanceCard]  one card, two balances, a round badge on its top
///                       edge (cash earned · coins with the real coin).
///  * [EarnActions]      Payout (gold glass pill) · Invite (black pill), each
///                       with its white circle icon.
///  * [EarnSectionTitle] "Programmes" bold with a small See all.
///  * [EarnStatCard]     the event card: title + status pill, a side mark
///                       and label each side of a big central figure, then
///                       a row of three white odds chips ([EarnOdd]).
///  * [EarnStatGrid]     the Statistics card: a gold glass card of cells,
///                       one black highlighted cell.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../account/account_kit.dart' show TileRow, TileBadge, accountFieldStyle;

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
import '../../screens/notifications_sheet.dart' show showNotificationsSheet;
import '../../theme/tokens.dart';
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import '../../widgets/nwsb_icon.dart';

const kEarnMuted = Color(0x99FFFFFF);
const kEarnSoft = Color(0xCCFFFFFF);
const kEarnInk = Color(0xFF0B0B10);
const kEarnGlass = Color(0x17FFFFFF);
const kEarnLine = Color(0x26FFFFFF);
const kEarnDark = Color(0xF20B0B10);
const kEarnGold = NwsbColors.goldLight;
const kEarnRadius = 22.0;
const kEarnTileRadius = 16.0;

/// The grey of the small labels on white chips.
const kEarnGrey = Color(0xFF8A8A93);

/// Our gold glass: where the reference fills a card yellow.
const kEarnGoldGlass = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(kEarnRadius)),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xD9A9853A), Color(0xBF7F6227), Color(0xD95C461A)],
  ),
  border: Border.fromBorderSide(BorderSide(color: Color(0x99F1D58A))),
  boxShadow: [BoxShadow(color: Color(0x40000000), offset: Offset(0, 12), blurRadius: 30)],
);

/// The dark NowssB glass pane.
const kEarnDarkGlass = BoxDecoration(
  color: Color(0x8C14141C),
  borderRadius: BorderRadius.all(Radius.circular(kEarnRadius)),
  border: Border.fromBorderSide(BorderSide(color: kEarnLine)),
  boxShadow: [BoxShadow(color: Color(0x40000000), offset: Offset(0, 12), blurRadius: 30)],
);

/// Tests: the name the header greets.
String? debugEarnName;

/// Tests: the avatar photo URL ('' for none).
String? debugEarnPhoto;

/// The account's first name, or null when there is none.
String? earnFirstName() {
  if (debugEarnName != null) return debugEarnName!.isEmpty ? null : debugEarnName;
  if (!NwsbFirebase.ready) return null;
  final n = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
  if (n.isEmpty) return null;
  return n.split(RegExp(r'\s+')).first;
}

String earnHey() {
  final n = earnFirstName();
  return n == null ? 'Hey there' : 'Hey, $n';
}

String? _photo() {
  if (debugEarnPhoto != null) return debugEarnPhoto!.isEmpty ? null : debugEarnPhoto;
  if (!NwsbFirebase.ready) return null;
  final p = FirebaseAuth.instance.currentUser?.photoURL ?? '';
  return p.isEmpty ? null : p;
}

/// A WHITE CIRCLE badge holding a dark mark, icon or [child].
class EarnCircle extends StatelessWidget {
  const EarnCircle({super.key, this.mark, this.icon, this.size = 40, this.child, this.outlined = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;

  /// A hairline ring so the circle reads on a white pill.
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: const Color(0x2E0B0B10)) : null,
        ),
        child: child ??
            (mark != null
                ? NwsbIcon(mark!, size: size * 0.46, color: kEarnInk, strokeWidth: 1.9)
                : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.5, color: kEarnInk)),
      );
}

/// Kept for callers: now the white circle badge.
class EarnSquare extends StatelessWidget {
  const EarnSquare({super.key, this.mark, this.icon, this.size = 36, this.child, this.dark = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;
  final bool dark;
  @override
  Widget build(BuildContext context) => EarnCircle(mark: mark, icon: icon, size: size, outlined: !dark, child: child);
}

/// A tappable white circle (back, bell, expand, close).
class EarnCircleButton extends StatelessWidget {
  const EarnCircleButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 42});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: EarnCircle(icon: icon, size: size),
        ),
      );
}

/// The back button as a white circle.
class EarnBackSquare extends StatelessWidget {
  const EarnBackSquare({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EarnCircleButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: onTap);
}

/// The small round avatar: the account photo, else the initial.
class EarnAvatar extends StatelessWidget {
  const EarnAvatar({super.key, this.size = 44, this.name});
  final double size;
  final String? name;
  @override
  Widget build(BuildContext context) {
    final n = (name ?? earnFirstName() ?? '').trim();
    final initial = Text(n.isEmpty ? 'N' : n.characters.first.toUpperCase(),
        style: TextStyle(color: kEarnInk, fontSize: size * 0.42, fontWeight: FontWeight.w800, height: 1));
    final url = _photo();
    return Container(
      key: const ValueKey('earn-avatar'),
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: url == null
          ? initial
          : Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initial),
    );
  }
}

/// The reference header: [back], the round avatar, "Hey," small with the
/// name bold under it, and the bell (or [trailing]) at the far right.
class EarnHey extends StatelessWidget {
  const EarnHey({super.key, this.eyebrow, this.onBack, this.trailing, this.title, this.bell = true, this.name});

  /// Kept for callers; the reference has no eyebrow.
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Overrides the greeting's name line.
  final String? title;

  /// Overrides the account's first name.
  final String? name;

  /// Shows the bell when there is no [trailing].
  final bool bell;

  @override
  Widget build(BuildContext context) {
    final n = name ?? earnFirstName();
    return Row(children: [
      if (onBack != null) ...[EarnBackSquare(onTap: onBack!), const SizedBox(width: 10)],
      EarnAvatar(name: n),
      const SizedBox(width: 12),
      Expanded(
        child: Semantics(
          label: title ?? earnHey(),
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Hey,', maxLines: 1, style: TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
            Text(title ?? n ?? 'there',
                key: const ValueKey('earn-hey'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3)),
          ]),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 10), trailing!]
      else if (bell) ...[
        const SizedBox(width: 10),
        EarnCircleButton(key: const ValueKey('earn-bell'), icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => showNotificationsSheet(context)),
      ],
    ]);
  }
}

/// A glass pane in the Earn shape: dark glass, or our gold glass.
class EarnPane extends StatelessWidget {
  const EarnPane({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.dark = false, this.gold = false});
  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: gold
            ? kEarnGoldGlass
            : dark
                ? kEarnDarkGlass.copyWith(color: kEarnDark)
                : kEarnDarkGlass,
        child: child,
      );
}

/// One side of [EarnBalanceCard].
class EarnBalance {
  const EarnBalance({required this.label, required this.value, this.sub, this.coin = false, this.mark, this.onTap, this.key});
  final String label;
  final Widget value;
  final String? sub;
  final bool coin;
  final String? mark;
  final VoidCallback? onTap;
  final Key? key;
}

/// One card, two balances side by side, a white circle badge centred on
/// its top edge (the reference's Current / Bonus balance card).
class EarnBalanceCard extends StatelessWidget {
  const EarnBalanceCard({super.key, required this.left, required this.right, this.badge = Icons.swap_horiz_rounded});
  final EarnBalance left;
  final EarnBalance right;
  final IconData badge;

  Widget _side(EarnBalance b, {required bool end}) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(
            child: Text(b.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kEarnSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          if (b.onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kEarnMuted),
          ],
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (b.coin) ...[const NwsbCoinDisc(size: 26), const SizedBox(width: 7)],
            b.value,
          ]),
        ),
        if (b.sub != null) ...[
          const SizedBox(height: 4),
          Text(b.sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnMuted, fontSize: 11.5, height: 1.3)),
        ],
      ]),
    );
    if (b.onTap == null) return body;
    return Semantics(
      button: true,
      label: b.label,
      child: GestureDetector(
        key: b.key,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          b.onTap!();
        },
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        // Room for the badge riding the top edge.
        padding: const EdgeInsets.only(top: 15),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            key: const ValueKey('earn-balance-card'),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: kEarnDarkGlass.copyWith(borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _side(left, end: false)),
                Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: kEarnLine),
                Expanded(child: _side(right, end: true)),
              ]),
            ),
          ),
          Positioned(
            top: -15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 3))]),
                child: EarnCircle(icon: badge, size: 30),
              ),
            ),
          ),
        ]),
      );
}

/// The big number style of balances and stat cards.
const kEarnBig = TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8);

/// A reference pill button: our gold glass when [primary] (the yellow
/// Deposit), else black (Withdraw); a white circle icon at its left.
class EarnActionButton extends StatelessWidget {
  const EarnActionButton({super.key, required this.label, required this.icon, required this.onTap, this.primary = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(color: primary ? const Color(0x99F1D58A) : const Color(0x33FFFFFF)),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        shape: shape,
        clipBehavior: Clip.antiAlias,
        color: primary ? Colors.transparent : const Color(0xF2000000),
        child: Ink(
          decoration: primary
              ? const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xE6B8933F), Color(0xE68A6A2A)]),
                )
              : null,
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 7, 10, 7),
                child: Row(children: [
                  EarnCircle(icon: icon, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two equal pills side by side: Payout (gold) and Invite (black).
class EarnActions extends StatelessWidget {
  const EarnActions({super.key, required this.onPayout, required this.onInvite});
  final VoidCallback onPayout;
  final VoidCallback onInvite;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: EarnActionButton(key: const ValueKey('earn-action-payout'), label: 'Payout', icon: Icons.arrow_downward_rounded, onTap: onPayout)),
        const SizedBox(width: 10),
        Expanded(child: EarnActionButton(key: const ValueKey('earn-action-invite'), label: 'Invite', icon: Icons.arrow_upward_rounded, onTap: onInvite, primary: false)),
      ]);
}

/// A section header: bold title at the left, small See all at the right.
class EarnSectionTitle extends StatelessWidget {
  const EarnSectionTitle(this.title, {super.key, this.onSeeAll, this.action = 'See all'});
  final String title;
  final VoidCallback? onSeeAll;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
        child: Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
          if (onSeeAll != null)
            Semantics(
              button: true,
              label: '$action, $title',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.selection();
                  onSeeAll!();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(action, style: const TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),
      );
}

enum EarnStatus { ongoing, upcoming, reached, off }

/// The reference status pill: Ongoing green, Upcoming orange, Reached our
/// gold, off a quiet glass.
class EarnStatusPill extends StatelessWidget {
  const EarnStatusPill(this.status, {super.key, this.text});
  final EarnStatus status;
  final String? text;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      EarnStatus.ongoing => (const Color(0xFF2FBF71), Colors.white, 'Ongoing'),
      EarnStatus.upcoming => (const Color(0xFFF2994A), Colors.white, 'Upcoming'),
      EarnStatus.reached => (kEarnGold, kEarnInk, 'Reached'),
      EarnStatus.off => (const Color(0x33FFFFFF), Colors.white, 'Not yet'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text ?? label, maxLines: 1, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
    );
  }
}

/// A small glass chip: a mark (or the real coin) and a short line.
class EarnChip extends StatelessWidget {
  const EarnChip(this.text, {super.key, this.mark, this.icon, this.coin = false});
  final String text;
  final String? mark;
  final IconData? icon;
  final bool coin;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (coin)
            const NwsbCoinDisc(size: 18)
          else if (mark != null || icon != null)
            EarnCircle(mark: mark, icon: icon, size: 18, outlined: true),
          if (coin || mark != null || icon != null) const SizedBox(width: 5),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnInk, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// The reference odds chip: a white pill, a small grey label and a bold
/// figure ("1x  1.8").
class EarnOdd {
  const EarnOdd(this.label, this.value, {this.coin = false, this.icon});
  final String label;
  final String value;
  final bool coin;
  final IconData? icon;
}

class EarnOddChip extends StatelessWidget {
  const EarnOddChip(this.odd, {super.key});
  final EarnOdd odd;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(odd.label, maxLines: 1, style: const TextStyle(color: kEarnGrey, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            if (odd.coin) ...[const NwsbCoinDisc(size: 15), const SizedBox(width: 3)],
            if (odd.icon != null) ...[Icon(odd.icon, size: 14, color: kEarnInk), const SizedBox(width: 2)],
            Text(odd.value, maxLines: 1, style: const TextStyle(color: kEarnInk, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

/// A row of up to three odds chips, equal widths.
class EarnOddsRow extends StatelessWidget {
  const EarnOddsRow(this.odds, {super.key});
  final List<EarnOdd> odds;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < odds.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: EarnOddChip(odds[i])),
        ],
      ]);
}

/// A plain progress bar (white on a glass track).
class EarnBar extends StatelessWidget {
  const EarnBar(this.value, {super.key, this.height = 6, this.color = Colors.white});
  final double value;
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0x33FFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ]),
        ),
      );
}

/// One side of [EarnStatCard]: the crest (a white circle badge) and its
/// name under it.
class EarnSide {
  const EarnSide(this.label, {this.mark, this.icon, this.coin = false});
  final String label;
  final String? mark;
  final IconData? icon;
  final bool coin;
}

/// The reference event card: title and status pill on top, a crest each
/// side of a big central figure (small line above, small line under), and
/// a row of three white odds chips. Gold glass unless [gold] is off.
class EarnStatCard extends StatelessWidget {
  const EarnStatCard({
    super.key,
    required this.title,
    required this.number,
    this.eyebrow,
    this.under,
    this.left,
    this.right,
    this.status,
    this.odds = const [],
    this.onTap,
    this.gold = true,
  });
  final String title;
  final String number;
  final String? eyebrow;
  final String? under;
  final EarnSide? left;
  final EarnSide? right;
  final Widget? status;
  final List<EarnOdd> odds;
  final VoidCallback? onTap;
  final bool gold;

  Widget _side(EarnSide s) => Column(mainAxisSize: MainAxisSize.min, children: [
        s.coin ? const NwsbCoinDisc(size: 46) : EarnCircle(mark: s.mark, icon: s.icon, size: 46),
        const SizedBox(height: 7),
        Text(s.label,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
      ]);

  @override
  Widget build(BuildContext context) {
    final card = EarnPane(
      gold: gold,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.2)),
          ),
          if (status != null) ...[const SizedBox(width: 8), status!],
          if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kEarnSoft)],
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(flex: 3, child: left == null ? const SizedBox() : _side(left!)),
          Expanded(
            flex: 4,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (eyebrow != null)
                FittedBox(fit: BoxFit.scaleDown, child: Text(eyebrow!, maxLines: 1, style: const TextStyle(color: kEarnSoft, fontSize: 11.5, fontWeight: FontWeight.w600))),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, child: Text(number, maxLines: 1, style: kEarnBig.copyWith(fontSize: 34))),
              if (under != null) ...[
                const SizedBox(height: 2),
                Text(under!, maxLines: 3, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.25)),
              ],
            ]),
          ),
          Expanded(flex: 3, child: right == null ? const SizedBox() : _side(right!)),
        ]),
        if (odds.isNotEmpty) ...[const SizedBox(height: 14), EarnOddsRow(odds)],
      ]),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap!();
        },
        child: card,
      ),
    );
  }
}

/// One cell of [EarnStatGrid]: a label on top, the figure at the bottom
/// ([second] at the bottom right, the reference's home · away pair).
class EarnStat {
  const EarnStat(this.label, this.value, {this.sub, this.second, this.highlight = false, this.key, this.onTap});
  final VoidCallback? onTap;
  final String label;
  final String value;
  final String? second;
  final String? sub;
  final bool highlight;
  final Key? key;
}

/// The reference Statistics card: [title] over a grid of glass cells on
/// our gold glass, one BLACK highlighted cell. Without a [title] it is the
/// bare grid.
class EarnStatGrid extends StatelessWidget {
  const EarnStatGrid(this.stats, {super.key, this.columns = 2, this.title = 'Statistics'});
  final List<EarnStat> stats;
  final int columns;
  final String? title;

  Widget _tile(EarnStat s) {
    final tile = _plain(s);
    if (s.onTap == null) return KeyedSubtree(key: s.key, child: tile);
    return Semantics(
      key: s.key,
      button: true,
      label: '${s.label}, ${s.value}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          s.onTap!();
        },
        child: tile,
      ),
    );
  }

  Widget _plain(EarnStat s) => Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
        decoration: BoxDecoration(
          color: s.highlight ? const Color(0xFF050507) : const Color(0x2E000000),
          borderRadius: BorderRadius.circular(kEarnTileRadius),
          border: Border.all(color: s.highlight ? const Color(0xFF050507) : const Color(0x33FFFFFF)),
          boxShadow: s.highlight ? const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text(s.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
            ),
            if (s.onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kEarnSoft),
          ]),
          const Spacer(),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.value, maxLines: 1, style: TextStyle(color: Colors.white, fontSize: s.highlight ? 24 : 20, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.4)),
              ),
            ),
            if (s.second != null) ...[
              const SizedBox(width: 6),
              Text(s.second!, maxLines: 1, style: const TextStyle(color: kEarnSoft, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ]),
          if (s.sub != null) ...[
            const SizedBox(height: 3),
            Text(s.sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 11, height: 1.3)),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += columns) {
      final row = stats.sublist(i, (i + columns).clamp(0, stats.length));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: 8),
            Expanded(child: j < row.length ? _tile(row[j]) : const SizedBox()),
          ],
        ]),
      ));
      if (i + columns < stats.length) rows.add(const SizedBox(height: 8));
    }
    final grid = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows);
    if (title == null) return grid;
    return EarnPane(
      gold: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ),
        grid,
      ]),
    );
  }
}

/// A slim loading line in place of the old thinking orb.
class EarnLoading extends StatelessWidget {
  const EarnLoading({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const SizedBox(
              width: 140,
              child: LinearProgressIndicator(minHeight: 3, color: Colors.white, backgroundColor: Color(0x26FFFFFF)),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 10),
            Text(label!, style: const TextStyle(color: kEarnSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
}

/// A text field on the black tile row of the account pages: the small grey
/// label over white type, a square badge on the left.
class EarnField extends StatelessWidget {
  const EarnField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon = Icons.edit_outlined,
    this.fieldKey,
    this.keyboard,
    this.caps = TextCapitalization.none,
    this.action = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.spacing = 0,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Key? fieldKey;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double spacing;

  @override
  Widget build(BuildContext context) => TileRow(
        leading: TileBadge(icon: icon),
        label: label,
        body: TextField(
          key: fieldKey,
          controller: controller,
          style: accountFieldStyle.copyWith(letterSpacing: spacing),
          cursorColor: Colors.white,
          keyboardType: keyboard,
          textCapitalization: caps,
          textInputAction: action,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 1),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x73FFFFFF), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
          ),
        ),
      );
}
