/// The NowssB Earn layout (Ribon, Nov 23): a wallet-app shape that reads at
/// a glance, in the NowssB glass kit (film, glass panes, white ink, the gold
/// of the real coin), never a borrowed colour.
///
///  * [EarnHey]          "Hey, name" header with the back square.
///  * [EarnBalanceCard]  one glass card, two balances side by side: cash
///                       earned and coins (the real NowssB coin).
///  * [EarnActions]      two big clear buttons (Payout · Invite).
///  * [EarnSectionTitle] a section title with See all.
///  * [EarnStatCard]     big central number, a status pill, three chips.
///  * [EarnStatGrid]     a plain statistics grid with one highlighted dark
///                       tile.
///
/// Every mark sits in a rounded square: no balls, circles, orbs or rings.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../account/account_kit.dart' show TileRow, TileBadge, accountFieldStyle;

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
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

/// Tests: the name the header greets.
String? debugEarnName;

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

/// A white rounded square holding a dark mark (the Earn badge).
class EarnSquare extends StatelessWidget {
  const EarnSquare({super.key, this.mark, this.icon, this.size = 36, this.child, this.dark = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;

  /// Glass square with a white mark instead (on white tiles).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : kEarnInk;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? const Color(0x24FFFFFF) : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: dark ? Border.all(color: kEarnLine) : null,
      ),
      child: child ??
          (mark != null
              ? NwsbIcon(mark!, size: size * 0.46, color: ink, strokeWidth: 1.9)
              : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.5, color: ink)),
    );
  }
}

/// The back button as a white rounded square.
class EarnBackSquare extends StatelessWidget {
  const EarnBackSquare({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Back',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const EarnSquare(icon: Icons.arrow_back_rounded, size: 42),
        ),
      );
}

/// "Hey, name" with a small caps eyebrow; back square on the left.
class EarnHey extends StatelessWidget {
  const EarnHey({super.key, required this.eyebrow, this.onBack, this.trailing, this.title});
  final String eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Overrides the greeting.
  final String? title;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (onBack != null) ...[EarnBackSquare(onTap: onBack!), const SizedBox(width: 14)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(title ?? earnHey(),
                key: const ValueKey('earn-hey'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]);
}

/// A glass pane in the Earn shape (rounded 22, kit fill and hairline).
class EarnPane extends StatelessWidget {
  const EarnPane({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.dark = false});
  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: dark ? kEarnDark : const Color(0x8C14141C),
          borderRadius: BorderRadius.circular(kEarnRadius),
          border: Border.all(color: kEarnLine),
          boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 12), blurRadius: 30)],
        ),
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

/// One card, two balances side by side with a hairline between them.
class EarnBalanceCard extends StatelessWidget {
  const EarnBalanceCard({super.key, required this.left, required this.right});
  final EarnBalance left;
  final EarnBalance right;

  Widget _side(EarnBalance b) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          if (b.coin)
            const NwsbCoinDisc(size: 22)
          else
            EarnSquare(mark: b.mark ?? NwsbMarks.earn, size: 22),
          const SizedBox(width: 7),
          Flexible(
            child: Text(b.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
          ),
          if (b.onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: kEarnMuted),
          ],
        ]),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: b.value),
        if (b.sub != null) ...[
          const SizedBox(height: 4),
          Text(b.sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnMuted, fontSize: 11.5, height: 1.3)),
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
  Widget build(BuildContext context) => EarnPane(
        key: const ValueKey('earn-balance-card'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _side(left)),
            Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: kEarnLine),
            Expanded(child: _side(right)),
          ]),
        ),
      );
}

/// The big number style of balances and stat cards.
const kEarnBig = TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8);

