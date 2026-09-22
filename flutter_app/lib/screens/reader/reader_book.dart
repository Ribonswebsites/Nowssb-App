/// Meaning Reader and eBook Reader — `#sub-reader-meaning` / `#sub-reader-ebook`.
///
/// Transcribed from app/js/part065.js. Same pages, same tools, same
/// preferences. The two UIs stay different on purpose: the Meaning Reader
/// has a Previous / Highlight / Next footer; the eBook Reader has chevrons
/// and a contents row.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/reader_store.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_image.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_thinking_loader.dart';
import 'reader_epub.dart';
import 'reader_lookup.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

enum ReaderKind { meaning, ebook }

class ReaderBookScreen extends StatefulWidget {
  const ReaderBookScreen({super.key, required this.kind, this.initialBook});

  final ReaderKind kind;
  final EbBook? initialBook;

  @override
  State<ReaderBookScreen> createState() => _ReaderBookScreenState();
}

class _ReaderBookScreenState extends State<ReaderBookScreen> {
  final _store = ReaderStore.instance;
  final _stage = ScrollController();

  int _idx = 0;
  EbBook? _book;
  OpenedEpub? _epub;
  bool _swipeOn = false;
  bool _immersive = false;
  bool _settings = false;
  bool _toc = false;
  bool _tools = false;
  bool _notepad = false;
  bool _remind = false;
  bool _web = false;
  bool _railOpen = false;
  String _toast = '';
  Timer? _toastT;
  String _noteOn = '';
  final _noteIn = TextEditingController();
  String _webMode = 'translate';
  String _webText = '';
  String _webBody = '';
  bool _webWait = false;
  Offset? _fabDrag;

  bool get _isMeaning => widget.kind == ReaderKind.meaning;
  String get _bookKey =>
      _isMeaning ? 'meanings' : (_epub?.key ?? _book?.key ?? '');

  List<ReaderPage> get _pages {
    if (_isMeaning) return _store.meaningPages();
    if (_epub != null) return _epub!.pages;
    if (_book != null) return _store.bookPages(_book!);
    return const [];
  }

