/// NowssB Connect — the daily word board.
///
/// Today's word sits at the top as a big poster word with its meaning.
/// Below it, people share a short thought on how the word felt (up to 280
/// characters), an optional feeling chip and an optional image. Posts are
/// anonymous: no profiles, follows, usernames or chats. Others tap one
/// gentle "felt this". Each day has its own board; earlier days are
/// read-only. Everything comes from the server (/api/economy/board*).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/content.dart';
import '../../data/day_part.dart';
import '../../data/home_widget_sync.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../widgets/concept/normal/surface.dart';
import '../economy/economy_api.dart';

/// Max characters in one thought (the server enforces the same).
const kBoardMaxText = 280;

/// Max bytes for an uploaded image after compression (about 1 MB).
const kBoardMaxImageBytes = 1024 * 1024;

/// Feeling chips, in the order shown.
const kBoardFeelings = ['calm', 'light', 'heavy', 'open', 'warm', 'tender', 'clear', 'restless'];

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

const _guideKey = 'nwsb_connect_board_guide_v1';

/// One anonymous thought on a day's board.
class BoardPost {
  const BoardPost({required this.id, required this.text, this.feeling = '', this.image = '', this.felt = 0, this.feltByMe = false, this.mine = false, this.at = 0});
  final String id, text, feeling, image;
  final int felt, at;
  final bool feltByMe, mine;

  factory BoardPost.from(Map m) => BoardPost(
        id: '${m['id'] ?? ''}',
        text: '${m['text'] ?? ''}',
        feeling: '${m['feeling'] ?? ''}',
        image: '${m['image'] ?? ''}',
        felt: (m['felt'] as num?)?.toInt() ?? 0,
        feltByMe: m['feltByMe'] == true,
        mine: m['mine'] == true,
        at: (m['at'] as num?)?.toInt() ?? 0,
      );

  BoardPost withFelt(int n, bool on) => BoardPost(id: id, text: text, feeling: feeling, image: image, felt: n, feltByMe: on, mine: mine, at: at);
}

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

