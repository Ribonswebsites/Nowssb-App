/// The look shared by Complete your profile and Bank / payout details: the
/// dark NowssB surface with the violet glow, frosted glass cards with a
/// hairline, gold for the one action that matters, white type.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'countries.dart';

class AccountColors {
  AccountColors._();
  static const bg = Color(0xFF07060F);
  static const violet = Color(0xFF6B4BD8);
  static const violetDeep = Color(0xFF2A1A5E);
  static const glass = Color(0x1AFFFFFF);
  static const glassStrong = Color(0x26FFFFFF);
  static const hairline = Color(0x2EFFFFFF);
  static const soft = Color(0xB3FFFFFF);
  static const faint = Color(0x80FFFFFF);
  static const error = Color(0xFFFF8A80);
  static const ok = Color(0xFF7CE0B4);
}

/// Full-screen page: violet glow behind, a round glass back button, title
/// and kicker, then [children] in a scroll view.
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.kicker,
    required this.title,
    required this.children,
    this.onBack,
    this.trailing,
    this.bottom,
  });

  final String kicker;
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Pinned under the scroll view (the main action).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccountColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _Glow()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      if (onBack != null)
                        GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!, semantic: 'Back')
                      else
                        const SizedBox(width: 4),
                      const Spacer(),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Text(kicker.toUpperCase(),
                          style: const TextStyle(color: NwsbColors.gold, fontSize: 11.5, letterSpacing: 2.4, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                      const SizedBox(height: 18),
                      ...children,
                    ],
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    child: bottom!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.7, -1.05),
          radius: 1.25,
          colors: [Color(0xFF3B2585), Color(0xFF160F33), AccountColors.bg],
          stops: [0, 0.42, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-1.1, 0.9),
            radius: 0.9,
            colors: [Color(0x40C8A96E), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}

/// Frosted glass card with a hairline.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24, this.glow});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (glow ?? Colors.white).withValues(alpha: glow == null ? 0.11 : 0.20),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
            border: Border.all(color: AccountColors.hairline),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, required this.semantic});
  final IconData icon;
  final VoidCallback onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AccountColors.glassStrong,
            border: Border.all(color: AccountColors.hairline),
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

/// Small section label above a group of fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});
  final String text;
  final bool optional;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7, top: 14),
      child: Row(children: [
        Text(text, style: const TextStyle(color: AccountColors.soft, fontSize: 13, fontWeight: FontWeight.w600)),
        if (optional) const Text('  · optional', style: TextStyle(color: AccountColors.faint, fontSize: 12)),
      ]),
    );
  }
}

InputDecoration accountInput({String? hint, String? error, Widget? prefix, Widget? suffix}) {
  OutlineInputBorder b(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
    errorText: error,
    errorStyle: const TextStyle(color: AccountColors.error, fontSize: 12),
    errorMaxLines: 2,
    filled: true,
    fillColor: const Color(0x14FFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    prefixIcon: prefix,
    suffixIcon: suffix,
    enabledBorder: b(AccountColors.hairline),
    focusedBorder: b(NwsbColors.gold, 1.4),
    errorBorder: b(AccountColors.error),
    focusedErrorBorder: b(AccountColors.error, 1.4),
    disabledBorder: b(const Color(0x14FFFFFF)),
  );
}

const accountFieldStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500);

/// The gold primary action; a spinner while [busy].
class GoldCta extends StatelessWidget {
  const GoldCta({super.key, required this.label, required this.onTap, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || busy ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFFF3D58A), Color(0xFFC8A96E), Color(0xFFA9843C)]),
            boxShadow: const [BoxShadow(color: Color(0x40C8A96E), blurRadius: 28, spreadRadius: -6, offset: Offset(0, 10))],
          ),
          child: busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF1A1408)))
              : Text(label, style: const TextStyle(color: Color(0xFF1A1408), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        ),
      ),
    );
  }
}

/// A pill that selects one option.
class GlassChoice extends StatelessWidget {
  const GlassChoice({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? NwsbColors.gold.withValues(alpha: 0.22) : const Color(0x12FFFFFF),
          border: Border.all(color: selected ? NwsbColors.gold : AccountColors.hairline, width: selected ? 1.3 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: selected ? NwsbColors.goldLight : AccountColors.soft), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: selected ? NwsbColors.goldLight : AccountColors.soft, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
      ),
    );
  }
}

/// Tappable field that shows the chosen country and opens [pickCountry].
class CountryField extends StatelessWidget {
  const CountryField({super.key, required this.country, required this.onPicked, this.showDial = false, this.error, this.fieldKey});
  final NwsbCountry? country;
  final ValueChanged<NwsbCountry> onPicked;
  final bool showDial;
  final String? error;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final c = country;
    return GestureDetector(
      key: fieldKey,
      onTap: () async {
        final picked = await pickCountry(context, selected: c?.code);
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        isEmpty: c == null,
        decoration: accountInput(hint: 'Choose your country', error: error, suffix: const Icon(Icons.expand_more_rounded, color: AccountColors.soft)),
        child: c == null
            ? null
            : Text('${c.flag}  ${c.name}${showDial ? '  +${c.dial}' : ''}', style: accountFieldStyle, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Searchable country sheet (all ISO countries with calling codes).
Future<NwsbCountry?> pickCountry(BuildContext context, {String? selected}) {
  return showModalBottomSheet<NwsbCountry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CountrySheet(selected: selected),
  );
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({this.selected});
  final String? selected;
  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = kNwsbCountries
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.code.toLowerCase() == q || '+${c.dial}'.startsWith(q.startsWith('+') ? q : '+$q'))
        .toList();
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF110D22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AccountColors.hairline)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: TextField(
            key: const Key('country-search'),
            autofocus: false,
            style: accountFieldStyle,
            onChanged: (v) => setState(() => _q = v),
            decoration: accountInput(hint: 'Search country or +code', prefix: const Icon(Icons.search_rounded, color: AccountColors.soft)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final on = c.code == widget.selected;
              return ListTile(
                key: Key('country-${c.code}'),
                onTap: () => Navigator.pop(context, c),
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text(c.name, style: TextStyle(color: on ? NwsbColors.goldLight : Colors.white, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
                trailing: Text('+${c.dial}', style: const TextStyle(color: AccountColors.faint)),
              );
            },
          ),
        ),
      ]),
    );
  }
}