  ReaderPage? get _page {
    final pages = _pages;
    if (pages.isEmpty) return null;
    final i = _idx.clamp(0, pages.length - 1);
    return pages[i];
  }

  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    _store.addListener(_onStore);
    unawaited(_store.ensureLoaded());
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _toastT?.cancel();
    _noteIn.dispose();
    _stage.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _haptic([int ms = 15]) {
    if (ms >= 24) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _toastNow(String msg) {
    _toastT?.cancel();
    setState(() => _toast = msg);
    _toastT = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _toast = '');
    });
  }

  void _go(int dir) {
    final last = _pages.length - 1;
    if ((_idx <= 0 && dir < 0) || (_idx >= last && dir > 0)) {
      _haptic(8);
      return;
    }
    setState(() {
      _idx += dir;
      _settings = false;
      _tools = false;
    });
    if (_stage.hasClients) _stage.jumpTo(0);
    _haptic(12);
  }

  void _jump(int i) {
    setState(() {
      _idx = i.clamp(0, math.max(0, _pages.length - 1));
      _toc = false;
      _notepad = false;
    });
    if (_stage.hasClients) _stage.jumpTo(0);
    _haptic(20);
  }

  Future<void> _openEpub() async {
    _haptic(20);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['epub'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final f = picked.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        _toastNow('Could not read that file');
        return;
      }
      _toastNow('Opening ${f.name}…');
      final book = buildEpub(bytes, f.name);
      _store.rememberEpub(book);
      setState(() {
        _epub = book;
        _book = EbBook(
          key: book.key,
          title: book.title,
          sub: book.sub,
          price: 0,
          cover: book.cover,
          about: book.sub,
          contents: [for (final p in book.pages) p.title],
        );
        _idx = 0;
      });
      _toastNow('${book.pages.length} chapters');
      _haptic(28);
    } on FormatException catch (e) {
      const why = {
        'not-a-zip': 'That file is not an EPUB.',
        'no-opf': 'That EPUB has no readable index.',
        'empty-spine': 'That EPUB lists no chapters.',
        'no-text': 'That EPUB has no text to show.',
      };
      _toastNow(why[e.message] ?? 'Could not open that EPUB');
    } catch (_) {
      _toastNow('Could not open that EPUB');
    }
  }

  Future<void> _mark(String what, {bool wholePage = false}) async {
    final pg = _page;
    if (pg == null) return;
    final text = wholePage ? pg.plain : '';
    if (what == 'hl') {
      if (text.isEmpty) {
        _toastNow('Select some text first');
        return;
      }
      await _store.addHighlight(_bookKey, _idx, text);
      _toastNow('Highlighted');
      _haptic(28);
    } else if (what == 'note') {
      setState(() {
        _noteOn = text.length > 160 ? text.substring(0, 160) : text;
        _notepad = true;
      });
    } else if (what == 'copy') {
      final t = text.isEmpty ? pg.plain : text;
      await Clipboard.setData(ClipboardData(text: t));
      _toastNow('Copied');
      _haptic(20);
    } else if (what == 'translate' || what == 'search') {
      final t = text.isEmpty ? pg.plain : text;
      await _openWeb(what, t);
    }
  }

  Future<void> _highlightSelection(String text) async {
    final t = text.trim();
    if (t.length < 2) {
      _toastNow('Select some text first');
      return;
    }
    await _store.addHighlight(_bookKey, _idx, t);
    _toastNow('Highlighted');
    _haptic(28);
  }

  Future<void> _noteSelection(String text) async {
    final t = text.trim();
    setState(() {
      _noteOn = t.length > 160 ? t.substring(0, 160) : t;
      _notepad = true;
      _tools = false;
    });
  }

  Future<void> _openWeb(String mode, String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      _toastNow('Select some text first');
      return;
    }
    setState(() {
      _web = true;
      _webMode = mode;
      _webText = t;
      _webWait = true;
      _webBody = '';
      _tools = false;
    });
    _haptic(20);
    if (mode == 'translate') {
      final out = await ReaderLookup.translate(t, _store.lang);
      if (!mounted) return;
      setState(() {
        _webWait = false;
        _webBody = out ?? '';
      });
    } else {
      final rows = await ReaderLookup.search(t);
      if (!mounted) return;
      setState(() {
        _webWait = false;
        _webBody = rows.isEmpty
            ? ''
            : rows.map((r) => '${r.$1}\n${r.$2}').join('\n\n');
      });
    }
  }

  Future<void> _saveWeb() async {
    final t = _webBody.trim();
    if (t.isEmpty) {
      _toastNow('Nothing to save');
      return;
    }
    await _store.addNote(_bookKey, _idx,
        t: t, on: _webText.length > 80 ? _webText.substring(0, 80) : _webText);
    _toastNow('Saved to notepad');
    _haptic(28);
  }

  ThemeData get _chrome {
    final dark = _store.prefs.theme == 'dark' || _store.prefs.theme == 'black';
    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      useMaterial3: false,
    );
  }

  Color get _shell {
    switch (_store.prefs.theme) {
      case 'light':
      case 'sepia':
        return const Color(0xFF14151A);
      case 'dark':
        return const Color(0xFF101115);
      default:
        return Colors.black;
    }
  }

  Color get _pageBg {
    switch (_store.prefs.theme) {
      case 'light':
        return const Color(0xFFFBFAF7);
      case 'dark':
        return const Color(0xFF22242A);
      case 'black':
        return Colors.black;
      default:
        return const Color(0xFFF4EFE4);
    }
  }

  Color get _pageFg {
    switch (_store.prefs.theme) {
      case 'light':
        return const Color(0xFF1D1D1F);
      case 'dark':
        return const Color(0xFFE6E3DC);
      case 'black':
        return const Color(0xFFD8D5CF);
      default:
        return const Color(0xFF241F18);
    }
  }

  TextStyle _fontStyle(double size,
      {FontWeight w = FontWeight.w400, double height = 1.72}) {
    final color = _pageFg;
    if (_flutterTest) {
      return TextStyle(
          fontSize: size, fontWeight: w, height: height, color: color);
    }
    switch (_store.prefs.font) {
      case 'DM Sans':
        return GoogleFonts.dmSans(
            fontSize: size, fontWeight: w, height: height, color: color);
      case 'Georgia':
        return GoogleFonts.notoSerif(
            fontSize: size, fontWeight: w, height: height, color: color);
      case 'Iowan':
        return GoogleFonts.libreBaskerville(
            fontSize: size, fontWeight: w, height: height, color: color);
      default:
        return GoogleFonts.lora(
            fontSize: size, fontWeight: w, height: height, color: color);
    }
  }

  double get _lineHeight {
    switch (_store.prefs.spacing) {
      case 0:
        return 1.5;
      case 2:
        return 2.02;
      default:
        return 1.72;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLib = !_isMeaning && _book == null && _epub == null;
    return Theme(
      data: _chrome,
      child: Scaffold(
        backgroundColor: _shell,
        body: Stack(
          children: [
            if (showLib) _library() else _reader(),
            if (_toast.isNotEmpty)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 96),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80000000),
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Text(
                        _toast,
                        style: const TextStyle(
                          color: NwsbColors.deep,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _library() {
    final list = [
      ..._store.epubs.map((e) => EbBook(
            key: e.key,
            title: e.title,
            sub: e.sub,
            price: 0,
            cover: e.cover,
            about: e.sub,
            contents: [for (final p in e.pages) p.title],
          )),
      ..._store.libraryBooks(),
    ];
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        _topBar(
          backLabel: 'Back',
          title: 'eBook Reader',
          sub: '${list.length} in your library',
          onBack: () => Navigator.of(context).pop(),
          padTop: top,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
            children: [
              _libRow(
                open: true,
                title: 'Open an EPUB',
                sub: 'Read a .epub from this device',
                meta: 'Opened here, nothing uploaded',
                onTap: _openEpub,
              ),
              const SizedBox(height: 12),
              for (final b in list) ...[
                _libRow(
                  cover: b.cover,
                  title: b.title,
                  sub: b.sub,
                  meta: '${b.contents.length} chapters',
                  onTap: () {
                    OpenedEpub? opened;
                    for (final e in _store.epubs) {
                      if (e.key == b.key) opened = e;
                    }
                    setState(() {
                      _book = b;
                      _epub = opened;
                      _idx = 0;
                    });
                    _haptic(28);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _libRow({
    String cover = '',
    bool open = false,
    required String title,
    required String sub,
    required String meta,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(7),
              ),
              clipBehavior: Clip.antiAlias,
              child: open
                  ? const Icon(Icons.file_upload_outlined, color: Colors.white)
                  : (cover.isEmpty
                      ? const SizedBox.shrink()
                      : NwsbImage(url: cover)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w300,
                          height: 1.45)),
                  const SizedBox(height: 5),
                  Text(meta,
                      style: const TextStyle(
                          color: Color(0xCCE8D5A3),
                          fontSize: 10,
                          letterSpacing: 0.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0x59FFFFFF), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _reader() {
    final pages = _pages;
    final pg = _page;
    final top = MediaQuery.paddingOf(context).top;
    final bot = MediaQuery.paddingOf(context).bottom;
    final n = pages.length;
    final pct = n == 0 ? 0 : (((_idx + 1) / n) * 100).round();
    final left = n - _idx - 1;
    final pm = _store.pageMarks(_bookKey, _idx);

    return Stack(
      children: [
        Column(
          children: [
            if (!_immersive)
              _topBar(
                backLabel: _isMeaning ? 'Library' : '',
                title: _isMeaning
                    ? 'The Book of Meanings'
                    : (_epub?.title ?? _book?.title ?? 'Reader'),
                sub: pg?.chapterName ?? '',
                onBack: () {
                  if (_isMeaning) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _book = null;
                      _epub = null;
                      _idx = 0;
                    });
                  }
                },
                padTop: top,
                trailing: [
                  if (_isMeaning)
                    _iconBtn(
                      onTap: () => setState(() => _toc = true),
                      child: const Icon(Icons.menu_book_outlined,
                          size: 19, color: Colors.white),
                    )
                  else ...[
                    _iconBtn(
                      onTap: () => setState(() => _settings = !_settings),
                      child: const Text('Aa',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                    _iconBtn(
                      onTap: () => setState(() => _tools = true),
                      child: const Icon(Icons.more_vert,
                          size: 20, color: Colors.white),
                    ),
                  ],
                ],
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: _swipeOn
                    ? null
                    : (d) {
                        final v = d.primaryVelocity ?? 0;
                        if (v.abs() < 280) return;
                        _go(v < 0 ? 1 : -1);
                      },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _immersive ? 14 : 52,
                    4,
                    _isMeaning ? 14 : 34,
                    14,
                  ),
                  child: Stack(
                    children: [
                      _pageCard(pg, n),
                      if (!_isMeaning) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _chev(true, _idx == 0),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _chev(false, _idx >= n - 1),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!_immersive && !_isMeaning) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: DefaultTextStyle(
                  style:
                      const TextStyle(color: Color(0x80FFFFFF), fontSize: 10.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _toc = true),
                        child: const Text('Contents',
                            style: TextStyle(color: Color(0xB3FFFFFF))),
                      ),
                      Text('${_idx + 1} of $n'),
                      Text('$pct%'),
                      Text(left == 0
                          ? 'last page'
                          : '$left page${left == 1 ? '' : 's'} left'),
                    ],
                  ),
                ),
              ),
              _prog(pct),
            ],
            if (!_immersive && _isMeaning) _meaningFoot(n, pct, bot),
            if (_settings) _settingsTray(bot),
          ],
        ),
        if (!_immersive) _rail(),
        if (_immersive) _fab(),
        if (_immersive && _railOpen) _rail(),
        IgnorePointer(
          child: ColoredBox(
            color: Colors.black.withValues(
              alpha: (100 - _store.prefs.bright) / 100 * 0.66,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (_toc) _tocSheet(pages),
        if (_tools) _toolsSheet(pm),
        if (_notepad) _notepadSheet(),
        if (_remind) _remindSheet(pg?.title ?? 'this page'),
        if (_web) _webSheet(),
      ],
    );
  }

  Widget _pageCard(ReaderPage? pg, int total) {
    if (pg == null) {
      return const Center(
        child: AppThinkingLoader(label: 'Preparing…', state: OrbState.composing),
      );
    }
    final size = _store.prefs.size.toDouble();
    final pm = _store.pageMarks(_bookKey, _idx);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        controller: _stage,
        child: Column(
          children: [
            Text(
              pg.chapter > 0
                  ? 'CHAPTER ${pg.chapter}'
                  : pg.chapterName.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: _pageFg.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pg.title,
              textAlign: TextAlign.center,
              style: _fontStyle(size * 1.72, w: FontWeight.w600, height: 1.18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 54,
                      height: 1,
                      color: _pageFg.withValues(alpha: 0.4)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('✦',
                        style: TextStyle(
                            fontSize: 11,
                            color: _pageFg.withValues(alpha: 0.4))),
                  ),
                  Container(
                      width: 54,
                      height: 1,
                      color: _pageFg.withValues(alpha: 0.4)),
                ],
              ),
            ),
            if (pg.root != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  pg.root!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: _pageFg.withValues(alpha: 0.6),
                  ),
                ),
              ),
            if (pg.pending)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 6),
                child: Text(
                  'This chapter has no text in the app yet. When it is added it will open here, in this reader.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                    color: _pageFg.withValues(alpha: 0.62),
                  ),
                ),
              )
            else
              for (var i = 0; i < pg.body.length; i++)
                _para(pg.body[i], i == 0 && pg.first, size, pm.hl),
            const SizedBox(height: 22),
            Text(
              '${_idx + 1} of $total',
              style: TextStyle(
                  fontSize: 11, color: _pageFg.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _para(String raw, bool drop, double size, List<String> hl) {
    final spans = _highlightSpans(raw, hl, size, drop);
    Widget child = SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      contextMenuBuilder: (context, state) {
        final sel = state.textEditingValue.selection;
        final t = sel.isValid
            ? state.textEditingValue.text.substring(sel.start, sel.end)
            : '';
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: 'Highlight',
              onPressed: () {
                ContextMenuController.removeAny();
                _highlightSelection(t);
              },
            ),
            ContextMenuButtonItem(
              label: 'Note',
              onPressed: () {
                ContextMenuController.removeAny();
                _noteSelection(t);
              },
            ),
            ContextMenuButtonItem(
              label: 'Copy',
              onPressed: () {
                ContextMenuController.removeAny();
                Clipboard.setData(ClipboardData(text: t));
                _toastNow('Copied');
              },
            ),
            ContextMenuButtonItem(
              label: 'Translate',
              onPressed: () {
                ContextMenuController.removeAny();
                _openWeb('translate', t);
              },
            ),
            ContextMenuButtonItem(
              label: 'Search',
              onPressed: () {
                ContextMenuController.removeAny();
                _openWeb('search', t);
              },
            ),
          ],
        );
      },
    );
    if (_swipeOn) {
      child = GestureDetector(
        onTap: () async {
          await _store.swipeHighlight(_bookKey, _idx, raw);
          _toastNow('Highlighted · saved to notepad');
          _haptic(16);
        },
        child: child,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: child,
    );
  }

  List<InlineSpan> _highlightSpans(
      String raw, List<String> hl, double size, bool drop) {
    final base = _fontStyle(size, height: _lineHeight);
    if (hl.isEmpty) {
      if (!drop || raw.isEmpty) return [TextSpan(text: raw, style: base)];
      return [
        TextSpan(
          text: raw[0],
          style: base.copyWith(
            fontSize: size * 3.1,
            height: 0.86,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: raw.substring(1), style: base),
      ];
    }
    // Longest-first so overlapping phrases paint once.
    final hits = [...hl]..sort((a, b) => b.length.compareTo(a.length));
    final marked = <int>{};
    final ranges = <(int, int)>[];
    for (final h in hits) {
      if (h.isEmpty) continue;
      var i = 0;
      while (true) {
        final at = raw.indexOf(h, i);
        if (at < 0) break;
        final covered = List.generate(h.length, (k) => at + k);
        if (covered.every(marked.contains)) {
          i = at + 1;
          continue;
        }
        for (final k in covered) {
          marked.add(k);
        }
        ranges.add((at, at + h.length));
        i = at + h.length;
      }
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final out = <InlineSpan>[];
    var cursor = 0;
    for (final r in ranges) {
      if (r.$1 > cursor) {
        out.add(TextSpan(text: raw.substring(cursor, r.$1), style: base));
      }
      out.add(TextSpan(
        text: raw.substring(r.$1, r.$2),
        style: base.copyWith(backgroundColor: const Color(0x66E8D5A3)),
      ));
      cursor = r.$2;
    }
    if (cursor < raw.length) {
      out.add(TextSpan(text: raw.substring(cursor), style: base));
    }
    return out;
  }

  Widget _meaningFoot(int n, int pct, double bot) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bot),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_idx + 1} of $n',
                  style: const TextStyle(
                      color: Color(0xA6FFFFFF), fontSize: 10.5)),
              const SizedBox(width: 10),
              Expanded(child: _prog(pct, inset: false)),
              const SizedBox(width: 10),
              Text('$pct%',
                  style: const TextStyle(
                      color: Color(0xA6FFFFFF), fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _navBtn('Previous', true, _idx == 0, () => _go(-1)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() => _swipeOn = !_swipeOn);
                  _toastNow(_swipeOn
                      ? 'Swipe across any line to highlight it'
                      : 'Swipe highlight off');
                  _haptic(20);
                },
                icon: Icon(Icons.highlight_alt,
                    size: 15,
                    color: _swipeOn
                        ? NwsbColors.goldLight
                        : const Color(0xB3FFFFFF)),
                label: Text('Highlight',
                    style: TextStyle(
                        color: _swipeOn
                            ? NwsbColors.goldLight
                            : const Color(0xB3FFFFFF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: _navBtn('Next', false, _idx >= n - 1, () => _go(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(String label, bool left, bool off, VoidCallback onTap) {
    return TextButton(
      onPressed: off ? null : onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (left)
              const Icon(Icons.chevron_left,
                  size: 15, color: Color(0xD9FFFFFF)),
            Text(label,
                style: TextStyle(
                    color:
                        off ? const Color(0x47FFFFFF) : const Color(0xD9FFFFFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            if (!left)
              const Icon(Icons.chevron_right,
                  size: 15, color: Color(0xD9FFFFFF)),
          ],
        ),
      ),
    );
  }

  Widget _prog(int pct, {bool inset = true}) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: pct / 100,
        minHeight: 3,
        backgroundColor: const Color(0x29FFFFFF),
        color: NwsbColors.goldLight,
      ),
    );
    if (!inset) return bar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: bar,
    );
  }

  Widget _chev(bool left, bool off) {
    return IconButton(
      onPressed: off ? null : () => _go(left ? -1 : 1),
      icon: Icon(
        left ? Icons.chevron_left : Icons.chevron_right,
        color: off ? const Color(0x2EFFFFFF) : const Color(0x73FFFFFF),
        size: 20,
      ),
    );
  }

  Widget _topBar({
    required String backLabel,
    required String title,
    required String sub,
    required VoidCallback onBack,
    required double padTop,
    List<Widget> trailing = const [],
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, padTop + 6, 8, 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 19),
            label: Text(backLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (sub.isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w300)),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }

  Widget _iconBtn({required VoidCallback onTap, required Widget child}) {
    return IconButton(onPressed: onTap, icon: child);
  }

  Widget _rail() {
    Widget cell(
        {Key? key, required VoidCallback onTap, required Widget child}) {
      return SizedBox(
        key: key,
        width: 42,
        height: 42,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: child,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: const BoxDecoration(
          color: Color(0xE60C0C0E),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
          border: Border.fromBorderSide(BorderSide(color: Color(0x1AFFFFFF))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(
              onTap: () => setState(() => _notepad = true),
              child:
                  const Icon(Icons.notes, color: Color(0xD1FFFFFF), size: 19),
            ),
            cell(
              key: const Key('rd-rail-settings'),
              onTap: () => setState(() => _settings = !_settings),
              child: const Text('Aa',
                  style: TextStyle(
                      color: Color(0xD1FFFFFF), fontWeight: FontWeight.w700)),
            ),
            cell(
              onTap: () => _store.setPref(theme: 'light'),
              child: const Icon(Icons.wb_sunny_outlined,
                  color: Color(0xD1FFFFFF), size: 19),
            ),
            cell(
              onTap: () => _store.setPref(theme: 'black'),
              child: const Icon(Icons.dark_mode_outlined,
                  color: Color(0xD1FFFFFF), size: 19),
            ),
            cell(
              key: const Key('rd-rail-tools'),
              onTap: () => setState(() => _tools = true),
              child: const Icon(Icons.highlight_alt,
                  color: Color(0xD1FFFFFF), size: 19),
            ),
            cell(
              onTap: () {
                setState(() {
                  _immersive = !_immersive;
                  _railOpen = false;
                });
                _toastNow(_immersive
                    ? 'Full screen — tap the pencil for the tools'
                    : 'Full screen off');
                _haptic(18);
              },
              child: Icon(
                _immersive ? Icons.fullscreen_exit : Icons.fullscreen,
                color: const Color(0xD1FFFFFF),
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab() {
    final size = MediaQuery.sizeOf(context);
    var x = _fabDrag?.dx ?? _store.fabX;
    var y = _fabDrag?.dy ?? _store.fabY;
    x = x.clamp(6, size.width - 50);
    y = y.clamp(6, size.height - 50);
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          _fabDrag = Offset(
            (_fabDrag?.dx ?? _store.fabX) + d.delta.dx,
            (_fabDrag?.dy ?? _store.fabY) + d.delta.dy,
          );
        }),
        onPanEnd: (_) {
          final p = _fabDrag ?? Offset(_store.fabX, _store.fabY);
          _store.setFabPos(p.dx, p.dy);
        },
        onTap: () => setState(() => _railOpen = !_railOpen),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x29FFFFFF)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 22,
                  offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _settingsTray(double bot) {
    final p = _store.prefs;
    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10 + bot),
      decoration: const BoxDecoration(
        color: Color(0xF70E0E11),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _setRow(
              'Font',
              Row(
                children: [
                  _tinyBtn('−', () => _store.cycleFont(-1)),
                  Expanded(
                    child: Text(p.font,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.5)),
                  ),
                  _tinyBtn('+', () => _store.cycleFont(1)),
                ],
              ),
            ),
            _setRow(
              'Text Size',
              Row(
                children: [
                  const Text('A',
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: p.size.toDouble(),
                      min: 14,
                      max: 26,
                      divisions: 12,
                      activeColor: NwsbColors.goldLight,
                      onChanged: (v) => _store.setPref(size: v.round()),
                    ),
                  ),
                  const Text('A',
                      style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 17)),
                ],
              ),
            ),
            _setRow(
              'Spacing',
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _store.setPref(spacing: i),
                        child: Container(
                          width: 46,
                          height: 32,
                          decoration: BoxDecoration(
                            color: p.spacing == i
                                ? const Color(0x38E8D5A3)
                                : const Color(0x0FFFFFFF),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: p.spacing == i
                                  ? const Color(0x80E8D5A3)
                                  : const Color(0x1FFFFFFF),
                            ),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 10.0 + i * 4,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Color(0xD9FFFFFF), width: 1.6),
                                    bottom: BorderSide(
                                        color: Color(0xD9FFFFFF), width: 1.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _setRow(
              'Theme',
              Row(
                children: [
                  for (final t in kReaderThemes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _store.setPref(theme: t),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: switch (t) {
                              'light' => const Color(0xFFFBFAF7),
                              'sepia' => const Color(0xFFCBB894),
                              'dark' => const Color(0xFF4A4D55),
                              _ => Colors.black,
                            },
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.theme == t
                                  ? NwsbColors.goldLight
                                  : (t == 'black'
                                      ? const Color(0x40FFFFFF)
                                      : Colors.transparent),
                              width: 1.5,
                            ),
                          ),
                          child: Text('Aa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: t == 'light' || t == 'sepia'
                                    ? const Color(0xFF241F18)
                                    : const Color(0xFFE6E3DC),
                              )),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _setRow(
              'Brightness',
              Row(
                children: [
                  const Text('☀',
                      style: TextStyle(fontSize: 11, color: Color(0x80FFFFFF))),
                  Expanded(
                    child: Slider(
                      value: p.bright.toDouble(),
                      min: 35,
                      max: 100,
                      activeColor: NwsbColors.goldLight,
                      onChanged: (v) => _store.setPref(bright: v.round()),
                    ),
                  ),
                  const Text('☀',
                      style: TextStyle(fontSize: 15, color: Color(0xCCFFFFFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0x8CFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _tinyBtn(String t, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x21FFFFFF)),
        ),
        child:
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _sheet({
    required String title,
    String sub = '',
    required Widget body,
    VoidCallback? onClose,
  }) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xF708080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.paddingOf(context).top + 10, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        if (sub.isNotEmpty)
                          Text(sub,
                              style: const TextStyle(
                                  color: Color(0x80FFFFFF), fontSize: 11.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose ??
                        () => setState(() {
                              _toc = false;
                              _tools = false;
                              _notepad = false;
                              _remind = false;
                              _web = false;
                            }),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0x1AFFFFFF)),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _tocSheet(List<ReaderPage> pages) {
    return _sheet(
      title: 'Contents',
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
        itemCount: pages.length,
        itemBuilder: (context, i) {
          final q = pages[i];
          final on = i == _idx;
          return GestureDetector(
            onTap: () => _jump(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: on ? const Color(0x1FE8D5A3) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      q.chapter > 0 ? '${q.chapter}' : '·',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xCCE8D5A3),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                        if (_isMeaning)
                          Text(q.chapterName,
                              style: const TextStyle(
                                  color: Color(0x80FFFFFF), fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _toolsSheet(PageMarks pm) {
    Widget tool(IconData ic, String label, VoidCallback onTap,
        {bool on = false}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: on ? const Color(0x26E8D5A3) : const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: on ? const Color(0x80E8D5A3) : const Color(0x1AFFFFFF)),
          ),
          child: Column(
            children: [
              Icon(ic, color: Colors.white, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return _sheet(
      title: 'Page tools',
      onClose: () => setState(() => _tools = false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: [
              tool(Icons.bookmark_border, pm.mark ? 'Bookmarked' : 'Bookmark',
                  () async {
                final on = await _store.toggleBookmark(_bookKey, _idx);
                setState(() => _tools = false);
                _toastNow(on ? 'Bookmarked' : 'Bookmark removed');
                _haptic(28);
              }, on: pm.mark),
              tool(
                  Icons.notes,
                  'Notepad',
                  () => setState(() {
                        _tools = false;
                        _notepad = true;
                      })),
              tool(Icons.highlight_alt, 'Swipe highlight', () {
                setState(() {
                  _swipeOn = !_swipeOn;
                  _tools = false;
                });
                _toastNow(_swipeOn
                    ? 'Swipe across any line to highlight it'
                    : 'Swipe highlight off');
              }, on: _swipeOn),
              tool(
                  Icons.alarm,
                  'Remind me',
                  () => setState(() {
                        _tools = false;
                        _remind = true;
                      })),
              tool(Icons.translate, 'Translate page',
                  () => _mark('translate', wholePage: true)),
              tool(Icons.search, 'Search the web',
                  () => _mark('search', wholePage: true)),
              tool(Icons.ios_share, 'Share', () async {
                await Clipboard.setData(
                    ClipboardData(text: _page?.plain ?? 'NowssB Reader'));
                _toastNow('Copied');
              }),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Highlights on this page',
              style: TextStyle(
                  color: Color(0x8CFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (pm.hl.isEmpty)
            const Text('Select any text on the page to highlight it.',
                style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12.5))
          else
            for (var i = 0; i < pm.hl.length; i++)
              _mkRow(pm.hl[i], () => _store.drop(_bookKey, _idx, 'hl', i)),
          const SizedBox(height: 16),
          const Text('Notes on this page',
              style: TextStyle(
                  color: Color(0x8CFFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (pm.notes.isEmpty)
            const Text('No notes yet.',
                style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12.5))
          else
            for (var i = 0; i < pm.notes.length; i++)
              _mkRow(
                pm.notes[i].t +
                    (pm.notes[i].on.isEmpty ? '' : '\non “${pm.notes[i].on}”'),
                () => _store.drop(_bookKey, _idx, 'notes', i),
              ),
        ],
      ),
    );
  }

  Widget _mkRow(String t, VoidCallback onDrop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(t,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4)),
          ),
          IconButton(
            onPressed: onDrop,
            icon: const Icon(Icons.close, color: Color(0x99FFFFFF), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _notepadSheet() {
    final rows = _store.bookEntries(_bookKey);
    final where = _isMeaning
        ? 'The Book of Meanings'
        : (_epub?.title ?? _book?.title ?? 'Library');
    return _sheet(
      title: 'Notepad',
      sub: where,
      onClose: () => setState(() {
        _notepad = false;
        _noteOn = '';
      }),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          if (_noteOn.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1FE8D5A3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('on “$_noteOn”',
                        style: const TextStyle(
                            color: NwsbColors.goldLight, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _noteOn = ''),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _noteIn,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Write a note…',
                    hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                    filled: true,
                    fillColor: Color(0x14FFFFFF),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final t = _noteIn.text.trim();
                  if (t.isEmpty) {
                    _toastNow('Write something first');
                    return;
                  }
                  await _store.addNote(_bookKey, _idx, t: t, on: _noteOn);
                  _noteIn.clear();
                  setState(() => _noteOn = '');
                  _toastNow('Note saved');
                  _haptic(28);
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _npChip(Icons.highlight_alt, 'Swipe Highlight', () {
                setState(() => _swipeOn = !_swipeOn);
                _toastNow(_swipeOn
                    ? 'Swipe across any line to highlight it'
                    : 'Swipe highlight off');
              }, on: _swipeOn),
              _npChip(Icons.copy, 'Copy all', () async {
                if (rows.isEmpty) {
                  _toastNow('Nothing to copy');
                  return;
                }
                final text =
                    '$where\n\n${rows.map((r) => 'p${r.page + 1}  ${r.t}${r.on.isEmpty ? '' : '\n     on “${r.on}”'}').join('\n\n')}';
                await Clipboard.setData(ClipboardData(text: text));
                _toastNow('Notepad copied');
              }),
              _npChip(Icons.ios_share, 'Share', () async {
                if (rows.isEmpty) {
                  _toastNow('Nothing to share');
                  return;
                }
                final text =
                    '$where\n\n${rows.map((r) => 'p${r.page + 1}  ${r.t}').join('\n\n')}';
                await Clipboard.setData(ClipboardData(text: text));
                _toastNow('Notepad copied');
              }),
              _npChip(Icons.delete_outline, 'Clear book', () async {
                await _store.clearBook(_bookKey);
                _toastNow('Notepad cleared');
              }),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Text(
              'Nothing yet. Turn on Swipe Highlight and tap a paragraph — it is painted on the page and lands here at the same time.',
              style: TextStyle(
                  color: Color(0x73FFFFFF), fontSize: 13, height: 1.5),
            )
          else
            for (final r in rows)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _jump(r.page),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x26E8D5A3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${r.page + 1}',
                            style: const TextStyle(
                                color: NwsbColors.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.t,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          if (r.on.isNotEmpty)
                            Text('on “${r.on}”',
                                style: const TextStyle(
                                    color: Color(0x80FFFFFF), fontSize: 11)),
                          if (r.auto)
                            const Text('swiped',
                                style: TextStyle(
                                    color: NwsbColors.goldLight, fontSize: 10)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openWeb('search', r.t),
                      icon: const Icon(Icons.search,
                          color: Color(0x99FFFFFF), size: 16),
                    ),
                    IconButton(
                      onPressed: () =>
                          _store.drop(_bookKey, r.page, r.kind, r.i),
                      icon: const Icon(Icons.close,
                          color: Color(0x99FFFFFF), size: 16),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _npChip(IconData ic, String label, VoidCallback onTap,
      {bool on = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0x26E8D5A3) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: on ? const Color(0x80E8D5A3) : const Color(0x1AFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _remindSheet(String title) {
    const rem = [
      (15, 'In 15 minutes'),
      (60, 'In an hour'),
      (180, 'In 3 hours'),
      (480, 'This evening'),
      (1440, 'Tomorrow'),
    ];
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _remind = false),
        child: ColoredBox(
          color: const Color(0xCC000000),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121218),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Remind me about “$title”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    for (final r in rem)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await _store.addReminder(
                              minutes: r.$1,
                              title: title,
                              which: _isMeaning ? 'meaning' : 'ebook',
                              key: _bookKey,
                              idx: _idx,
                            );
                            setState(() => _remind = false);
                            _toastNow('Reminder set');
                            _haptic(30);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(r.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15)),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () => setState(() => _remind = false),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webSheet() {
    return _sheet(
      title: _webMode == 'translate' ? 'Translate' : 'Look up',
      onClose: () => setState(() => _web = false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text(
              _webText.length > 220
                  ? '${_webText.substring(0, 220)}…'
                  : _webText,
              style: const TextStyle(
                  color: Color(0xB3FFFFFF), fontSize: 13, height: 1.45)),
          if (_webMode == 'translate') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in ReaderLookup.langs)
                  GestureDetector(
                    onTap: () {
                      _store.setLang(g.$1);
                      _openWeb('translate', _webText);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _store.lang == g.$1
                            ? const Color(0x26E8D5A3)
                            : const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _store.lang == g.$1
                              ? const Color(0x80E8D5A3)
                              : const Color(0x1AFFFFFF),
                        ),
                      ),
                      child: Text(g.$2,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_webWait)
            const Text('Looking it up…',
                style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13))
          else if (_webBody.isEmpty)
            Text(
              _webMode == 'translate'
                  ? 'Could not reach Google Translate from here — check the connection, or open it with the button below.'
                  : 'No summary came back for this phrase. Google has the full web results — the button below opens it.',
              style: const TextStyle(
                  color: Color(0x80FFFFFF), fontSize: 13, height: 1.5),
            )
          else ...[
            Text(_webBody,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.5)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _saveWeb,
              child: const Text('Save to notepad'),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              final u = _webMode == 'translate'
                  ? Uri.parse(
                      'https://translate.google.com/?sl=auto&tl=${_store.lang}&op=translate&text=${Uri.encodeComponent(_webText)}')
                  : Uri.parse(
                      'https://www.google.com/search?q=${Uri.encodeComponent(_webText)}');
              launchUrl(u, mode: LaunchMode.externalApplication);
            },
            child: Text(
              _webMode == 'translate'
                  ? 'Open Google Translate'
                  : 'Open full Google results',
              style: const TextStyle(color: NwsbColors.deep),
            ),
          ),
        ],
      ),
    );
  }
}
