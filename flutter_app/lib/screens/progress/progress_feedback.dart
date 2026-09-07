/// Feedback chips + note — same copy as website part006 / Glass Orb.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_tokens.dart';

class ProgressFeedbackSection extends StatefulWidget {
  const ProgressFeedbackSection({super.key});

  @override
  State<ProgressFeedbackSection> createState() => _ProgressFeedbackSectionState();
}

class _ProgressFeedbackSectionState extends State<ProgressFeedbackSection> {
  static const _working = [
    'Morning routine',
    'Evening session',
    'Repeat mode',
    'Listening mode',
    'Word meaning',
    'Phonetic guide',
  ];
  static const _notWorking = [
    'Too many words',
    'Audio missing',
    'Pronunciation unclear',
    'App too slow',
    'Reps feel long',
    'No guidance',
  ];
  static const _wants = [
    'More words',
    'Body map',
    'AI feedback',
    'Progress charts',
    'Sentence builder',
    'Weekly report',
    'More voices',
  ];

  final _selected = <String>{};
  final _note = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('nwsb_mp_feedback_chips') ?? const [];
    final note = prefs.getString('nwsb_mp_feedback_note') ?? '';
    final saved = prefs.getBool('nwsb_mp_feedback_saved') ?? false;
    if (!mounted) return;
    setState(() {
      _selected.addAll(raw);
      _note.text = note;
      _saved = saved;
    });
  }

  Future<void> _persist({bool markSaved = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nwsb_mp_feedback_chips', _selected.toList());
    await prefs.setString('nwsb_mp_feedback_note', _note.text.trim());
    if (markSaved) {
      await prefs.setBool('nwsb_mp_feedback_saved', true);
      setState(() => _saved = true);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Question(
          title: "What's working for you?",
          options: _working,
          selected: _selected,
          onToggle: _toggle,
        ),
        const SizedBox(height: 24),
        _Question(
          title: "What's not working or feels off?",
          options: _notWorking,
          selected: _selected,
          onToggle: _toggle,
        ),
        const SizedBox(height: 24),
        _Question(
          title: 'What do you want more of?',
          options: _wants,
          selected: _selected,
          onToggle: _toggle,
        ),
        const SizedBox(height: 24),
        const Text(
          'Anything else you want to tell us?',
          style: TextStyle(fontSize: 17, color: MpColors.white),
        ),
        const SizedBox(height: 11),
        TextField(
          controller: _note,
          maxLines: 5,
          style: const TextStyle(color: Color(0xFFEEEEEE), fontSize: 13),
          onChanged: (_) => _persist(),
          decoration: InputDecoration(
            hintText: 'Tell us what would make your journey better…',
            hintStyle: const TextStyle(color: MpColors.dim, fontSize: 13),
            filled: true,
            fillColor: const Color(0x80000000),
            contentPadding: const EdgeInsets.all(17),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _persist(markSaved: true),
            style: TextButton.styleFrom(
              foregroundColor: MpColors.bg,
              backgroundColor: MpColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: Text(_saved ? 'Feedback saved' : 'Save feedback'),
          ),
        ),
      ],
    );
  }

  void _toggle(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
    _persist();
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, color: MpColors.white)),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              InkWell(
                onTap: () => onToggle(o),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected.contains(o)
                        ? Colors.white.withOpacity(0.105)
                        : const Color(0x94030405),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected.contains(o)
                          ? Colors.white.withOpacity(0.25)
                          : const Color(0x1AFFFFFF),
                    ),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected.contains(o) ? Colors.white : const Color(0xFFBFC2C3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
