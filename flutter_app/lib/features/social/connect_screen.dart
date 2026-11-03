/// NowssB Connect — a quiet dashboard, not a social network.
///
/// At the top, a composer with three kinds of post: a Thought (a few lines),
/// a Quote (words plus who said them) or an Image (with an optional caption).
/// Below, today's board: thoughts, quotes and images from everyone, newest
/// first, filterable by kind. Posts are anonymous: no profiles, follows,
/// counts, stories or chats. Others' posts can be hidden or reported; your
/// own can be deleted. Earlier days are read-only.
///
/// Everything comes from the server (/api/economy/board*); images go to
/// Firebase Storage at connect/{uid}/{ms}.jpg, as before.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/glass_list_card.dart';
import '../economy/economy_api.dart';

/// Max characters in one post (the server enforces the same).
const kBoardMaxText = 280;

/// Max characters for who said a quote.
const kBoardMaxBy = 40;

/// Max bytes for an uploaded image after compression (about 1 MB).
const kBoardMaxImageBytes = 1024 * 1024;

/// Posts each person can share a day (the server enforces the same).
const kBoardPerDay = 3;

const _bg = Color(0xFF07070A);
const _white = Colors.white;
const _danger = Color(0xFFF87171);

/// Re-encodes any picked image as a JPEG no larger than
/// [kBoardMaxImageBytes]: at most 1280 px on the long side, stepping the
/// quality down and then the size until it fits. Null if it can't.
Uint8List? compressBoardImage(Uint8List raw) {
  img.Image? src;
  try {
    src = img.decodeImage(raw);
  } catch (_) {
    return null;
  }
  if (src == null) return null;
  var im = img.bakeOrientation(src);
  for (final side in const [1280, 1024, 800, 640]) {
    if (math.max(im.width, im.height) > side) {
      im = im.width >= im.height ? img.copyResize(im, width: side) : img.copyResize(im, height: side);
    }
    for (final q in const [82, 72, 60, 48]) {
      final out = img.encodeJpg(im, quality: q);
      if (out.lengthInBytes <= kBoardMaxImageBytes) return out;
    }
  }
  return null;
}

enum PostKind { thought, quote, image }

extension PostKindLabel on PostKind {
  String get label => switch (this) { PostKind.thought => 'Thought', PostKind.quote => 'Quote', PostKind.image => 'Image' };
  IconData get icon => switch (this) {
        PostKind.thought => Icons.chat_bubble_outline_rounded,
        PostKind.quote => Icons.format_quote_rounded,
        PostKind.image => Icons.image_outlined,
      };
}

/// A quote is stored as its text: “words” — who said it.
String encodeQuote(String words, String by) {
  final w = words.trim().replaceAll('“', '"').replaceAll('”', '"');
  final b = by.trim();
  return b.isEmpty ? '“$w”' : '“$w” — $b';
}

final _quoteRe = RegExp(r'^“([\s\S]+)”(?:\s—\s(.+))?$');

/// One anonymous post on a day's board.
class BoardPost {
  const BoardPost({required this.id, required this.text, this.image = '', this.mine = false, this.at = 0});
  final String id, text, image;
  final int at;
  final bool mine;

  factory BoardPost.from(Map m) => BoardPost(
        id: '${m['id'] ?? ''}',
        text: '${m['text'] ?? ''}',
        image: '${m['image'] ?? ''}',
        mine: m['mine'] == true,
        at: (m['at'] as num?)?.toInt() ?? 0,
      );

  RegExpMatch? get _q => image.isEmpty ? _quoteRe.firstMatch(text.trim()) : null;

  PostKind get kind => image.isNotEmpty ? PostKind.image : (_q != null ? PostKind.quote : PostKind.thought);

  /// For a quote: the words without the marks. Otherwise the text.
  String get body => _q?.group(1)?.trim() ?? text;

  /// For a quote: who said it ('' if not given).
  String get by => _q?.group(2)?.trim() ?? '';
}