class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  final _text = TextEditingController();
  final _focus = FocusNode();

  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  String? _error;
  String _day = '';
  String _today = '';
  bool _readOnly = false;
  String _serverWord = '';
  String _serverMeaning = '';
  List<BoardPost> _posts = const [];
  List<String> _days = const [];
  int _left = 3;
  String _feeling = '';
  String? _image;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guideOnce());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || NormalLoop.debugT != null;
    if (still) {
      _breath.stop();
      _breath.value = NormalLoop.debugT ?? .35;
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── today's word (the same word of the day the home uses) ──
  ({String word, String meaning}) get _todayWord {
    final w = HomeWidgetSync.wordFor(DayClock.now(), ContentStore.instance.library);
    return (word: w?.word ?? '', meaning: w?.meaning ?? '');
  }

  ({String word, String meaning}) get _shownWord {
    if (!_readOnly) {
      final t = _todayWord;
      if (t.word.isNotEmpty) return t;
    }
    return (word: _serverWord, meaning: _serverMeaning);
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
        _serverWord = '${r['word'] ?? ''}';
        _serverMeaning = '${r['meaning'] ?? ''}';
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

  // ── instructions: shown once, reopened from '?' ──
  Future<void> _guideOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_guideKey) == true || !mounted) return;
    await prefs.setBool(_guideKey, true);
    if (mounted) await _guide();
  }

  Future<void> _guide() => showDialog<void>(
        context: context,
        barrierColor: const Color(0x66000000),
        builder: (c) => const _GuideDialog(),
      );

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

  Future<void> _share() async {
    final text = _text.text.trim();
    if (_sending || _readOnly || _left <= 0) return;
    if (text.length < 2 && _image == null) {
      _snack('Share a thought first.');
      return;
    }
    setState(() => _sending = true);
    final w = _todayWord;
    try {
      final r = await EconomyApi.call('boardPost', {'text': text, 'feeling': _feeling, 'image': _image ?? '', 'word': w.word, 'meaning': w.meaning});
      final p = r['post'];
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        if (p is Map) _posts = [BoardPost.from(p), ..._posts];
        _left = (r['postsLeft'] as num?)?.toInt() ?? math.max(0, _left - 1);
        _text.clear();
        _feeling = '';
        _image = null;
      });
      _focus.unfocus();
    } on EconomyException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack("That didn't send. Try again.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _felt(BoardPost p) async {
    if (_readOnly || p.mine) return;
    final on = !p.feltByMe;
    HapticFeedback.selectionClick();
    _replace(p.withFelt(math.max(0, p.felt + (on ? 1 : -1)), on));
    try {
      final r = await EconomyApi.call('boardFelt', {'day': _day, 'postId': p.id, 'on': on});
      _replace(p.withFelt((r['felt'] as num?)?.toInt() ?? p.felt, r['feltByMe'] == true));
    } catch (e) {
      _replace(p);
      _snack(e is EconomyException ? e.message : "That didn't go through. Try again.");
    }
  }

  void _replace(BoardPost p) {
    if (!mounted) return;
    setState(() => _posts = [for (final x in _posts) x.id == p.id ? p : x]);
  }

  Future<void> _moderate(BoardPost p, {required bool report}) async {
    setState(() => _posts = [for (final x in _posts) if (x.id != p.id) x]);
    try {
      await EconomyApi.call('boardReport', {'day': _day, 'postId': p.id, if (!report) 'hideOnly': true, if (report) 'reason': 'reported from board'});
      _snack(report ? 'Thanks. We hid it and our team will look.' : 'Hidden. You won’t see it again.');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: nBase,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: nInk,
          onRefresh: () => _load(_day.isEmpty || _day == _today ? null : _day),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _header(canPop)),
              SliverToBoxAdapter(child: _dayStrip()),
              SliverToBoxAdapter(child: _poster()),
              if (!_readOnly) SliverToBoxAdapter(child: _composer()),
              if (_readOnly)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text('This board has closed. You can read it, but not post or react.', style: nSub),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(_readOnly ? 'What people felt' : 'How today’s word felt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: nInk)),
                ),
              ),
              ..._feed(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool canPop) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(
          children: [
            if (canPop) _RoundBtn(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).maybePop()) else const SizedBox(width: 8),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NowssB Connect', style: nTitle),
                  SizedBox(height: 2),
                  Text('One word a day. Share how it felt.', style: nSub),
                ],
              ),
            ),
            _RoundBtn(icon: Icons.question_mark_rounded, label: 'How Connect works', onTap: _guide),
          ],
        ),
      );

  String _label(String d) {
    if (d.length != 8) return d;
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mo = int.tryParse(d.substring(4, 6)) ?? 1;
    return '${m[(mo - 1).clamp(0, 11)]} ${int.tryParse(d.substring(6)) ?? ''}';
  }

  Widget _dayStrip() {
    if (_days.isEmpty) return const SizedBox(height: 8);
    final all = [_today, ..._days];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = all[i];
          final on = d == _day;
          return _Pill(
            label: i == 0 ? 'Today' : _label(d),
            selected: on,
            onTap: () => _load(i == 0 ? null : d),
          );
        },
      ),
    );
  }

  Widget _poster() {
    final w = _shownWord;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, child) {
          final t = _breath.value;
          final glow = .5 + .5 * math.sin(t * 2 * math.pi);
          return Container(
            decoration: neu(r: 30),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // A slow ring of light that breathes behind the word.
                Positioned(
                  right: -60 + 10 * glow,
                  top: -70 + 8 * glow,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [nGold.withValues(alpha: .20 + .12 * glow), nGold.withValues(alpha: 0)]),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_readOnly ? 'THE WORD ON ${_label(_day).toUpperCase()}' : 'TODAY’S WORD',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: nSubInk)),
              const SizedBox(height: 10),
              if (w.word.isEmpty && _loading)
                const SizedBox(height: 64)
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text((w.word.isEmpty ? 'NowssB' : w.word).toUpperCase(), maxLines: 1, style: nPoster.copyWith(fontSize: 64)),
                ),
              if (w.meaning.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(w.meaning, style: const TextStyle(fontSize: 15, height: 1.4, color: nInk, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final n = _text.text.characters.length;
    final over = n > kBoardMaxText;
    final canSend = !_sending && !_uploading && _left > 0 && !over && (n >= 2 || _image != null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: neu(r: 26),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: neu(r: 18, pressed: true),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _text,
                focusNode: _focus,
                enabled: _left > 0,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(kBoardMaxText)],
                style: const TextStyle(fontSize: 15, color: nInk, height: 1.4),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _left > 0 ? 'How did today’s word feel?' : 'That’s 3 thoughts for today. Come back tomorrow.',
                  hintStyle: const TextStyle(color: nSubInk, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kBoardFeelings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = kBoardFeelings[i];
                  return _Pill(label: f, small: true, selected: _feeling == f, onTap: () => setState(() => _feeling = _feeling == f ? '' : f));
                },
              ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  _BoardImage(path: _image!, height: 140),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Semantics(
                      button: true,
                      label: 'Remove image',
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xCCFFFFFF), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 18, color: nInk),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _RoundBtn(
                  icon: _uploading ? Icons.hourglass_top_rounded : Icons.add_photo_alternate_outlined,
                  label: 'Add an image',
                  size: 44,
                  onTap: _left > 0 ? _pickImage : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$n/$kBoardMaxText · ${_left > 0 ? '$_left of 3 left today' : 'no thoughts left today'}',
                    style: TextStyle(fontSize: 12.5, color: over ? const Color(0xFFB3261E) : nSubInk),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Share',
                  child: GestureDetector(
                    onTap: canSend ? _share : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(color: canSend ? nInk : const Color(0xFFB9BDC8), borderRadius: BorderRadius.circular(999)),
                      child: Text(_sending ? 'Sharing…' : 'Share', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _feed() {
    if (_loading && _posts.isEmpty) {
      return const [SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: nInk, strokeWidth: 2))))];
    }
    if (_error != null) {
      return [SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: Text(_error!, style: nSub)))];
    }
    if (_posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(_readOnly ? 'No one shared a thought that day.' : 'No thoughts yet today. Be the first to share how it felt.', style: nSub.copyWith(fontSize: 14)),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: _posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final p = _posts[i];
            return _Rise(
              key: ValueKey(p.id),
              delay: Duration(milliseconds: 40 * math.min(i, 6)),
              child: _PostCard(
                post: p,
                readOnly: _readOnly,
                onFelt: () => _felt(p),
                onHide: () => _moderate(p, report: false),
                onReport: () => _moderate(p, report: true),
              ),
            );
          },
        ),
      ),
    ];
  }
}

