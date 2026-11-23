/// The look shared by Complete your profile and Bank / payout details. It
/// is the Menu / Settings / Store / Sound Library language, built from the
/// same widgets:
///
///  * the purple film behind ([AppBackdrop]) under the Menu's
///    [QuietFilmVeil];
///  * the Menu's top bar: white circle back button, `NOWSSB` in gold and
///    the page name;
///  * the Store's big white heading and grey subline;
///  * cards are [GlassListCard] (white badge, small grey overline, big white
///    title) and every row inside is the black [GlassTile] row: circle icon,
///    hairline divider, text, arrow. Input rows are that same black row with
///    a text field in place of the title;
///  * the main action is the Sound Library / intro white bar with the ink
///    label and an arrow;
///  * pickers are the Settings choice sheet (dark glass, [GlassSearchField],
///    black rows, a white pill on the current one).
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/glass_list_card.dart';
import 'countries.dart';

export '../../widgets/glass_list_card.dart' show GlassListCard, GlassTile, kGlassMuted, kGlassTile;

class AccountColors {
  AccountColors._();
  static const bg = NwsbColors.deep;
  static const muted = kGlassMuted;
  static const soft = Color(0xB3FFFFFF);
  static const faint = Color(0x73FFFFFF);
  static const hairline = Color(0x26FFFFFF);

  /// The login screen's error ink.
  static const error = Color(0xFFFFB4AB);
  static const errorEdge = Color(0x99FFB4AB);
}

/// Full-screen page: film + veil, the Menu bar, a Store heading, then
/// [children]; [bottom] is pinned under the list (the main action).
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.kicker,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
  });

  /// Second word in the bar after NOWSSB ("Your account", "Earn").
  final String kicker;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final pad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AccountColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackdrop()),
          const Positioned.fill(child: QuietFilmVeil()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(onBack == null ? 18 : 12, top + 10, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0x66060C18),
                  border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
                ),
                child: Row(children: [
                  if (onBack != null) ...[
                    AccountBackButton(onTap: onBack!),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: 'NOWSSB',
                          style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: NwsbColors.goldLight),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: kicker,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ]),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 34, height: 1.0, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(subtitle!, style: const TextStyle(color: Color(0xAFFFFFFF), fontSize: 13, height: 1.3)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ...children,
                  ],
                ),
              ),
              if (bottom != null)
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + pad),
                  decoration: const BoxDecoration(
                    color: Color(0x66060C18),
                    border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
                  ),
                  child: bottom!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Menu's back button: a white circle with an ink arrow.
class AccountBackButton extends StatelessWidget {
  const AccountBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.arrow_back_rounded, size: 19, color: NwsbColors.ink),
        ),
      ),
    );
  }
}

/// The plain surface of a [GlassListCard] for content that is not a header
/// plus rows (a loading block, an error).
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0x8C14141C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AccountColors.hairline),
        ),
        child: child,
      ),
    );
  }
}

/// The circle a [GlassTile] opens with.
class TileBadge extends StatelessWidget {
  const TileBadge({super.key, this.icon, this.child, this.color = Colors.white});
  final IconData? icon;
  final Widget? child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: child ?? Icon(icon, size: 18, color: color),
    );
  }
}

const _divider = SizedBox(
  width: 25,
  child: Center(child: SizedBox(width: 1, height: 28, child: ColoredBox(color: Color(0x26FFFFFF)))),
);

/// One black [GlassTile]-shaped row. [label] is the small grey line, [body]
/// takes the title's place (a text field, a value). An [error] draws the
/// login screen's error ink under the row and on its edge.
class TileRow extends StatelessWidget {
  const TileRow({
    super.key,
    required this.leading,
    required this.label,
    required this.body,
    this.trailing,
    this.onTap,
    this.error,
    this.optional = false,
  });

  final Widget leading;
  final String label;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? error;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final bad = error != null;
    final row = Material(
      color: kGlassTile,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: bad ? AccountColors.errorEdge : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(children: [
            leading,
            _divider,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: label),
                    if (optional) const TextSpan(text: '  ·  optional', style: TextStyle(color: AccountColors.faint, fontWeight: FontWeight.w500)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kGlassMuted, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                ),
                const SizedBox(height: 2),
                body,
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      ),
    );
    if (!bad) return row;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      row,
      FieldError(error!),
    ]);
  }
}

/// Validation line in the login screen's error ink.
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 8, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline_rounded, size: 14, color: AccountColors.error),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: AccountColors.error, fontSize: 12, height: 1.35))),
      ]),
    );
  }
}

/// The white text the Menu's search field types in, on a black row.
const accountFieldStyle = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700);

/// A text field inside a [TileRow]: no box, no outline, white type.
class TileInput extends StatelessWidget {
  const TileInput({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboard,
    this.caps = TextCapitalization.none,
    this.formatters,
    this.onChanged,
    this.autofill,
    this.action,
    this.spacing = 0,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofill;
  final TextInputAction? action;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: accountFieldStyle.copyWith(letterSpacing: spacing),
      cursorColor: Colors.white,
      keyboardType: keyboard,
      textCapitalization: caps,
      textInputAction: action ?? TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofill,
      inputFormatters: formatters,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 1),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x59FFFFFF), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
      ),
    );
  }
}

/// The arrow a tappable [GlassTile] ends with.
const tileArrow = Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGlassMuted);

/// The white pill that marks the current choice in a Settings sheet.
class CurrentPill extends StatelessWidget {
  const CurrentPill({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0B0B10)),
    );
  }
}