/// "just now", "12 min ago", "3 h ago", "Yesterday", "Nov 2".
String boardAgo(int at, {DateTime? now}) {
  if (at <= 0) return '';
  final n = now ?? DateTime.now();
  final t = DateTime.fromMillisecondsSinceEpoch(at);
  final d = n.difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24 && t.day == n.day) return '${d.inHours} h ago';
  final y = DateTime(n.year, n.month, n.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (y == 1) return 'Yesterday';
  return '${_months[t.month - 1]} ${t.day}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  /// Tests: turn a stored image path into something drawable (no network).
  @visibleForTesting
  static Widget Function(String path)? debugImage;

  /// Tests: replace picking + compressing + uploading an image. Returns the
  /// stored path (connect/{uid}/{ms}.jpg) or null.
  @visibleForTesting
  static Future<String?> Function()? debugPickImage;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _text = TextEditingController();
  final _by = TextEditingController();
  final _focus = FocusNode();

  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  String? _error;
  String _day = '';
  String _today = '';
  bool _readOnly = false;
  List<BoardPost> _posts = const [];
  List<String> _days = const [];
  int _left = kBoardPerDay;
  PostKind _kind = PostKind.thought;
  PostKind? _filter;
  String? _image;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _by.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _by.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load([String? day]) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await EconomyApi.call('boardDay', {if (day != null) 'day': day});
      if (!mounted) return;
      setState(() {
        _day = '${r['day'] ?? ''}';
        _today = '${r['today'] ?? _day}';
        _readOnly = r['readOnly'] == true;
        _posts = [for (final p in (r['posts'] as List? ?? const [])) if (p is Map) BoardPost.from(p)];
        _days = [for (final d in (r['days'] as List? ?? const [])) '$d'];
        _left = (r['postsLeft'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is EconomyException ? e.message : "Can't reach NowssB right now. Pull down to try again.";
      });
    }
  }

  void _snack(String msg) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> _signedIn() async {
    if (EconomyMirror.instance.uid != null) return true;
    final ok = await NwsbSignInPage.open(context);
    return ok && EconomyMirror.instance.uid != null;
  }

  // ── image: pick, compress to about 1 MB, upload ──
  Future<void> _pickImage() async {
    if (_uploading) return;
    final fake = ConnectScreen.debugPickImage;
    if (fake != null) {
      final p = await fake();
      if (p != null && mounted) setState(() => _image = p);
      return;
    }
    if (!await _signedIn() || !mounted) return;
    final uid = EconomyMirror.instance.uid!;
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048, imageQuality: 90);
    if (x == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final raw = await x.readAsBytes();
      final bytes = await compute(compressBoardImage, raw);
      if (bytes == null) {
        _snack('That image is too large or unreadable. Try another one.');
        return;
      }
      final path = 'connect/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await FirebaseStorage.instance.ref(path).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      if (mounted) setState(() => _image = path);
    } catch (_) {
      _snack('That image did not upload. Try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String get _outgoing {
    final t = _text.text.trim();
    return _kind == PostKind.quote && t.isNotEmpty ? encodeQuote(t, _by.text) : t;
  }

  bool get _canPost {
    if (_sending || _uploading || _readOnly || _left <= 0) return false;
    final n = _outgoing.characters.length;
    if (n > kBoardMaxText) return false;
    return switch (_kind) {
      PostKind.image => _image != null,
      _ => _text.text.trim().length >= 2,
    };
  }

  Future<void> _post() async {
    if (!_canPost) return;
    setState(() => _sending = true);
    try {
      final r = await EconomyApi.call('boardPost', {'text': _outgoing, 'image': _kind == PostKind.image ? (_image ?? '') : ''});
      final p = r['post'];
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        if (p is Map) _posts = [BoardPost.from(p), ..._posts];
        _left = (r['postsLeft'] as num?)?.toInt() ?? math.max(0, _left - 1);
        _text.clear();
        _by.clear();
        _image = null;
      });
      _focus.unfocus();
    } on EconomyException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack("That didn't post. Try again.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _drop(BoardPost p) => setState(() => _posts = [for (final x in _posts) if (x.id != p.id) x]);

  Future<void> _hideOrReport(BoardPost p, {required bool report}) async {
    final before = _posts;
    _drop(p);
    try {
      await EconomyApi.call('boardReport', {'day': _day, 'postId': p.id, if (!report) 'hideOnly': true, if (report) 'reason': 'reported from board'});
      _snack(report ? 'Thanks. It’s hidden and our team will look.' : 'Hidden. You won’t see it again.');
    } catch (e) {
      if (mounted) setState(() => _posts = before);
      _snack(e is EconomyException ? e.message : "That didn't go through. Try again.");
    }
  }

  Future<void> _delete(BoardPost p) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF15151C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0x26FFFFFF))),
        title: const Text('Delete this post?', style: TextStyle(color: _white, fontWeight: FontWeight.w800)),
        content: const Text('It will be removed from the board for everyone.', style: TextStyle(color: kGlassMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: kGlassMuted))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: _danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final before = _posts;
    _drop(p);
    try {
      await EconomyApi.call('boardDelete', {'day': _day, 'postId': p.id});
      _snack('Deleted.');
    } catch (e) {
      if (mounted) setState(() => _posts = before);
      _snack(e is EconomyException ? e.message : "That didn't delete. Try again.");
    }
  }

  String _label(String d) {
    if (d.length != 8) return d;
    final mo = int.tryParse(d.substring(4, 6)) ?? 1;
    return '${_months[(mo - 1).clamp(0, 11)]} ${int.tryParse(d.substring(6)) ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: _bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(-.8, -1.1), radius: 1.4, colors: [Color(0xFF1C1A24), _bg]),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: _white,
            backgroundColor: const Color(0xFF15151C),
            onRefresh: () => _load(_day.isEmpty || _day == _today ? null : _day),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _header(canPop)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(children: [
                    if (!_readOnly) _composer(),
                    _board(),
                  ]),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool canPop) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
        child: Row(children: [
          if (canPop)
            _CircleBtn(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).maybePop())
          else
            const SizedBox(width: 4),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NowssB Connect', style: TextStyle(color: _white, fontSize: 24, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text('Share a thought, a quote or an image.', style: TextStyle(color: kGlassMuted, fontSize: 13)),
            ]),
          ),
        ]),
      );

  // ── composer ──
  Widget _composer() {
    final n = _outgoing.characters.length;
    final over = n > kBoardMaxText;
    final out = _left <= 0;
    return GlassListCard(
      icon: Icons.edit_outlined,
      overline: 'Share · anonymous',
      title: 'Post to the board',
      subtitle: out ? 'That’s $kBoardPerDay posts for today. Come back tomorrow.' : '$_left of $kBoardPerDay left today',
      children: out
          ? const []
          : [
              Row(children: [
                for (final k in PostKind.values) ...[
                  if (k != PostKind.thought) const SizedBox(width: 8),
                  Expanded(child: _KindTab(kind: k, selected: _kind == k, onTap: () => setState(() => _kind = k))),
                ],
              ]),
              if (_kind == PostKind.image) _imageSlot(),
              _Field(
                controller: _text,
                focus: _focus,
                hint: switch (_kind) {
                  PostKind.thought => 'What’s on your mind?',
                  PostKind.quote => 'The words, as you remember them',
                  PostKind.image => 'Add a caption (optional)',
                },
                minLines: _kind == PostKind.image ? 1 : 3,
              ),
              if (_kind == PostKind.quote) _Field(controller: _by, hint: 'Who said it (optional)', minLines: 1, maxLength: kBoardMaxBy),
              Row(children: [
                Expanded(
                  child: Text('$n / $kBoardMaxText',
                      style: TextStyle(fontSize: 12.5, color: over ? _danger : kGlassMuted, fontFeatures: const [ui.FontFeature.tabularFigures()])),
                ),
                _PostBtn(busy: _sending, enabled: _canPost, onTap: _post),
              ]),
            ],
    );
  }

  Widget _imageSlot() {
    if (_image != null) {
      return Stack(children: [
        _BoardImage(path: _image!, height: 170),
        Positioned(
          right: 8,
          top: 8,
          child: _CircleBtn(icon: Icons.close_rounded, label: 'Remove image', size: 36, onTap: () => setState(() => _image = null)),
        ),
      ]);
    }
    return GlassTile(
      icon: _uploading ? Icons.hourglass_top_rounded : Icons.add_photo_alternate_outlined,
      title: _uploading ? 'Uploading…' : 'Choose an image',
      sub: 'From your gallery. We shrink it to about 1 MB.',
      onTap: _uploading ? null : _pickImage,
    );
  }

  // ── the board ──
  Widget _board() {
    final shown = [for (final p in _posts) if (_filter == null || p.kind == _filter) p];
    final isToday = _day.isEmpty || _day == _today;
    final count = _posts.length;
    return GlassListCard(
      icon: Icons.dashboard_outlined,
      overline: isToday ? 'Today’s board' : 'Board · ${_label(_day)}',
      title: _readOnly ? 'What people shared' : 'From everyone',
      subtitle: _loading
          ? null
          : _readOnly
              ? 'This day has closed. You can read it, but not post.'
              : count == 0
                  ? 'Nothing here yet'
                  : count == 1
                      ? '1 post today'
                      : '$count posts today',
      children: [
        if (_days.isNotEmpty) _dayStrip(),
        _filters(),
        ..._items(shown),
      ],
    );
  }

  Widget _dayStrip() {
    final all = [_today, ..._days];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = all[i];
          return _Chip(label: i == 0 ? 'Today' : _label(d), selected: d == _day, onTap: () => _load(i == 0 ? null : d));
        },
      ),
    );
  }

  Widget _filters() => SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _Chip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
          for (final k in PostKind.values) ...[
            const SizedBox(width: 8),
            _Chip(label: '${k.label}s', icon: k.icon, selected: _filter == k, onTap: () => setState(() => _filter = k)),
          ],
        ]),
      );

  List<Widget> _items(List<BoardPost> shown) {
    if (_loading && _posts.isEmpty) {
      return const [
        Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: _white, strokeWidth: 2))),
      ];
    }
    if (_error != null) return [_Note(icon: Icons.cloud_off_rounded, text: _error!)];
    if (shown.isEmpty) {
      final what = _filter == null ? 'posts' : '${_filter!.label.toLowerCase()}s';
      return [
        _Note(
          icon: Icons.spa_outlined,
          text: _readOnly
              ? 'No $what that day.'
              : _posts.isEmpty
                  ? 'No posts yet today. Share the first thought, quote or image.'
                  : 'No $what yet today.',
        ),
      ];
    }
    return [
      for (final p in shown)
        _PostTile(
          key: ValueKey(p.id),
          post: p,
          onHide: () => _hideOrReport(p, report: false),
          onReport: () => _hideOrReport(p, report: true),
          onDelete: () => _delete(p),
        ),
    ];
  }
}