String _ago(int at) {
  if (at <= 0) return '';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at));
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.readOnly, required this.onFelt, required this.onHide, required this.onReport});
  final BoardPost post;
  final bool readOnly;
  final VoidCallback onFelt, onHide, onReport;

  @override
  Widget build(BuildContext context) {
    final p = post;
    return Container(
      decoration: neu(r: 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (p.feeling.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: neu(r: 999, pressed: true),
                  child: Text('feels ${p.feeling}', style: const TextStyle(fontSize: 12.5, color: nInk, fontWeight: FontWeight.w700)),
                ),
              if (p.feeling.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: Text(p.mine ? 'You · ${_ago(p.at)}' : 'A healer · ${_ago(p.at)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: nSubInk)),
              ),
              if (!p.mine)
                PopupMenuButton<String>(
                  tooltip: 'Hide or report',
                  icon: const Icon(Icons.more_horiz_rounded, color: nSubInk),
                  color: nBase,
                  onSelected: (v) => v == 'report' ? onReport() : onHide(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'hide', child: Text('Hide this')),
                    PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
                )
              else
                const SizedBox(height: 40),
            ],
          ),
          if (p.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 2),
              child: Text(p.text, style: const TextStyle(fontSize: 15.5, height: 1.45, color: nInk)),
            ),
          if (p.image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 10),
              child: _BoardImage(path: p.image, height: 190),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _FeltButton(count: p.felt, on: p.feltByMe, enabled: !readOnly && !p.mine, onTap: onFelt),
          ),
        ],
      ),
    );
  }
}

class _FeltButton extends StatelessWidget {
  const _FeltButton({required this.count, required this.on, required this.enabled, required this.onTap});
  final int count;
  final bool on, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 felt this' : '$count felt this';
    return Semantics(
      button: enabled,
      toggled: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: on ? neu(r: 999, pressed: true) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: on ? 1.15 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(on ? Icons.spa_rounded : Icons.spa_outlined, size: 20, color: on ? nGold : nSubInk),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: on ? nInk : nSubInk)),
            ],
          ),
        ),
      ),
    );
  }
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
    Widget child;
    if (fake != null) {
      child = fake(widget.path);
    } else {
      child = FutureBuilder<String>(
        future: _url,
        builder: (_, s) => s.hasData
            ? Image.network(s.data!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE3E6EE)))
            : const ColoredBox(color: Color(0xFFE3E6EE)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(height: widget.height, width: double.infinity, child: child),
    );
  }
}

/// A soft fade + rise as a thought appears.
class _Rise extends StatelessWidget {
  const _Rise({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || NormalLoop.debugT != null;
    if (still) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420) + delay,
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: c)),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap, this.small = false});
  final String label;
  final bool selected, small;
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
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 16, vertical: small ? 9 : 10),
            decoration: selected ? BoxDecoration(color: nInk, borderRadius: BorderRadius.circular(999)) : neu(r: 999),
            child: Text(label, style: TextStyle(fontSize: small ? 13 : 13.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : nInk)),
          ),
        ),
      );
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.label, required this.onTap, this.size = 46});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
            decoration: neu(r: 999),
            child: Icon(icon, color: onTap == null ? const Color(0xFFB9BDC8) : nInk, size: 22),
          ),
        ),
      );
}

class _GuideDialog extends StatefulWidget {
  const _GuideDialog();
  @override
  State<_GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<_GuideDialog> {
  static const _steps = [
    ('One word a day', 'Everyone sees the same word of the day at the top. Sit with it for a moment.'),
    ('Share how it felt', 'Write a short thought, up to 280 characters. Add a feeling or an image if you like. Up to 3 a day.'),
    ('Gentle and anonymous', 'No profiles, follows or chats. Tap “felt this” when a thought lands. Hide or report anything that doesn’t belong.'),
  ];
  var _i = 0;

  @override
  Widget build(BuildContext context) {
    final (title, body) = _steps[_i];
    final last = _i == _steps.length - 1;
    return Dialog(
      backgroundColor: nBase,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step ${_i + 1} of ${_steps.length}', style: const TextStyle(fontSize: 12.5, color: nSubInk, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: nInk)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.45, color: nInk)),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip', style: TextStyle(color: nSubInk))),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: nInk, foregroundColor: Colors.white),
                  onPressed: () => last ? Navigator.pop(context) : setState(() => _i++),
                  child: Text(last ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

