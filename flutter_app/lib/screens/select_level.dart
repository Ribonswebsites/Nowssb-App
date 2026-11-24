/// The word's stages, opened from the Player's stage chip. A plain NowssB tab
/// (no banner, no video): the current stage and the next two, expandable to
/// every stage with the rest locked, "Request more stages", and "Buy next 3
/// stages" when the word has more stages than this account has open.
///
///  * Teacher-recorded words (client_words.json → StagePack) list their
///    recorded stages with the client's Devanagari; a stage the teacher has
///    not recorded yet is a locked "Coming soon" slot. Tapping an open stage
///    starts Listen → Your turn → Score for it.
///  * Other words list their content stages; tapping an open one makes it
///    the stage the Player speaks.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../data/word_requests.dart';
import '../features/stage_practice/stage_access.dart';
import '../features/stage_practice/stage_pack.dart';
import '../features/stage_practice/stage_practice_screen.dart' show openStagePractice;
import '../features/stage_practice/stage_progress.dart';
import '../widgets/content_lock.dart' show ensureWordOpen;
import '../widgets/restyle_kit.dart';
import 'poster/poster_kit.dart' show inr;
import 'practice_player.dart' show wordDevanagari;
import 'store/store_actions.dart' show storeBuyNow;

class SelectLevelScreen extends StatefulWidget {
  const SelectLevelScreen({super.key, this.initialLevel = 1, this.word});
  final int initialLevel;
  final Word? word;

  @override
  State<SelectLevelScreen> createState() => _SelectLevelScreenState();
}

/// One row of the tab.
class _StageRow {
  const _StageRow({
    required this.number,
    required this.title,
    this.deva = '',
    this.line = '',
    this.recorded = false,
    this.soon = false,
  });
  final int number;
  final String title;
  final String deva;
  final String line;
  final bool recorded;
  final bool soon;
}

class _SelectLevelScreenState extends State<SelectLevelScreen> {
  late int _level;
  bool _expanded = false;
  bool _requesting = false;
  bool _requested = false;

  Word? get _word => widget.word;
  StagePack? get _pack => _word == null ? null : StagePack.forWord(_word!);

  @override
  void initState() {
    super.initState();
    _level = math.max(1, widget.initialLevel);
    unawaited(StageProgressStore.instance.ensureLoaded());
  }

  String get _name {
    final w = _word?.word ?? '';
    return w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
  }

  List<_StageRow> _rows() {
    final w = _word;
    if (w == null) return const [];
    final pack = _pack;
    if (pack != null) {
      final rows = <_StageRow>[
        for (final s in pack.stages)
          _StageRow(number: s.number, title: s.title.isEmpty ? 'Stage ${s.number}' : s.title, deva: s.deva, recorded: true),
        for (final n in pack.comingSoon) _StageRow(number: n, title: 'Stage $n', soon: true),
      ]..sort((a, b) => a.number.compareTo(b.number));
      return rows;
    }
    if (w.stages.isEmpty) {
      return [_StageRow(number: 1, title: 'Stage 1', deva: wordDevanagari(w) ?? '')];
    }
    return [
      for (var i = 0; i < w.stages.length; i++)
        _StageRow(
          number: i + 1,
          title: w.stages[i].title.trim().isEmpty ? 'Stage ${i + 1}' : w.stages[i].title.trim(),
          line: w.stages[i].text.trim() == w.stages[i].title.trim() ? '' : w.stages[i].text.trim(),
        ),
    ];
  }

  int get _current {
    final pack = _pack;
    if (pack != null) return StageProgressStore.instance.currentStage(pack.wordKey, pack.stages.length);
    final n = _rows().length;
    return n == 0 ? 1 : _level.clamp(1, math.max(1, math.min(n, _openCount(n)))).toInt();
  }

  int _openCount(int total) => _word == null ? 0 : stagesOpenFor(_word!.key, total);

  bool _ownsWord() => _word != null && Entitlements.instance.canOpenWord(_word!);

  // ── actions ────────────────────────────────────────────────────────────

  void _tell(String s) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _tapRow(_StageRow r, int open) async {
    final w = _word;
    if (w == null) return;
    AppHaptics.selection();
    if (r.soon) {
      _tell(stageComingSoonNote(r.number));
      return;
    }
    if (r.number > open) {
      await _buyNext(open);
      return;
    }
    final pack = _pack;
    if (pack != null) {
      final progressOpen = Entitlements.instance.isAdmin || StageProgressStore.instance.isUnlocked(pack.wordKey, r.number);
      if (!progressOpen) {
        _tell('Pass Stage ${r.number - 1} to open Stage ${r.number}.');
        return;
      }
      await openStagePractice(context, w, stage: r.number);
      return;
    }
    if (!await ensureWordOpen(context, w)) return;
    setState(() => _level = r.number);
    await PracticeProgress.instance.setLevel(r.number);
    _tell('${r.title} is now playing in the Player.');
  }

  Future<void> _buyNext(int open) async {
    final w = _word;
    if (w == null) return;
    if (!_ownsWord()) {
      await ensureWordOpen(context, w);
      return;
    }
    final total = _rows().where((r) => !r.soon).length;
    await storeBuyNow(context, stageBundleItem(wordKey: w.key, wordTitle: _name, openCount: open, total: total));
  }