// ───────────────────────── pieces ─────────────────────────

/// Delete needs the boardDelete server action (functions/_lib/economy/connect.js),
/// which is written but not deployed yet. Until then your own posts show no
/// menu instead of a Delete that fails.
const kBoardDeleteLive = false;

class _PostTile extends StatelessWidget {
  const _PostTile({super.key, required this.post, required this.onHide, required this.onReport, required this.onDelete});
  final BoardPost post;
  final VoidCallback onHide, onReport, onDelete;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final k = p.kind;
    final when = boardAgo(p.at);
    final meta = [k.label, p.mine ? 'You' : 'Anonymous', if (when.isNotEmpty) when].join(' · ');
    return Container(
      decoration: BoxDecoration(color: kGlassTile, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), shape: BoxShape.circle, border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Icon(k.icon, size: 15, color: _white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kGlassMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .2)),
          ),
          if (!p.mine || kBoardDeleteLive) PopupMenuButton<String>(
            tooltip: p.mine ? 'Delete' : 'Hide or report',
            icon: const Icon(Icons.more_horiz_rounded, color: kGlassMuted),
            color: const Color(0xFF15151C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x26FFFFFF))),
            onSelected: (v) => switch (v) { 'delete' => onDelete(), 'report' => onReport(), _ => onHide() },
            itemBuilder: (_) => p.mine
                ? const [PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: _danger)))]
                : const [
                    PopupMenuItem(value: 'hide', child: Text('Hide this', style: TextStyle(color: _white))),
                    PopupMenuItem(value: 'report', child: Text('Report', style: TextStyle(color: _danger))),
                  ],
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 6),
          child: switch (k) {
            PostKind.quote => _quote(p),
            PostKind.image => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _BoardImage(path: p.image, height: 210),
                if (p.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(p.text, style: const TextStyle(color: _white, fontSize: 14.5, height: 1.45)),
                ],
              ]),
            PostKind.thought => Text(p.text, style: const TextStyle(color: _white, fontSize: 15.5, height: 1.5)),
          },
        ),
      ]),
    );
  }

  Widget _quote(BoardPost p) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 2),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x40FFFFFF), width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('“${p.body}”', style: const TextStyle(color: _white, fontSize: 18, height: 1.45, fontWeight: FontWeight.w600)),
          if (p.by.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('— ${p.by}', style: const TextStyle(color: kGlassMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
}

class _KindTab extends StatelessWidget {
  const _KindTab({required this.kind, required this.selected, required this.onTap});
  final PostKind kind;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: kind.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              color: selected ? _white : kGlassTile,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _white : const Color(0x1FFFFFFF)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(kind.icon, size: 17, color: selected ? const Color(0xFF0B0B10) : _white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(kind.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF0B0B10) : _white)),
              ),
            ]),
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.focus, this.minLines = 1, this.maxLength = kBoardMaxText});
  final TextEditingController controller;
  final FocusNode? focus;
  final String hint;
  final int minLines, maxLength;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: kGlassTile, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: TextField(
          controller: controller,
          focusNode: focus,
          minLines: minLines,
          maxLines: math.max(minLines, 5),
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          cursorColor: _white,
          style: const TextStyle(fontSize: 15, color: _white, height: 1.4),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 15),
          ),
        ),
      );
}

