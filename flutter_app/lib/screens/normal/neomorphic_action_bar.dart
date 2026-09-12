/// Native Flutter translation of app/widgets/neomorphic-action-bar-1.html.
library;

import 'package:flutter/material.dart';

import 'glassmorphism_theme.dart';

class NmSuppliedActionBar extends StatelessWidget {
  const NmSuppliedActionBar({
    super.key,
    this.onSupport,
    this.onCoach,
    this.glassmorphism = false,
  });

  final VoidCallback? onSupport;
  final VoidCallback? onCoach;
  final bool glassmorphism;

  static const _surface = Color(0xFFF4F8FC);
  static const _textPrimary = Color(0xFF2E3A59);
  static const _textSecondary = Color(0xFF6B7A99);
  static const _accent = Color(0xFF7B88EE);
  static const _shadowDark = Color(0x8CA3B1C6);
  static const _shadowLight = Color(0xE6FFFFFF);
  static const _fashionInk = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final glass = glassmorphism || NormalGlassMode.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _NeoCircle(
                size: 48,
                glass: glass,
                child: Icon(Icons.auto_awesome,
                    size: 21, color: glass ? _fashionInk : _accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'How can we help today?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                    color: glass ? Colors.white : _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: glass ? const Color(0xA4070A11) : _surface,
              borderRadius: BorderRadius.circular(999),
              border: glass ? Border.all(color: const Color(0x2AFFFFFF)) : null,
              boxShadow: glass
                  ? const [
                      BoxShadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 12),
                          blurRadius: 28),
                    ]
                  : const [
                      BoxShadow(
                          color: _shadowDark,
                          offset: Offset(8, 8),
                          blurRadius: 18),
                      BoxShadow(
                          color: _shadowLight,
                          offset: Offset(-8, -8),
                          blurRadius: 18),
                    ],
            ),
            child: Row(
              children: [
                _ActionCircle(
                  icon: Icons.support_agent_outlined,
                  label: 'Help and support',
                  onTap: onSupport,
                  glass: glass,
                ),
                const SizedBox(width: 8),
                _ActionCircle(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Personal coach',
                  onTap: onCoach,
                  glass: glass,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Personal Coach',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: glass ? Colors.white : _textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCoach,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      color: glass ? const Color(0xEBFFFFFF) : _surface,
                      borderRadius: BorderRadius.circular(999),
                      border: glass ? Border.all(color: Colors.white) : null,
                      boxShadow: glass
                          ? const [
                              BoxShadow(
                                  color: Color(0x66000000),
                                  offset: Offset(0, 8),
                                  blurRadius: 18),
                            ]
                          : const [
                              BoxShadow(
                                  color: _shadowDark,
                                  offset: Offset(5, 5),
                                  blurRadius: 11),
                              BoxShadow(
                                  color: _shadowLight,
                                  offset: Offset(-5, -5),
                                  blurRadius: 11),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Enter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: glass ? _fashionInk : _textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: glass ? _fashionInk : _textPrimary,
                        ),
                      ],
                    ),
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
  const _NeoCircle(
      {required this.size, required this.child, this.glass = false});
  final double size;
  final Widget child;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final activeGlass = glass || NormalGlassMode.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: activeGlass
            ? const Color(0xEBFFFFFF)
            : NmSuppliedActionBar._surface,
        shape: BoxShape.circle,
        border:
            activeGlass ? Border.all(color: Colors.white, width: 1.5) : null,
        boxShadow: activeGlass
            ? const [
                BoxShadow(
                    color: Color(0x66000000),
                    offset: Offset(0, 6),
                    blurRadius: 14)
              ]
            : const [
                BoxShadow(
                    color: NmSuppliedActionBar._shadowDark,
                    offset: Offset(6, 6),
                    blurRadius: 12),
                BoxShadow(
                    color: NmSuppliedActionBar._shadowLight,
                    offset: Offset(-6, -6),
                    blurRadius: 12),
              ],
      ),
      child: Center(child: child),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle(
      {required this.icon,
      required this.label,
      this.onTap,
      this.glass = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool glass;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: _NeoCircle(
            size: 40,
            glass: glass,
            child: Icon(
              icon,
              size: 18,
              color: glass
                  ? NmSuppliedActionBar._fashionInk
                  : NmSuppliedActionBar._textSecondary,
            ),
          ),
        ),
      );
}