/// A big clear action: white with ink when [primary], else glass.
class EarnActionButton extends StatelessWidget {
  const EarnActionButton({super.key, required this.label, required this.icon, required this.onTap, this.primary = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final fg = primary ? kEarnInk : Colors.white;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: primary ? Colors.white : const Color(0x24FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: primary ? BorderSide.none : const BorderSide(color: Color(0x40FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 15.5)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two big buttons side by side.
class EarnActions extends StatelessWidget {
  const EarnActions({super.key, required this.onPayout, required this.onInvite});
  final VoidCallback onPayout;
  final VoidCallback onInvite;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: EarnActionButton(key: const ValueKey('earn-action-payout'), label: 'Payout', icon: Icons.south_west_rounded, onTap: onPayout)),
        const SizedBox(width: 10),
        Expanded(child: EarnActionButton(key: const ValueKey('earn-action-invite'), label: 'Invite', icon: Icons.person_add_alt_1_rounded, onTap: onInvite, primary: false)),
      ]);
}

/// A section title with an optional See all.
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
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(action, style: const TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: kEarnSoft),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

enum EarnStatus { ongoing, upcoming, reached, off }

/// Ongoing (white), Upcoming (glass), Reached (gold), off (quiet glass).
class EarnStatusPill extends StatelessWidget {
  const EarnStatusPill(this.status, {super.key, this.text});
  final EarnStatus status;
  final String? text;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, line, label) = switch (status) {
      EarnStatus.ongoing => (Colors.white, kEarnInk, Colors.white, 'Ongoing'),
      EarnStatus.upcoming => (const Color(0x1AFFFFFF), Colors.white, const Color(0x40FFFFFF), 'Upcoming'),
      EarnStatus.reached => (kEarnGold, kEarnInk, kEarnGold, 'Reached'),
      EarnStatus.off => (const Color(0x1AFFFFFF), kEarnSoft, const Color(0x26FFFFFF), 'Not yet'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: line)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (status == EarnStatus.ongoing) ...[
          Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF2FBF71), borderRadius: BorderRadius.circular(1.5))),
          const SizedBox(width: 6),
        ],
        Text(text ?? label, maxLines: 1, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ]),
    );
  }
}

/// A small chip: a mark (or the real coin) and a short line.
class EarnChip extends StatelessWidget {
  const EarnChip(this.text, {super.key, this.mark, this.icon, this.coin = false});
  final String text;
  final String? mark;
  final IconData? icon;
  final bool coin;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 9, 5),
        decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1FFFFFFF))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (coin)
            const NwsbCoinDisc(size: 16)
          else if (mark != null)
            NwsbIcon(mark!, size: 14, color: Colors.white, strokeWidth: 1.9)
          else if (icon != null)
            Icon(icon, size: 14, color: Colors.white),
          if (coin || mark != null || icon != null) const SizedBox(width: 5),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// A plain progress bar (white on a glass track, squared ends rounded).
class EarnBar extends StatelessWidget {
  const EarnBar(this.value, {super.key, this.height = 6, this.color = Colors.white});
  final double value;
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0x26FFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ]),
        ),
      );
}

/// Big central number, its unit, a title, a status pill and three chips.
class EarnStatCard extends StatelessWidget {
  const EarnStatCard({
    super.key,
    required this.title,
    required this.number,
    this.unit,
    this.status,
    this.chips = const [],
    this.progress,
    this.footer,
    this.mark,
    this.onTap,
    this.dark = false,
  });
  final String title;
  final String number;
  final String? unit;
  final Widget? status;
  final List<Widget> chips;
  final double? progress;
  final String? footer;
  final String? mark;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final card = EarnPane(
      dark: dark,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          if (mark != null) ...[EarnSquare(mark: mark, size: 30), const SizedBox(width: 10)],
          Expanded(
            child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25)),
          ),
          if (status != null) ...[const SizedBox(width: 8), status!],
          if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kEarnMuted)],
        ]),
        const SizedBox(height: 14),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: number, style: kEarnBig.copyWith(fontSize: 40)),
                if (unit != null) TextSpan(text: '  $unit', style: const TextStyle(color: kEarnMuted, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              maxLines: 1,
            ),
          ),
        ),
        if (progress != null) ...[const SizedBox(height: 12), EarnBar(progress!)],
        if (footer != null) ...[
          const SizedBox(height: 8),
          Text(footer!, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: chips),
        ],
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

/// One tile of [EarnStatGrid].
class EarnStat {
  const EarnStat(this.label, this.value, {this.sub, this.highlight = false, this.key, this.onTap});
  final VoidCallback? onTap;
  final String label;
  final String value;
  final String? sub;
  final bool highlight;
  final Key? key;
}

/// A plain statistics grid, two per row; [EarnStat.highlight] is the dark
/// tile (solid ink, white hairline, gold figure).
class EarnStatGrid extends StatelessWidget {
  const EarnStatGrid(this.stats, {super.key, this.columns = 2});
  final List<EarnStat> stats;
  final int columns;

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
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: s.highlight ? const Color(0xFF07070B) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(kEarnTileRadius),
          border: Border.all(color: s.highlight ? const Color(0x66FFFFFF) : const Color(0x1FFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: Text(s.label.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
            ),
            if (s.onTap != null) const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kEarnMuted),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(s.value, maxLines: 1, style: TextStyle(color: s.highlight ? kEarnGold : Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.4)),
          ),
          if (s.sub != null) ...[
            const SizedBox(height: 3),
            Text(s.sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnMuted, fontSize: 11, height: 1.3)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows);
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
