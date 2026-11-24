// The Player's stage list (opened from the "Stages" chip). One row per real
// stage of the word: for a teacher-recorded word, one row per recording,
// and a locked "Coming soon" row for a stage not recorded yet. Tapping a
// recorded stage plays it in the Player, where Practice scores against it.
// Below the list, one "Request more stages" button. No banners, no video.
import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../data/word_devanagari.dart';
import '../data/word_requests.dart';
import '../player/frequency_ritual.dart';
import '../features/stage_practice/stage_pack.dart';
import '../features/stage_practice/stage_progress.dart';
import '../widgets/nwsb_icon.dart';
import 'player_settings.dart';

/// Rows shown for a word with no teacher recordings: the Player's own
/// levels, named as stages.
const kPlainStageCount = 4;

class SelectLevelScreen extends StatefulWidget {
  const SelectLevelScreen({super.key, this.initialLevel = 1, this.word, this.currentStage = 1, this.onStage});
  final int initialLevel;
  final Word? word;

  /// The stage the Player is on (teacher-recorded words).
  final int currentStage;

  /// Plays stage N in the Player (teacher-recorded words). The sheet closes.
  final ValueChanged<int>? onStage;

  @override
  State<SelectLevelScreen> createState() => _SelectLevelScreenState();
}

class _SelectLevelScreenState extends State<SelectLevelScreen> {
  late int _selected;
  bool _requesting = false;
  bool _requested = false;

  StagePack? get _pack => widget.word == null ? null : StagePack.forWord(widget.word!);

  String get _name {
    final raw = widget.word?.word.trim() ?? '';
    return raw
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _selected = _pack != null
        ? widget.currentStage
        : widget.initialLevel.clamp(1, kPlainStageCount).toInt();
  }

  void _tell(String text) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _request() async {
    if (_requesting || _requested || _name.isEmpty) return;
    setState(() => _requesting = true);
    try {
      final count = _pack?.stages.length ?? kPlainStageCount;
      await WordRequestStore.instance.submit(
        word: _name,
        notes: 'More stages requested for $_name ($count so far).',
        kind: 'stages',
      );
      if (!mounted) return;
      setState(() => _requested = true);
      _tell('Request sent. New stages show here when they are recorded.');
    } catch (e) {
      _tell(e is ArgumentError ? '${e.message}' : 'Could not send the request. Try again.');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deva = widget.word == null ? null : wordDevanagari(widget.word!);
    return ListenableBuilder(
      listenable: StageProgressStore.instance,
      builder: (context, _) => Material(
        color: const Color(0xFF030303),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ListView(
            key: const ValueKey('stages-list'),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _CircleButton(
                  key: const ValueKey('stages-back'),
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                // More → the player's settings (voice, speed, sleep).
                _CircleButton(
                  key: const ValueKey('stages-settings'),
                  icon: Icons.more_horiz_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PlayerSettingsScreen()),
                  ),
                ),
              ]),
              if (_name.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(_name,
                    key: const ValueKey('stages-headline'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
                if (deva != null)
                  Text(deva,
                      key: const ValueKey('stages-headline-deva'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
              ],
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                SizedBox(width: 44, child: Divider(color: Color(0x59FFFFFF))),
                Flexible(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: EditableLabel('select_level.SelectLevelScreen', 'SELECT STAGE',
                            style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w500)))),
                SizedBox(width: 44, child: Divider(color: Color(0x59FFFFFF))),
              ]),
              const SizedBox(height: 18),
              if (widget.word == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Open a word in the Player to see its stages.',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                )
              else
                ..._rows(),
              if (widget.word != null) ...[
                const SizedBox(height: 14),
                _ActionRow(
                  key: const ValueKey('stages-request'),
                  icon: _requested ? Icons.check_rounded : Icons.add_rounded,
                  label: _requested ? 'REQUESTED' : (_requesting ? 'SENDING…' : 'REQUEST MORE STAGES'),
                  onTap: _request,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _rows() {
    final pack = _pack;
    if (pack == null) {
      return [
        for (var n = 1; n <= kPlainStageCount; n++)
          _stageRow(n, sub: frequencyLine(widget.word!, n), onTap: () async {
            setState(() => _selected = n);
            await PracticeProgress.instance.setLevel(n);
          }),
      ];
    }
    final progress = StageProgressStore.instance;
    final out = <Widget>[];
    final numbers = <int>{for (final s in pack.stages) s.number, ...pack.comingSoon}.toList()..sort();
    for (final n in numbers) {
      final st = pack.stages.where((s) => s.number == n).firstOrNull;
      if (st == null) {
        out.add(_stageRow(n,
            sub: 'Your teacher has not recorded it yet',
            locked: true,
            soon: true,
            onTap: () => _tell(stageComingSoonNote(n))));
        continue;
      }
      final rec = progress.record(pack.wordKey, n);
      if (!Entitlements.instance.isAdmin && !progress.isUnlocked(pack.wordKey, n)) {
        out.add(_stageRow(n,
            deva: st.deva,
            sub: 'Pass Stage ${n - 1} to open',
            locked: true,
            onTap: () => _tell('Pass Stage ${n - 1} to open Stage $n.')));
        continue;
      }
      final best = rec.attempts == 0 ? 'Tap to play, then Practice' : 'Best ${rec.best}${rec.passed ? ' · passed' : ''}';
      out.add(_stageRow(n,
          deva: st.deva,
          sub: best,
          passed: rec.passed,
          onTap: () {
            setState(() => _selected = n);
            widget.onStage?.call(n);
          }));
    }
    return out;
  }

  Widget _stageRow(int n, {String deva = '', required String sub, bool locked = false, bool soon = false, bool passed = false, required VoidCallback onTap}) {
    final selected = !locked && _selected == n;
    return GestureDetector(
      key: ValueKey('stages-row-$n'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0x16FFFFFF) : const Color(0x08FFFFFF),
          border: Border.all(color: selected ? const Color(0xE6FFFFFF) : const Color(0x24FFFFFF), width: selected ? 1.4 : 1),
          boxShadow: selected ? const [BoxShadow(color: Color(0x40FFFFFF), blurRadius: 22)] : const [],
        ),
        child: Row(children: [
          SizedBox(
            width: 34,
            child: Text(n.toString().padLeft(2, '0'),
                style: TextStyle(color: locked ? const Color(0x66FFFFFF) : Colors.white, fontSize: 18, fontWeight: FontWeight.w300, height: 1)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(soon ? 'STAGE $n · ${kStageComingSoon.toUpperCase()}' : 'STAGE $n',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: locked ? const Color(0x99FFFFFF) : Colors.white, fontSize: 13, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
              if (deva.isNotEmpty)
                Text(deva,
                    key: ValueKey('stages-deva-$n'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 3),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            ]),
          ),
          if (locked)
            const Icon(Icons.lock_rounded, size: 16, color: Color(0x80FFFFFF))
          else if (passed)
            const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF7BE0A8))
          else if (selected && _pack != null)
            const Icon(Icons.graphic_eq_rounded, size: 18, color: Colors.white)
          else
            const NwsbIcon(NwsbMarks.stages, size: 16, color: Color(0xFFE8D5A3)),
        ]),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))),
          child: Icon(icon, color: Colors.white, size: 20)));
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))),
          child: Row(children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2.2))),
          ])));
}