/// The Sound Library / intro main action: a white bar, ink label in caps,
/// an arrow. "Please wait" while [busy] (the login screen's busy state).
class PrimaryBar extends StatelessWidget {
  const PrimaryBar({super.key, required this.label, required this.onTap, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    // Off stays readable: glass fill, hairline, 70% white type.
    final ink = enabled || busy ? NwsbColors.ink : const Color(0xB3FFFFFF);
    return Material(
        color: enabled || busy ? Colors.white : const Color(0x1FFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: enabled || busy ? BorderSide.none : const BorderSide(color: Color(0x40FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(
                  busy ? 'PLEASE WAIT' : label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: ink),
                ),
              ),
              if (!busy) ...[
                const SizedBox(width: 14),
                Icon(Icons.arrow_forward_rounded, size: 17, color: ink),
              ],
            ]),
          ),
        ),
    );
  }
}

/// Quiet text action under the main bar ("Not now", "Cancel"), as the
/// login screen's "Explore without account".
class QuietAction extends StatelessWidget {
  const QuietAction({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// A choice pill: the Settings sheet's white pill when on, a glass circle
/// row's fill when off.
class GlassChoice extends StatelessWidget {
  const GlassChoice({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? const Color(0xFF0B0B10) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.white : const Color(0x1AFFFFFF),
          border: Border.all(color: selected ? Colors.white : const Color(0x1FFFFFFF)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: ink), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
      ),
    );
  }
}

/// Flag in the tile circle.
class FlagBadge extends StatelessWidget {
  const FlagBadge(this.country, {super.key});
  final NwsbCountry? country;
  @override
  Widget build(BuildContext context) {
    return TileBadge(
      child: country == null
          ? const Icon(Icons.public_rounded, size: 18, color: Colors.white)
          : Text(country!.flag, style: const TextStyle(fontSize: 18)),
    );
  }
}

/// A black row that shows the chosen country and opens [pickCountry].
class CountryField extends StatelessWidget {
  const CountryField({super.key, required this.country, required this.onPicked, this.label = 'Country', this.error, this.fieldKey});
  final NwsbCountry? country;
  final ValueChanged<NwsbCountry> onPicked;
  final String label;
  final String? error;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final c = country;
    return TileRow(
      key: fieldKey,
      leading: FlagBadge(c),
      label: label,
      error: error,
      onTap: () async {
        final picked = await pickCountry(context, selected: c?.code);
        if (picked != null) onPicked(picked);
      },
      body: Text(c?.name ?? 'Choose your country',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: c == null ? const TextStyle(color: Color(0x59FFFFFF), fontSize: 15, fontWeight: FontWeight.w500) : accountFieldStyle),
      trailing: tileArrow,
    );
  }
}

/// The Settings choice sheet frame: a [GlassListCard] pane above the
/// dimmed page.
Future<T?> showAccountSheet<T>(BuildContext context, {required WidgetBuilder builder, bool tall = false}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      final kb = MediaQuery.viewInsetsOf(ctx).bottom;
      final body = Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom + kb),
        child: builder(ctx),
      );
      return tall ? SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.86, child: body) : body;
    },
  );
}

/// Searchable country sheet (all ISO countries with calling codes).
Future<NwsbCountry?> pickCountry(BuildContext context, {String? selected}) {
  return showAccountSheet<NwsbCountry>(context, tall: true, builder: (_) => _CountrySheet(selected: selected));
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({this.selected});
  final String? selected;
  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = kNwsbCountries
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.code.toLowerCase() == q || '+${c.dial}'.startsWith(q.startsWith('+') ? q : '+$q'))
        .toList();
    return ClipRRect(
      key: const Key('country-sheet'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
        decoration: BoxDecoration(
          color: const Color(0xF014141C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AccountColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.public_rounded, size: 22, color: Color(0xFF0B0B10)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHOOSE', style: TextStyle(color: kGlassMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                SizedBox(height: 2),
                Text('Country', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          KeyedSubtree(key: const Key('country-search'), child: GlassSearchField(controller: _search, hint: 'Search country or +code')),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Text('No country called "${_search.text.trim()}".', textAlign: TextAlign.center, style: const TextStyle(color: kGlassMuted, fontSize: 13)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 14),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final on = c.code == widget.selected;
                      return TileRow(
                        key: Key('country-${c.code}'),
                        leading: FlagBadge(c),
                        label: '+${c.dial}',
                        onTap: () => Navigator.pop(context, c),
                        body: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: accountFieldStyle),
                        trailing: on ? const CurrentPill() : tileArrow,
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

/// Date of birth in the Settings sheet frame: a dark wheel and the white
/// bar. Returns the picked day.
Future<DateTime?> pickBirthday(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  var value = initial ?? DateTime(now.year - 25, now.month, now.day);
  return showAccountSheet<DateTime>(
    context,
    builder: (ctx) => GlassListCard( squareBadge: true,
      key: const Key('dob-sheet'),
      margin: EdgeInsets.zero,
      icon: Icons.cake_outlined,
      overline: 'Optional',
      title: 'Date of birth',
      subtitle: 'Only used to check you are 13 or older.',
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(color: kGlassTile, borderRadius: BorderRadius.circular(20)),
          child: CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: value,
              minimumDate: DateTime(now.year - 110),
              maximumDate: now,
              onDateTimeChanged: (d) => value = d,
            ),
          ),
        ),
        const SizedBox(height: 4),
        PrimaryBar(key: const Key('dob-done'), label: 'Done', onTap: () => Navigator.pop(ctx, value)),
      ],
    ),
  );
}

/// A short black message strip floating over the page (the app's toast).
void showAccountToast(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kGlassTile,
    elevation: 0,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AccountColors.hairline)),
    content: Row(children: [
      const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600))),
    ]),
  ));
}

/// Placeholder block while a page loads.
class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0x8C14141C),
        border: Border.all(color: AccountColors.hairline),
      ),
    );
  }
}