  Future<void> _request() async {
    final w = _word;
    if (w == null || _requesting || _requested) return;
    setState(() => _requesting = true);
    try {
      await WordRequestStore.instance.submit(
        word: _name,
        notes: 'More stages requested for $_name (${_rows().length} so far).',
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

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([StageProgressStore.instance, Entitlements.instance]),
      builder: (context, _) => Material(
        color: const Color(0xFF07070C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ListView(
            key: const ValueKey('stages-list'),
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(children: [
                  KitBackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_name.isEmpty ? 'STAGES' : 'STAGES · ${_name.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(_headline(),
                          key: const ValueKey('stages-headline'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.25)),
                    ]),
                  ),
                ]),
              ),
              if (_word == null)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text('Open a word in the Player to see its stages.',
                      style: TextStyle(color: kKitMuted, fontSize: 14, height: 1.4)),
                )
              else ...[
                _stagesPane(),
                _morePane(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The word in Devanagari when the content has it, else its name.
  String _headline() {
    final w = _word;
    if (w == null) return 'Stages';
    final pack = _pack;
    final deva = (pack != null && pack.deva.isNotEmpty) ? pack.deva : wordDevanagari(w);
    return deva ?? _name;
  }

  Widget _stagesPane() {
    final rows = _rows();
    final total = rows.where((r) => !r.soon).length;
    final open = _openCount(total);
    final current = _current;
    // Collapsed: the current stage and the next two. Expanded: every stage.
    final start = rows.indexWhere((r) => r.number == current).clamp(0, math.max(0, rows.length - 1)).toInt();
    final window = rows.skip(start).take(3).toList();
    if (window.length < 3) {
      window.insertAll(0, rows.take(start).toList().reversed.take(3 - window.length).toList().reversed);
    }
    final hidden = rows.length - window.length;
    final shown = _expanded ? rows : window;
    return KitPane(
      eyebrow: 'Practice · Stages',
      title: '${math.min(open, total)} of ${rows.length} open',
      mark: NwsbMarks.stages,
      onHead: hidden > 0 ? _toggle : null,
      trailing: hidden > 0
          ? Semantics(
              button: true,
              label: _expanded ? 'Show fewer stages' : 'Show all stages',
              child: GestureDetector(
                key: const ValueKey('stages-expand'),
                onTap: _toggle,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x1AFFFFFF),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.white, size: 22),
                ),
              ),
            )
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final r in shown) _row(r, open, current),
        if (!_expanded && hidden > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: KitActionPill(
              'Show all ${rows.length} stages',
              key: const ValueKey('stages-show-all'),
              icon: Icons.expand_more_rounded,
              primary: false,
              onTap: _toggle,
            ),
          ),
      ]),
    );
  }

  void _toggle() {
    AppHaptics.selection();
    setState(() => _expanded = !_expanded);
  }

  Widget _row(_StageRow r, int open, int current) {
    final pack = _pack;
    final bought = r.number <= open;
    final progressOpen = pack == null ||
        Entitlements.instance.isAdmin ||
        StageProgressStore.instance.isUnlocked(pack.wordKey, r.number);
    final rec = pack == null ? null : StageProgressStore.instance.record(pack.wordKey, r.number);
    final locked = r.soon || !bought || !progressOpen;
    final isNow = !locked && r.number == current;
    final String sub;
    if (r.soon) {
      sub = kStageComingSoon;
    } else if (!bought) {
      sub = 'Locked · in the next 3 stages';
    } else if (!progressOpen) {
      sub = 'Opens when Stage ${r.number - 1} is passed';
    } else if (rec != null && rec.attempts > 0) {
      sub = 'Best ${rec.best}${rec.passed ? ' · passed' : ''}';
    } else if (r.line.isNotEmpty) {
      sub = r.line;
    } else {
      sub = isNow ? 'Your stage now' : 'Open';
    }
    return Semantics(
      button: true,
      label: '${r.title}. $sub',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('stages-row-${r.number}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => unawaited(_tapRow(r, open)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            KitIconBadge(
              locked ? Icons.lock_rounded : (rec?.passed ?? false) ? Icons.check_rounded : Icons.graphic_eq_rounded,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title,
                    style: TextStyle(
                        color: locked ? const Color(0x99FFFFFF) : Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                if (r.deva.isNotEmpty)
                  Text(r.deva,
                      key: ValueKey('stages-deva-${r.number}'),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 2),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kKitMuted, fontSize: 12.5)),
              ]),
            ),
            if (isNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: const Text('NOW',
                    style: TextStyle(color: Color(0xFF0B0B10), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              )
            else
              Icon(locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded, color: kKitMuted, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _morePane() {
    final rows = _rows();
    final total = rows.where((r) => !r.soon).length;
    final open = _openCount(total);
    final canBuy = open < total;
    final item = canBuy && _word != null
        ? stageBundleItem(wordKey: _word!.key, wordTitle: _name, openCount: open, total: total)
        : null;
    return KitPane(
      eyebrow: 'More stages',
      title: canBuy ? 'Open the next stages' : 'Want to go further?',
      mark: NwsbMarks.thought,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          canBuy
              ? (_ownsWord()
                  ? 'One purchase opens the next 3 stages of $_name, yours to keep.'
                  : 'Unlock $_name first; it comes with its first 3 stages.')
              : _requested
                  ? 'Your request for more $_name stages is with the teacher.'
                  : 'Every stage of $_name that exists is listed above. Ask the teacher to record more.',
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (item != null) ...[
          KitActionPill(
            _ownsWord() ? 'Buy next 3 stages · ${inr(item.price, sku: item.id)}' : 'Unlock $_name',
            key: const ValueKey('stages-buy-next'),
            icon: Icons.shopping_bag_outlined,
            onTap: () => unawaited(_buyNext(open)),
          ),
          const SizedBox(height: 10),
        ],
        KitActionPill(
          _requested ? 'Requested' : 'Request more stages',
          key: const ValueKey('stages-request'),
          icon: _requested ? Icons.check_rounded : Icons.add_rounded,
          primary: false,
          busy: _requesting,
          onTap: _requested ? null : () => unawaited(_request()),
        ),
      ]),
    );
  }
}
