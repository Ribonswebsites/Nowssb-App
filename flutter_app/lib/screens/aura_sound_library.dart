import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';

class AuraSoundLibraryScreen extends StatefulWidget {
  const AuraSoundLibraryScreen({super.key});

  @override
  State<AuraSoundLibraryScreen> createState() => _AuraSoundLibraryScreenState();
}

class _AuraSoundLibraryScreenState extends State<AuraSoundLibraryScreen> {
  final _search = TextEditingController();
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final query = _search.text.trim().toLowerCase();
    final tracks = all.where((w) => query.isEmpty || w.word.toLowerCase().contains(query) || w.meaning.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 38, 22, 34),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sound Library', style: const TextStyle(color: Color(0xFFF1EEE8), fontSize: 31, fontWeight: FontWeight.w400, letterSpacing: -1.5)),
                    const SizedBox(height: 7),
                    const Text('Your personal sound archive', style: TextStyle(color: Color(0xFF8E8B86), fontSize: 14)),
                  ])),
                  const Icon(Icons.graphic_eq_rounded, color: Color(0xFFEFECE5), size: 38),
                ]),
                const SizedBox(height: 27),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search sounds, words, meanings',
                    hintStyle: const TextStyle(color: Color(0xFF777777)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFDDDDDD)),
                    suffixIcon: const Icon(Icons.tune_rounded, color: Color(0xFFD8C39D)),
                    filled: true, fillColor: const Color(0xFF0B0B0B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFF222222))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFF222222))),
                  ),
                ),
                const SizedBox(height: 27),
                Row(children: [
                  for (final entry in ['All Sounds', 'Saved', 'Downloaded'])
                    Padding(padding: const EdgeInsets.only(right: 28), child: GestureDetector(onTap: () => setState(() => _tab = ['All Sounds', 'Saved', 'Downloaded'].indexOf(entry)), child: Column(children: [Text(entry, style: TextStyle(color: _tab == ['All Sounds', 'Saved', 'Downloaded'].indexOf(entry) ? Colors.white : const Color(0xFF777777), fontSize: 14)), const SizedBox(height: 14), if (_tab == ['All Sounds', 'Saved', 'Downloaded'].indexOf(entry)) Container(width: 48, height: 2, color: Colors.white)]))),
                ]),
                const SizedBox(height: 30),
                const Text('COLLECTIONS', style: TextStyle(color: Color(0xFF85817A), fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => Container(
                      width: 108,
                      padding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF171513 + i * 0x030303), Colors.black],
                        ),
                        border: Border.all(color: const Color(0xFF1C1C1C)),
                      ),
                      child: Text(
                        ['Favorites', 'Daily Practice', 'Root Frequencies', 'Downloads'][i],
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('ALL SOUNDS', style: TextStyle(color: Color(0xFF85817A), fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                if (tracks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No sounds found', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...tracks.map((w) => _AuraTrack(word: w)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraTrack extends StatelessWidget {
  const _AuraTrack({required this.word});
  final Word word;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 91),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF151515)))),
    child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF252525), Color(0xFF090909)])), child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF9A9A9A))),
      const SizedBox(width: 13),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(word.word, style: const TextStyle(color: Color(0xFFF1EEE8), fontSize: 14)), const SizedBox(height: 6), Text(word.organ.isEmpty ? 'Sound frequency' : word.organ, style: const TextStyle(color: Color(0xFF74716D), fontSize: 11))])),
      const Text('•••', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 18, letterSpacing: 2)),
    ]),
  );
}
