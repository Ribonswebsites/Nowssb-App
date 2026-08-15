/// The Library — every word the app teaches, searchable.
///
/// One list, filtered live. The website spreads this across the Word Atelier
/// and the sound library; what both are actually doing is showing the same
/// `content/library` document, so this is one screen over one list with a
/// search field and a row of category filters built FROM the data rather
/// than hardcoded beside it — add a category to a word in the studio and the
/// filter appears here on its own.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'word_detail.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _search = TextEditingController();
  String _category = '';

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    _search.dispose();
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;

    final categories = <String>{for (final w in all) ...w.categories}.toList()
      ..sort();

    final q = _search.text.trim().toLowerCase();
    final shown = all.where((w) {
      if (_category.isNotEmpty && !w.categories.contains(_category)) {
        return false;
      }
      if (q.isEmpty) return true;
      // Everything a person might reasonably type: the roman spelling, the
      // Devanagari, the meaning, and the organ it works on.
      return w.word.toLowerCase().contains(q) ||
          w.deva.contains(q) ||
          w.meaning.toLowerCase().contains(q) ||
          w.organ.toLowerCase().contains(q);
    }).toList();

    return PageShell(
      eyebrow: '${all.length} words',
      title: 'The Library',
      film: 'assets/video/word-acts.mp4',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            _SearchField(controller: _search),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Chip(
                      label: 'All',
                      on: _category.isEmpty,
                      onTap: () => setState(() => _category = ''),
                    ),
                    for (final c in categories)
                      _Chip(
                        label: c,
                        on: _category == c,
                        onTap: () =>
                            setState(() => _category = _category == c ? '' : c),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Text(
                    q.isEmpty ? 'Nothing here yet.' : 'No word matches “$q”.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0x8CFFFFFF),
                    ),
                  ),
                ),
              )
            else
              for (final w in shown) _row(context, w),
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Word w) => WordRow(
        word: w.word,
        deva: w.deva,
        sub: w.meaning.isNotEmpty ? w.meaning : w.organ,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WordDetail(word: w)),
        ),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 19, color: Color(0x99FFFFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              cursorColor: NwsbColors.goldLight,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search any word or meaning…',
                hintStyle: TextStyle(fontSize: 14, color: Color(0x8CFFFFFF)),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: controller.clear,
              child:
                  const Icon(Icons.close, size: 18, color: Color(0x99FFFFFF)),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: on ? Colors.white : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: on ? Colors.white : const Color(0x24FFFFFF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
              color: on ? NwsbColors.ink : const Color(0xCCFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