class _PostBtn extends StatelessWidget {
  const _PostBtn({required this.busy, required this.enabled, required this.onTap});
  final bool busy, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: enabled,
        label: 'Post',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(color: enabled ? _white : const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(999)),
            child: Text(busy ? 'Posting…' : 'Post',
                style: TextStyle(color: enabled ? const Color(0xFF0B0B10) : const Color(0x80FFFFFF), fontWeight: FontWeight.w800, fontSize: 14.5)),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0x33FFFFFF) : kGlassTile,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? const Color(0x66FFFFFF) : const Color(0x1AFFFFFF)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 14, color: selected ? _white : kGlassMuted), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? _white : kGlassMuted)),
            ]),
          ),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: kGlassTile, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        child: Column(children: [
          Icon(icon, color: kGlassMuted, size: 26),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kGlassMuted, fontSize: 14, height: 1.45)),
        ]),
      );
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.label, required this.onTap, this.size = 44});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0B0B10), size: size * .48),
          ),
        ),
      );
}

class _BoardImage extends StatefulWidget {
  const _BoardImage({required this.path, required this.height});
  final String path;
  final double height;
  @override
  State<_BoardImage> createState() => _BoardImageState();
}

class _BoardImageState extends State<_BoardImage> {
  Future<String>? _url;

  @override
  void initState() {
    super.initState();
    if (ConnectScreen.debugImage == null) _url = FirebaseStorage.instance.ref(widget.path).getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final fake = ConnectScreen.debugImage;
    const blank = ColoredBox(color: Color(0xFF15151C));
    final child = fake != null
        ? fake(widget.path)
        : FutureBuilder<String>(
            future: _url,
            builder: (_, s) => s.hasData ? Image.network(s.data!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => blank) : blank,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(height: widget.height, width: double.infinity, child: child),
    );
  }
}
