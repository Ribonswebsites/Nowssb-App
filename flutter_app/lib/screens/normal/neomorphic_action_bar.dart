/// Native Flutter translation of app/widgets/neomorphic-action-bar-1.html.
/// It is a plain below-section action bar: no outer card and no reserved space.
library;

import 'package:flutter/material.dart';

class NmSuppliedActionBar extends StatelessWidget {
  const NmSuppliedActionBar({super.key, this.onSupport, this.onCoach});

  final VoidCallback? onSupport;
  final VoidCallback? onCoach;

  static const _surface = Color(0xFFF4F8FC);
  static const _textPrimary = Color(0xFF2E3A59);
  static const _textSecondary = Color(0xFF6B7A99);
  static const _accent = Color(0xFF7B88EE);
  static const _shadowDark = Color(0x8CA3B1C6);
  static const _shadowLight = Color(0xE6FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _NeoCircle(
                size: 48,
                child: Icon(Icons.auto_awesome, size: 21, color: _accent),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('How can we help today?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.2, color: _textPrimary))),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(color: _shadowDark, offset: Offset(8, 8), blurRadius: 18), BoxShadow(color: _shadowLight, offset: Offset(-8, -8), blurRadius: 18)],
            ),
            child: Row(
              children: [
                _ActionCircle(icon: Icons.support_agent_outlined, label: 'Help and support', onTap: onSupport),
                const SizedBox(width: 8),
                _ActionCircle(icon: Icons.person_add_alt_1_outlined, label: 'Personal coach', onTap: onCoach),
                const SizedBox(width: 10),
                const Expanded(child: Text('Personal Coach', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textPrimary))),
                GestureDetector(
                  onTap: onCoach,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: _shadowDark, offset: Offset(5, 5), blurRadius: 11), BoxShadow(color: _shadowLight, offset: Offset(-5, -5), blurRadius: 11)],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Enter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)), SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 16, color: _textPrimary)]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeoCircle extends StatelessWidget {
  const _NeoCircle({required this.size, required this.child});
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: NmSuppliedActionBar._surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: NmSuppliedActionBar._shadowDark, offset: Offset(6, 6), blurRadius: 12), BoxShadow(color: NmSuppliedActionBar._shadowLight, offset: Offset(-6, -6), blurRadius: 12)]),
        child: Center(child: child),
      );
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: _NeoCircle(size: 40, child: Icon(icon, size: 18, color: NmSuppliedActionBar._textSecondary)),
        ),
      );
}
