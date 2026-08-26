/// Native Flutter translation of app/widgets/neumorphic-essentials.html.
///
/// This is a standalone Normal Home section. It deliberately has no phone or
/// page frame around it; only the supplied timeline cards are surfaced.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class NmSuppliedEssentials extends StatefulWidget {
  const NmSuppliedEssentials({super.key});

  @override
  State<NmSuppliedEssentials> createState() => _NmSuppliedEssentialsState();
}

class _NmSuppliedEssentialsState extends State<NmSuppliedEssentials> {
  var _expanded = false;

  static const _base = Color(0xFFECEEF2);
  static const _text = Color(0xFF2B2D33);
  static const _subtext = Color(0xFF8A8F9A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 18),
            child: Text('Your essentials', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: _text)),
          ),
          _TimelineEntry(
            hero: true,
            active: true,
            icon: Icons.mic_none_rounded,
            title: 'Preconceptions',
            subtitle: "Today's Meditation",
            duration: '3–20 min',
          ),
          const _TimelineEntry(icon: Icons.bedtime_outlined, title: 'Wind down for bed', duration: '12 min'),
          const _TimelineEntry(icon: Icons.nightlight_round, title: 'Fall asleep', duration: '45 min'),
          const _TimelineEntry(icon: Icons.nights_stay_outlined, title: 'Sleep through the night', duration: '45–480 min', last: true),
          if (_expanded) ...const [
            _TimelineEntry(icon: Icons.wb_sunny_outlined, title: 'Wake up gently', duration: '8 min'),
            _TimelineEntry(icon: Icons.wb_sunny_rounded, title: 'Morning intention', duration: '5 min', last: true),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 4, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                  decoration: BoxDecoration(color: _base, borderRadius: BorderRadius.circular(22), boxShadow: NwsbShadows.raisedXs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_expanded ? 'See less' : 'See more', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _subtext)),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: _base, shape: BoxShape.circle, boxShadow: NwsbShadows.raisedXs),
                        child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: _subtext),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.duration,
    this.subtitle,
    this.hero = false,
    this.active = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String duration;
  final String? subtitle;
  final bool hero;
  final bool active;
  final bool last;

  static const _base = Color(0xFFECEEF2);
  static const _orange = Color(0xFFFF8A3D);
  static const _orangeLight = Color(0xFFFFB44D);

  @override
  Widget build(BuildContext context) {
    final card = hero ? _HeroEssential(icon: icon, title: title, subtitle: subtitle!, duration: duration) : _PillEssential(icon: icon, title: title, duration: duration);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: active ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_orangeLight, _orange]) : null,
                      color: active ? null : _base,
                      boxShadow: active
                          ? const [BoxShadow(color: Color(0x339C6B30), blurRadius: 7, spreadRadius: 3), BoxShadow(color: Color(0x55000000), offset: Offset(3, 3), blurRadius: 6), BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 6)]
                          : NwsbShadows.raisedXs,
                    ),
                  ),
                ),
                if (!last) Expanded(child: Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 2), decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFC7CDD9), width: 3, style: BorderStyle.solid))))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 18), child: card)),
        ],
      ),
    );
  }
}

class _HeroEssential extends StatelessWidget {
  const _HeroEssential({required this.icon, required this.title, required this.subtitle, required this.duration});
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 148),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFB44D), Color(0xFFFF8A3D)]),
          boxShadow: NwsbShadows.raised,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0x8CFFFFFF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('● ● ●  543', style: TextStyle(fontSize: 12.5, color: Color(0xFF6B3F13), fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  const Text('•••', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B3F13))),
                ]),
                const SizedBox(height: 14),
                Row(children: [Icon(icon, size: 17, color: const Color(0xFF4A2A09)), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4A2A09))))]),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.volume_up_outlined, size: 15, color: Color(0xFF5C3812)), const SizedBox(width: 6), Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF5C3812))))]),
                Padding(padding: const EdgeInsets.only(left: 22, top: 2), child: Text(duration, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF5C3812)))),
              ]),
            ),
            const Positioned(right: 2, bottom: 0, child: Icon(Icons.face_2_outlined, size: 70, color: Color(0xA34A2A09))),
          ],
        ),
      );
}

class _PillEssential extends StatelessWidget {
  const _PillEssential({required this.icon, required this.title, required this.duration});
  final IconData icon;
  final String title;
  final String duration;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFECEEF2), borderRadius: BorderRadius.circular(20), boxShadow: NwsbShadows.raisedSm),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFECEEF2), shape: BoxShape.circle, boxShadow: NwsbShadows.raisedXs), child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9AA0AB), size: 18)),
          const SizedBox(width: 8),
          Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFECEEF2), shape: BoxShape.circle, boxShadow: NwsbShadows.raisedXs), child: Icon(icon, color: const Color(0xFF9AA0AB), size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2D33))), const SizedBox(height: 3), Text(duration, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8A8F9A)))])),
        ]),
      );
}
