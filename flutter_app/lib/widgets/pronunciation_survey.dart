import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _surveySeenKey = 'hasSeenPronunciationSurvey';
const _purple = Color(0xFF8B5CF6);

/// Shows the survey only once on this device.
/// Returns true when the sheet was shown, false when it was already seen.
Future<bool> showPronunciationSurveyIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_surveySeenKey) ?? false) return false;
  await prefs.setBool(_surveySeenKey, true);
  if (!context.mounted) return false;
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    builder: (_) => const PronunciationSurveySheet(),
  );
  return true;
}

class PronunciationSurveySheet extends StatefulWidget {
  const PronunciationSurveySheet({super.key});

  @override
  State<PronunciationSurveySheet> createState() =>
      _PronunciationSurveySheetState();
}

class _PronunciationSurveySheetState extends State<PronunciationSurveySheet>
    with SingleTickerProviderStateMixin {
  final _noteController = TextEditingController();
  late final AnimationController _entrance;
  String? _selected;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    setState(() => _submitted = true);
    Future<void>.delayed(const Duration(milliseconds: 760), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) => Transform.translate(
        offset:
            Offset(0, 40 * (1 - Curves.easeOutBack.transform(_entrance.value))),
        child: Opacity(opacity: _entrance.value.clamp(0.0, 1.0), child: child),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 720),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              decoration: BoxDecoration(
                color: const Color(0xE60A0A0A),
                border: Border.all(color: const Color(0x14FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331B0C3D),
                    blurRadius: 48,
                    offset: Offset(0, -12),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                              ),
                              children: [
                                TextSpan(text: 'NowssB'),
                                TextSpan(
                                  text: '.',
                                  style:
                                      TextStyle(color: _purple, fontSize: 22),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                            tooltip: 'Close feedback',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.8,
                          ),
                          children: [
                            TextSpan(text: 'Help us improve '),
                            TextSpan(
                              text: 'pronunciation',
                              style: TextStyle(color: _purple),
                            ),
                            TextSpan(text: ' on NowssB'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                                text:
                                    "Tell us what's working and what's not. The more "),
                            TextSpan(
                              text: 'specific',
                              style: TextStyle(color: _purple),
                            ),
                            TextSpan(text: ', the better.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _option(
                        value: 'helpful',
                        label: const TextSpan(
                          children: [
                            TextSpan(text: 'This pronunciation is '),
                            TextSpan(
                                text: 'helpful',
                                style: TextStyle(color: _purple)),
                          ],
                        ),
                        icon: _checkSvg,
                        delay: 0,
                      ),
                      _option(
                        value: 'experience',
                        label: const TextSpan(
                          children: [
                            TextSpan(text: 'How was your overall '),
                            TextSpan(
                                text: 'experience',
                                style: TextStyle(color: _purple)),
                            TextSpan(text: '?'),
                          ],
                        ),
                        icon: _starSvg,
                        delay: 50,
                      ),
                      _option(
                        value: 'dislike',
                        label: const TextSpan(
                          children: [
                            TextSpan(text: "What didn't you "),
                            TextSpan(
                                text: 'like', style: TextStyle(color: _purple)),
                            TextSpan(text: " about it?"),
                          ],
                        ),
                        icon: _thumbSvg,
                        delay: 100,
                      ),
                      _option(
                        value: 'changes',
                        label: const TextSpan(
                          children: [
                            TextSpan(
                                text:
                                    'What changes should we make? / Write a '),
                            TextSpan(
                                text: 'review',
                                style: TextStyle(color: _purple)),
                          ],
                        ),
                        icon: _pencilSvg,
                        delay: 150,
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _noteController,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 1200,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'What would you like us to know?',
                          hintStyle: const TextStyle(
                              color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withOpacity(.035),
                          counterStyle: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: _purple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: AnimatedScale(
                          scale: _submitted ? .975 : 1,
                          duration: const Duration(milliseconds: 140),
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF101014),
                              shape: const StadiumBorder(),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _submitted
                                  ? const Icon(Icons.check_rounded,
                                      key: ValueKey('sent'))
                                  : const Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: 'Send '),
                                          TextSpan(
                                            text: 'feedback',
                                            style: TextStyle(color: _purple),
                                          ),
                                        ],
                                      ),
                                      key: ValueKey('send'),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (_submitted)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(
                              'Thank you for helping us improve.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _option({
    required String value,
    required InlineSpan label,
    required String icon,
    required int delay,
  }) {
    final selected = _selected == value;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: .92 + value * .08, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => setState(() => _selected = value),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected
                  ? _purple.withOpacity(.13)
                  : Colors.white.withOpacity(.035),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? _purple.withOpacity(.7)
                    : Colors.white.withOpacity(.08),
              ),
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: selected ? 1.1 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.string(icon,
                        colorFilter: const ColorFilter.mode(
                            Color(0xFF0B0B0C), BlendMode.srcIn)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: _purple, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _checkSvg =
    '''<svg viewBox="0 0 24 24"><path d="M5 12.5l4.2 4.2L19 7" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>''';
const _starSvg =
    '''<svg viewBox="0 0 24 24"><path d="M12 3.8l2.45 4.97 5.49.8-3.97 3.87.94 5.47L12 16.32l-4.91 2.59.94-5.47-3.97-3.87 5.49-.8L12 3.8z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>''';
const _thumbSvg =
    '''<svg viewBox="0 0 24 24"><path d="M7.2 10.3v9.1H4.5a1 1 0 0 1-1-1v-7.1a1 1 0 0 1 1-1h2.7zM7.2 19.4h8.9a2 2 0 0 0 1.94-1.52l1.8-7.2a2 2 0 0 0-1.94-2.48h-4.1l.62-3.1A1.8 1.8 0 0 0 12.66 3l-5.46 7.3v9.1z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>''';
const _pencilSvg =
    '''<svg viewBox="0 0 24 24"><path d="M4 17.8V20h2.2L18.9 7.3l-2.2-2.2L4 17.8zM15.5 5.3l2.2 2.2 1.2-1.2a1.55 1.55 0 0 0 0-2.2l-.1-.1a1.55 1.55 0 0 0-2.2 0l-1.1 1.3z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>''';
