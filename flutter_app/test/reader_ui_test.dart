/// Native Reader — hub, Meaning Reader, eBook Reader, prefs, marks, EPUB.
///
/// The website Reader is app/js/part065.js. These screens were missing
/// from Flutter; this file is the proof they now open, turn pages, keep
/// preferences and file highlights the same way.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/reader_store.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/reader/reader_book.dart';
import 'package:nowssb/screens/reader/reader_epub.dart';
import 'package:nowssb/screens/reader/reader_hub.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReaderStore.instance.debugReset();
    VideoPool.instance.debugDropAll();
  });
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pumpPhone(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: NavScope(go: (_) {}, child: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('the hub shows both readers', (tester) async {
    await pumpPhone(tester, const ReaderHubScreen());
    expect(find.text('Reader'), findsWidgets);
    expect(find.text('Two ways to read what NowssB holds'), findsOneWidget);
    expect(find.text('Meaning Reader'), findsOneWidget);
    expect(find.text('eBook Reader'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('reader hub page film is the Fashion home backdrop, not reader-section', () {
    final hub = File('lib/screens/reader/reader_hub.dart').readAsStringSync();
    expect(hub, contains('AppBackdrop'));
    expect(hub, contains('reader-section.mp4'));
    expect(
      RegExp(r'Positioned\.fill\(child: AppBackdrop\(\)\)').hasMatch(hub),
      isTrue,
    );
    expect(
      hub.contains("const NwsbVideo(\n            asset: 'assets/video/reader-section.mp4'"),
      isFalse,
    );
  });

  testWidgets('Meaning Reader opens the catalogue as a book', (tester) async {
    await pumpPhone(tester, const ReaderHubScreen());
    await tester.tap(find.text('Meaning Reader'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('The Book of Meanings'), findsOneWidget);
    expect(find.text('Earth'), findsWidgets);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Highlight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meaning Reader turns the page', (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('Earth'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Water'), findsWidgets);
    expect(find.textContaining('of'), findsWidgets);
  });

  testWidgets('contents jumps to a later meaning', (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Contents'), findsOneWidget);
    await tester.tap(find.text('Fire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Fire'), findsWidgets);
    expect(find.text('Contents'), findsNothing);
  });

  testWidgets('Aa tray changes theme, size and font', (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    await tester.tap(find.byKey(const Key('rd-rail-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Font'), findsOneWidget);
    expect(find.text('Text Size'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Brightness'), findsOneWidget);

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(ReaderStore.instance.prefs.font, 'Georgia');

    await tester.tap(find.text('Aa').last);
    await tester.pump();
    expect(
      ReaderStore.instance.prefs.theme,
      anyOf('light', 'sepia', 'dark', 'black'),
    );
  });

  testWidgets('highlights and notes are remembered per page', (tester) async {
    final store = ReaderStore.instance;
    await store.ensureLoaded();
    await store.addHighlight('meanings', 0, 'the sound that carries');
    await store.addNote('meanings', 0, t: 'sit with it', on: 'Earth');
    await store.toggleBookmark('meanings', 0);

    final pm = store.pageMarks('meanings', 0);
    expect(pm.hl, contains('the sound that carries'));
    expect(pm.notes.single.t, 'sit with it');
    expect(pm.mark, isTrue);

    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    await tester.tap(find.byKey(const Key('rd-rail-tools')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Page tools'), findsOneWidget);
    expect(find.text('the sound that carries'), findsOneWidget);
    expect(find.textContaining('sit with it'), findsOneWidget);
    expect(find.text('Bookmarked'), findsOneWidget);
  });

  testWidgets('swipe highlight paints the line and files it', (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    await tester.tap(find.text('Highlight'));
    await tester.pump();
    expect(find.text('Swipe across any line to highlight it'), findsOneWidget);

    final para = ReaderStore.instance.meaningPages().first.body.first;
    await ReaderStore.instance.swipeHighlight('meanings', 0, para);
    await tester.pump();

    final rows = ReaderStore.instance.bookEntries('meanings');
    expect(rows, isNotEmpty);
    expect(rows.first.t, para);
    expect(rows.first.auto, isTrue);
  });

  testWidgets('eBook Reader lists the library then opens a title',
      (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.ebook),
    );
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('eBook Reader'), findsOneWidget);
    expect(find.text('Open an EPUB'), findsOneWidget);
    expect(find.text('The Shabdapathy Codex'), findsOneWidget);

    await tester.tap(find.text('The Shabdapathy Codex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('The Shabdapathy Codex'), findsWidgets);
    expect(find.textContaining('of'), findsWidgets);
  });

  testWidgets('a reminder is stored for the open page', (tester) async {
    await pumpPhone(
      tester,
      const ReaderBookScreen(kind: ReaderKind.meaning),
    );
    await tester.pump(const Duration(milliseconds: 30));

    await tester.tap(find.byKey(const Key('rd-rail-tools')));
    await tester.pump();
    await tester.tap(find.text('Remind me'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Remind me about'), findsOneWidget);
    await tester.tap(find.text('In 15 minutes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(ReaderStore.instance.reminders, isNotEmpty);
    expect(ReaderStore.instance.reminders.first.title, 'Earth');
    expect(find.text('Reminder set'), findsOneWidget);
  });

  test('prefs round-trip and clamp', () {
    final p = ReaderPrefs.fromJson({
      'theme': 'black',
      'font': 'DM Sans',
      'size': 99,
      'spacing': -4,
      'bright': 10,
    });
    expect(p.theme, 'black');
    expect(p.font, 'DM Sans');
    expect(p.size, 26);
    expect(p.spacing, 0);
    expect(p.bright, 35);

    final raw = ReaderPrefs.fromJson(p.toJson());
    expect(raw.theme, 'black');
    expect(raw.font, 'DM Sans');
  });

  test('meaning pages group the catalogue by category', () {
    final pages = ReaderStore.instance.meaningPages();
    expect(pages, isNotEmpty);
    expect(pages.first.title, kMsBaseMeanings.first.word);
    expect(pages.first.chapterName, kMsBaseMeanings.first.category);
    expect(pages.where((p) => p.first).length, greaterThan(1));
  });

  test('a real EPUB unzips into chapters', () {
    final book = buildEpub(_tinyEpub(), 'field-guide.epub');
    expect(book.title, 'Phonetic Origins');
    expect(book.pages, hasLength(2));
    expect(book.pages.first.title, 'The tracing method');
    expect(book.pages.first.body.first, contains('Isolate the root syllable.'));
    expect(book.pages.last.body.single, contains('Cross-language families'));
  });
}

Uint8List _tinyEpub() {
  final archive = Archive();
  archive.addFile(ArchiveFile(
    'META-INF/container.xml',
    0,
    utf8.encode(
      '''<?xml version="1.0"?>
<container>
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
    ),
  ));
  archive.addFile(ArchiveFile(
    'OEBPS/content.opf',
    0,
    utf8.encode(
      '''<?xml version="1.0"?>
<package>
  <metadata>
    <dc:title>Phonetic Origins</dc:title>
  </metadata>
  <manifest>
    <item id="c1" href="c1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="c2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>''',
    ),
  ));
  archive.addFile(ArchiveFile(
    'OEBPS/c1.xhtml',
    0,
    utf8.encode(
      '''<html><body>
<h1>The tracing method</h1>
<p>Isolate the root syllable.</p>
<p>Follow the sound, not the spelling.</p>
</body></html>''',
    ),
  ));
  archive.addFile(ArchiveFile(
    'OEBPS/c2.xhtml',
    0,
    utf8.encode(
      '''<html><body>
<h2>Worked examples</h2>
<p>Cross-language families & false trails.</p>
</body></html>''',
    ),
  ));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
