/// NowssB Connect — the website flow, in Flutter.
///
/// Setup (intro, profile, welcome), then Home, Reels, Connect, Profile,
/// and real one-to-one messages. Same pictures, same words, same steps.
/// People, posts, follows and chats are real and come from the server.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/practice_progress.dart';
import '../economy/economy_api.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';

const _gold = Color(0xFFE8D5A3);
const _ink = Color(0xFF060C18);
const _hero = 'https://media.nowssb.com/migrated-images/c6bfdcb8601beaba_grok_image_1784255334796_jew1ou.jpg';
const _logo = 'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png';
const _welcomeLogo = 'https://media.nowssb.com/migrated-images/8ed93fdc651b43c3_file_00000000b84c7209ab496862cacd6a7f_kagsie.png';
const _themeNeu = 'https://media.nowssb.com/migrated-images/f7ab49ce96814d9d_file_00000000a718720aaba9aef2f7b1e757_sdk2a8.png';
const _themeGlass = 'https://media.nowssb.com/migrated-images/4ab7671cefecf91e_file_00000000cf8c720a89a1fb6f44fe8c55_xwdwnz.png';
const _statsHero = 'https://media.nowssb.com/migrated-images/f7e0b23df165dd82_grok_image_1784171046763_kfygmv.jpg';
const _navHome = 'https://media.nowssb.com/migrated-images/4815ce65fb831cbf_569b91f0-578c-11f1-b67f-cfd32a085e10_pm6xc7.png';
const _navReels = 'https://media.nowssb.com/migrated-images/1b075adfd52b4af8_10d7afe0-5bf2-11f1-8248-b91d5cd919c2_b0bff9.png';
const _navConnect = 'https://media.nowssb.com/migrated-images/a0b5196292b572ab_04d5f4e0-5bf2-11f1-8248-b91d5cd919c2_mcohzv.png';
const _chatIco = 'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png';
const _focus = ['Sound Healer', 'Daily Practitioner', 'Wellness', 'Beginner', 'Practitioner', 'Frequency Sage'];
const _banners = [
  'https://media.nowssb.com/migrated-images/fc3d4da65185cd05_grok_image_1782591933705_qq3l9g.jpg',
  'https://media.nowssb.com/migrated-images/b0311b51f4665417_grok_image_1782591857840_tbznap.jpg',
  'https://media.nowssb.com/migrated-images/e5c7f3703725755d_grok_image_1782592051446_womamz.jpg',
  'https://media.nowssb.com/migrated-images/df58ad45365e63d0_grok_image_1782591669371_kqnaf9.jpg',
  'https://media.nowssb.com/migrated-images/89c64c87db948180_grok_image_1782591627828_lmde11.jpg',
  'https://media.nowssb.com/migrated-images/517802ba6a6c3a6c_grok_image_1782591559591_yxgud5.jpg',
  'https://media.nowssb.com/migrated-images/671fd0928171078a_grok_image_1782591561380_ytpn3b.jpg',
  'https://media.nowssb.com/migrated-images/58d0a40a97d4a693_grok_image_1782591732123_epmpiu.jpg',
];
const _explain = [
  ('Origin', 'https://media.nowssb.com/migrated-images/8a4d334229f9ff55_grok_image_1782620063491_op58of.jpg'),
  ('Evolution', 'https://media.nowssb.com/migrated-images/b0d670b6066b0c49_image_qg7ro5.jpg'),
  ('Frequency', 'https://media.nowssb.com/migrated-images/d143c72a353c7f2e_image_dtmprf.jpg'),
  ('Healing', 'https://media.nowssb.com/migrated-images/c061be5a902cf11b_grok_image_1782620475749_fgncxl.jpg'),
];

/// A real NowssB Connect member (from connectProfiles on the server).
class _Person {
  const _Person(this.id, this.username, this.name, this.avatar, this.category, [this.bio = '']);
  final String id;
  final String username;
  final String name;
  final String avatar;
  final String category;
  final String bio;

  factory _Person.from(Map m) => _Person('${m['uid'] ?? ''}', '${m['username'] ?? ''}', '${m['name'] ?? 'NowssB member'}', '${m['avatar'] ?? ''}', '${m['focus'] ?? ''}', '${m['bio'] ?? ''}');
}

/// A real post from the shared, moderated Echo feed.
class _Post {
  const _Post(this.id, this.authorId, this.image, this.caption, {this.authorName = '', this.authorAvatar = '', this.authorFocus = '', this.likes = 0});
  final String id;
  final String authorId;
  final String image;
  final String caption;
  final String authorName;
  final String authorAvatar;
  final String authorFocus;
  final int likes;

  factory _Post.from(Map m) => _Post('${m['id']}', '${m['authorUid'] ?? ''}', '${m['image'] ?? ''}', '${m['text'] ?? ''}',
      authorName: '${m['authorName'] ?? ''}', authorAvatar: '${m['authorAvatar'] ?? ''}', authorFocus: '${m['authorFocus'] ?? ''}', likes: (m['likes'] as num?)?.toInt() ?? 0);
}

/// Everything here comes from the NowssB server (/api/economy/connect*).
/// Nothing is invented: no sample people, posts, replies or counts.
class _ConnectData extends ChangeNotifier {
  bool ready = false;
  bool done = false;
  String? error;
  String uid = '';
  String name = '';
  String focus = _focus.first;
  String bio = '';
  String theme = 'neu';
  String banner = _banners.first;
  String avatar = '';
  int followers = 0;
  var people = <_Person>[];
  var posts = <_Post>[];
  final follows = <String>{};
  final liked = <String>{};
  final saved = <String>{}; // bookmarks are private, kept on this phone
  var inbox = <Map<String, dynamic>>[];
  final chats = <String, List<Map<String, dynamic>>>{};

  _Person? person(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    for (final c in inbox) {
      final w = c['with'];
      if (w is Map && w['uid'] == id) return _Person.from(w);
    }
    return null;
  }

  List<_Post> get myPosts => [for (final p in posts) if (p.authorId == uid && uid.isNotEmpty) p];

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      saved
        ..clear()
        ..addAll(p.getStringList('nwsb_connect_saved') ?? const []);
      await refresh();
      error = null;
    } on Object catch (e) {
      error = e is EconomyException ? e.message : 'Couldn’t reach NowssB Connect. Check your connection.';
    }
    ready = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    final h = await EconomyApi.call('connectHome');
    final me = h['me'];
    done = me is Map;
    if (me is Map) {
      uid = '${me['uid'] ?? ''}';
      name = '${me['name'] ?? ''}';
      focus = _focus.contains(me['focus']) ? '${me['focus']}' : _focus.first;
      bio = '${me['bio'] ?? ''}';
      theme = me['theme'] == 'glass' ? 'glass' : 'neu';
      final b = '${me['banner'] ?? ''}';
      banner = b.isEmpty ? _banners.first : b;
      avatar = '${me['avatar'] ?? ''}';
    }
    people = [for (final m in (h['people'] as List? ?? const [])) if (m is Map) _Person.from(m)];
    posts = [for (final m in (h['posts'] as List? ?? const [])) if (m is Map) _Post.from(m)];
    liked
      ..clear()
      ..addAll([for (final m in (h['posts'] as List? ?? const [])) if (m is Map && m['liked'] == true) '${m['id']}']);
    follows
      ..clear()
      ..addAll([for (final f in (h['following'] as List? ?? const [])) '$f']);
    followers = (h['followerCount'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  Future<void> _saveRemote() async {
    await EconomyApi.call('connectSaveProfile', {'name': name, 'focus': focus, 'bio': bio, 'theme': theme, 'banner': banner});
  }

  Future<void> finish(String name, String focus, String bio, String theme, String banner) async {
    this.name = name;
    this.focus = focus;
    this.bio = bio;
    this.theme = theme;
    this.banner = banner;
    await _saveRemote();
    await refresh();
  }

  Future<void> saveProfile(String name, String focus, String bio) async {
    this.name = name;
    this.focus = focus;
    this.bio = bio;
    notifyListeners();
    await _saveRemote();
  }

  Future<void> setTheme(String theme) async {
    this.theme = theme;
    notifyListeners();
    await _saveRemote();
  }

  Future<void> setBanner(String banner) async {
    this.banner = banner;
    notifyListeners();
    await _saveRemote();
  }

  Future<void> toggleFollow(String id) async {
    final on = !follows.contains(id);
    on ? follows.add(id) : follows.remove(id);
    notifyListeners();
    try {
      await EconomyApi.call('connectFollow', {'targetUid': id, 'follow': on});
    } on Object {
      on ? follows.remove(id) : follows.add(id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLike(String id) async {
    final r = await EconomyApi.call('connectLike', {'postId': id});
    r['liked'] == true ? liked.add(id) : liked.remove(id);
    final likes = (r['likes'] as num?)?.toInt();
    if (likes != null) {
      posts = [
        for (final p in posts)
          p.id == id ? _Post(p.id, p.authorId, p.image, p.caption, authorName: p.authorName, authorAvatar: p.authorAvatar, authorFocus: p.authorFocus, likes: likes) : p,
      ];
    }
    notifyListeners();
  }

  Future<void> toggleSave(String id) async {
    if (!saved.add(id)) saved.remove(id);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('nwsb_connect_saved', saved.toList());
  }

  Future<void> post(String text) async {
    await EconomyApi.call('connectPost', {'text': text});
    await refresh();
  }

  Future<void> loadInbox() async {
    final r = await EconomyApi.call('connectInbox');
    inbox = [for (final c in (r['chats'] as List? ?? const [])) if (c is Map) Map<String, dynamic>.from(c)];
    notifyListeners();
  }

  List<Map<String, dynamic>> linesFor(String id) => chats[id] ?? const [];

  Future<void> loadThread(String id) async {
    final r = await EconomyApi.call('connectThread', {'withUid': id});
    chats[id] = [for (final m in (r['messages'] as List? ?? const [])) if (m is Map) Map<String, dynamic>.from(m)];
    notifyListeners();
  }

  /// Sends a real message. The other person's replies only ever come from them.
  Future<void> send(String id, String text) async {
    final r = await EconomyApi.call('connectSend', {'toUid': id, 'text': text});
    final m = r['message'];
    if (m is Map) chats[id] = [...linesFor(id), Map<String, dynamic>.from(m)];
    notifyListeners();
  }
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _data = _ConnectData();

  @override
  void initState() {
    super.initState();
    _data.load();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _data,
      builder: (context, _) {
        if (!_data.ready) {
          return const Scaffold(backgroundColor: _ink, body: Center(child: CircularProgressIndicator(color: _gold)));
        }
        if (_data.error != null) return _offline(_data);
        if (!_data.done) return _Setup(data: _data);
        return _Shell(data: _data);
      },
    );
  }
}

class _Setup extends StatefulWidget {
  const _Setup({required this.data});
  final _ConnectData data;

  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  var _step = 0;
  final _name = TextEditingController();
  final _bio = TextEditingController();
  var _focusPick = _focus.first;
  var _theme = 'neu';
  var _banner = _banners.first;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NwsbVideo(asset: 'assets/video/subscription-bg.mp4', fit: BoxFit.cover, autoplay: true, loop: true, priority: ClipPriority.decoration),
          const DecoratedBox(decoration: BoxDecoration(color: Color(0xCC060C18))),
          if (_step == 0) _intro(),
          if (_step == 1) _profile(),
          if (_step == 2) _welcome(),
        ],
      ),
    );
  }

  Widget _intro() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 320,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_hero, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF120818))),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00060C18), Color(0xEE060C18)],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_logo, width: 22, height: 22, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22))),
                      const SizedBox(width: 8),
                      const Text('NOWSSB CONNECT · NEW', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Your circle for the healing journey.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.28)),
                    const SizedBox(height: 18),
                    const _Feature(Icons.show_chart, 'Share your practice, your streaks, your progress'),
                    const _Feature(Icons.person_outline, 'Follow sound healers and word-science practitioners'),
                    const _Feature(Icons.chat_bubble_outline, 'Message, call and connect — real people, real frequency'),
                    const SizedBox(height: 8),
                    const Text('By continuing, you agree this space follows our Community Guidelines and Privacy Policy.', style: TextStyle(color: Color(0x59FFFFFF), fontSize: 11, height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _cta('Get Started', () => setState(() => _step = 1)),
      ],
    );
  }

  Widget _profile() {
    return Column(
      children: [
        _top('Set up your profile', () => setState(() => _step = 0)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: Text(_name.text.isEmpty ? 'N' : _name.text[0].toUpperCase(), style: const TextStyle(color: _gold, fontSize: 28, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 18),
              const _Label('DISPLAY NAME'),
              TextField(controller: _name, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white), decoration: _field('Your name')),
              const SizedBox(height: 16),
              const _Label('YOUR FOCUS'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in _focus) _chip(f, _focusPick == f, () => setState(() => _focusPick = f)),
                ],
              ),
              const SizedBox(height: 16),
              const _Label('BIO  (optional)'),
              TextField(controller: _bio, maxLines: 3, maxLength: 150, style: const TextStyle(color: Colors.white), decoration: _field('Tell people about your practice...')),
              const SizedBox(height: 8),
              const _Label('PROFILE BANNER  (optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBanner,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(_banner, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A2E))),
                        const DecoratedBox(decoration: BoxDecoration(color: Color(0x44000000))),
                        const Center(child: Text('Tap to choose a banner · 1200×400', style: TextStyle(color: _gold, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _Label('CHOOSE YOUR LOOK'),
              const SizedBox(height: 8),
              Row(children: [
                _look('neu', 'NowssB', _themeNeu),
                const SizedBox(width: 12),
                _look('glass', 'NowssB Fashion', _themeGlass),
              ]),
            ],
          ),
        ),
        _cta('Continue', () {
          if (_name.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a display name.')));
            return;
          }
          setState(() => _step = 2);
        }),
      ],
    );
  }

  Future<void> _pickBanner() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF0F2F7),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Banner', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            SizedBox(
              height: 280,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  for (final url in _banners)
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFD8D8DE))),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _banner = picked);
  }

  Widget _look(String id, String label, String url) {
    final on = _theme == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _theme = id),
        child: Column(
          children: [
            Container(
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? _gold : const Color(0x33FFFFFF), width: on ? 2 : 1),
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: on ? _gold : Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _welcome() {
    final name = _name.text.trim();
    return Column(
      children: [
        const SizedBox(height: 36),
        const Text('Set-up Page', style: TextStyle(color: _gold, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const Text('One last step, and enjoy the connect', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.network(_welcomeLogo, width: 36, height: 36, errorBuilder: (_, __, ___) => const SizedBox(width: 36)),
          const SizedBox(width: 10),
          const Text('NowssB Connect', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 22),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
          child: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: _ink, size: 30),
          ),
        ),
        const SizedBox(height: 14),
        const Text("You're all set!", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final e in _explain)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 140,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(e.$2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1028))),
                          Positioned(left: 8, bottom: 6, child: Text(e.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        const Text('Welcome to NowssB Connect', style: TextStyle(color: Color(0x99FFFFFF))),
        Text(name.isEmpty ? 'there' : name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x33FFFFFF))),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ctaButton('Enter NowssB Connect', () async {
                  try {
                    await widget.data.finish(name, _focusPick, _bio.text.trim(), _theme, _banner);
                  } on Object catch (e) {
                    if (mounted) _toast(context, e);
                  }
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({required this.data});
  final _ConnectData data;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final glass = widget.data.theme == 'glass';
    final pages = [
      _Home(data: widget.data),
      _Reels(data: widget.data),
      _Community(data: widget.data),
      _Profile(data: widget.data),
    ];
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NwsbVideo(asset: 'assets/video/subscription-bg.mp4', fit: BoxFit.cover, autoplay: true, loop: true, priority: ClipPriority.decoration),
          DecoratedBox(decoration: BoxDecoration(color: glass ? const Color(0x99060C18) : const Color(0xE6060C18))),
          pages[_tab],
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  Widget _nav() {
    return Material(
      color: const Color(0xF7060C18),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _back(),
              Container(width: 1, height: 28, color: const Color(0x22E8D5A3)),
              _navBtn(0, _navHome, 'Home', false),
              _navBtn(1, _navReels, 'Reels', false),
              _navBtn(2, _navConnect, 'Connect', false),
              _navBtn(3, '', 'Profile', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _back() {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      child: const SizedBox(
        width: 52,
        child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _navBtn(int i, String icon, String label, bool avatar) {
    final on = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (avatar)
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFDFE3EC),
                backgroundImage: widget.data.banner.isEmpty ? null : null,
                child: Text(widget.data.name.isEmpty ? 'N' : widget.data.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 11, fontWeight: FontWeight.w800)),
              )
            else
              Image.network(icon, width: 22, height: 22, color: on ? _gold : Colors.white, colorBlendMode: BlendMode.srcIn, errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 16, color: on ? _gold : Colors.white)),
            const SizedBox(height: 3),
            Text(label.toUpperCase(), style: TextStyle(color: on ? _gold : const Color(0x8CFFFFFF), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.data});
  final _ConnectData data;

  @override
  Widget build(BuildContext context) {
    final p = PracticeProgress.instance;
    final words = p.uniqueWords;
    final sessions = p.totalSessions;
    return ListView(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            const SizedBox(width: 8),
            const Expanded(child: Text('NowssB Connect', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
            IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Inbox(data: data))),
              icon: Image.network(_chatIco, width: 26, height: 26, errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble_outline, color: _gold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x24E8D5A3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 196,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(_statsHero, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF120818))),
                        const Positioned(
                          right: 12,
                          bottom: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0x8C060C18), borderRadius: BorderRadius.all(Radius.circular(20)), border: Border.fromBorderSide(BorderSide(color: Color(0x4DE8D5A3)))),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              child: Text('HEALING IS FASHION', style: TextStyle(color: _gold, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Stats,\nYour Frequency.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 4),
                        Text('NowssB · Word Science · ${data.name.isEmpty ? 'there' : data.name}', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
                        const SizedBox(height: 14),
                        Container(height: 1, color: const Color(0x12FFFFFF)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _stat('$words', 'Words'),
                          _stat('$sessions', 'Sessions'),
                          _stat('—', 'Score'),
                          _stat('${p.streak}', 'Streak'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const _Hd('Reels · Pronunciation'),
        SizedBox(
          height: 148,
          child: p.sessionsSnapshot.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Be the first — practice a word and post a reel.', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12))),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    for (final s in p.sessionsSnapshot.take(8))
                      Container(
                        width: 96,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF10141C), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x22E8D5A3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.graphic_eq, color: _gold, size: 18),
                            const Spacer(),
                            Text('${s['word'] ?? 'Word'}', maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const _Hd('The New Fashion Trend'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: [
              for (final e in _explain) _shot(e.$2, e.$1),
            ],
          ),
        ),
        const _Hd('Suggested · Community'),
        if (data.people.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No one else has joined Connect yet. Invite a friend who practices.', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
          ),
        for (final person in data.people.take(5)) _personRow(context, data, person),
      ],
    );
  }
}

class _Reels extends StatelessWidget {
  const _Reels({required this.data});
  final _ConnectData data;

  @override
  Widget build(BuildContext context) {
    final sessions = PracticeProgress.instance.sessionsSnapshot;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 24),
      children: [
        const Text('Reels', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Pronunciation you practiced.', style: TextStyle(color: Color(0x88FFFFFF))),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text('No reels yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 8),
                Text('Practice a word and tap Post as Reel after scoring to share your pronunciation.', textAlign: TextAlign.center, style: TextStyle(color: Color(0x88FFFFFF))),
              ],
            ),
          )
        else
          for (final s in sessions.take(12))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xF0101014), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x22FFFFFF))),
              child: Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFF1A1A2E), child: Icon(Icons.graphic_eq, color: _gold, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s['word'] ?? 'Word'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(data.name.isEmpty ? 'You' : data.name, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 12)),
                ])),
                const Text('Reel', style: TextStyle(color: _gold, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
      ],
    );
  }
}

class _Community extends StatefulWidget {
  const _Community({required this.data});
  final _ConnectData data;

  @override
  State<_Community> createState() => _CommunityState();
}

class _CommunityState extends State<_Community> {
  var _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final people = [
      for (final p in widget.data.people)
        if (q.isEmpty || p.name.toLowerCase().contains(q) || p.username.contains(q) || p.category.toLowerCase().contains(q)) p,
    ];
    final posts = [
      for (final post in widget.data.posts)
        if (q.isEmpty || post.caption.toLowerCase().contains(q)) post,
    ];
    return RefreshIndicator(
      color: _gold,
      onRefresh: () => widget.data.refresh(),
      child: ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 24),
      children: [
        const Text.rich(TextSpan(children: [
          TextSpan(text: 'NowssB ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          TextSpan(text: 'Connect', style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _q = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
            prefixIcon: const Icon(Icons.search, color: Color(0x88FFFFFF)),
            filled: true,
            fillColor: const Color(0xFF141820),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        if (people.isEmpty && posts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: Text(q.isEmpty ? 'No people or posts yet. Be the first to post.' : 'Nothing matches your search.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        for (final person in people) _personRow(context, widget.data, person),
        if (posts.isNotEmpty) const _Hd('Explore'),
        for (final post in posts) _postCard(context, widget.data, post),
      ],
    ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.data});
  final _ConnectData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: 24),
      children: [
        SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(data.banner, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1028))),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xCC060C18)]))),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1A1A2E),
                  backgroundImage: data.avatar.isEmpty ? null : NetworkImage(data.avatar),
                  child: data.avatar.isNotEmpty ? null : Text(data.name.isEmpty ? 'N' : data.name[0].toUpperCase(), style: const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(data.name.isEmpty ? 'there' : data.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text(data.focus, style: const TextStyle(color: _gold)),
                if (data.bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(data.bio, style: const TextStyle(color: Color(0xCCFFFFFF))),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  _count('${data.myPosts.length}', 'Posts'),
                  _count('${data.follows.length}', 'Following'),
                  _count('${data.followers}', 'Followers'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _mini('Edit profile', () => _edit(context))),
                  const SizedBox(width: 8),
                  Expanded(child: _mini('Share', () {
                    Clipboard.setData(ClipboardData(text: 'Practice with me on NowssB Connect. ${data.name}'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile link copied.')));
                  })),
                  const SizedBox(width: 8),
                  Expanded(child: _mini('Messages', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Inbox(data: data))))),
                ]),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('POSTS', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            if (data.myPosts.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('You haven’t posted yet.', style: TextStyle(color: Color(0x88FFFFFF)))),
            for (final post in data.myPosts) _postCard(context, data, post),
          ]),
        ),
        const SizedBox(height: 8),
        _row(Icons.edit_note, 'New post', 'Share with the NowssB community', () => _compose(context)),
        _row(Icons.bookmark_border, 'Saved', "Posts you've bookmarked", () => _list(context, 'Saved', data.saved)),
        _row(Icons.favorite_border, 'Liked', "Posts you've liked", () => _list(context, 'Liked', data.liked)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Connect Theme', style: TextStyle(color: Color(0x88FFFFFF), fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _themePick(context, 'neu', 'NowssB', _themeNeu),
            const SizedBox(width: 12),
            _themePick(context, 'glass', 'NowssB Fashion', _themeGlass),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Neumorphism or frosted glass — applies to the Connect feed, reels, discover and profile.', style: TextStyle(color: Color(0x77FFFFFF), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _count(String n, String l) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(l, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 11)),
        ]),
      );

  Widget _mini(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF1A1E28), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  Widget _themePick(BuildContext context, String id, String label, String url) {
    final on = data.theme == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => data.setTheme(id),
        child: Column(children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? _gold : const Color(0x33FFFFFF), width: on ? 2 : 1),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: on ? _gold : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  void _list(BuildContext context, String title, Set<String> ids) {
    final posts = [for (final post in data.posts) if (ids.contains(post.id)) post];
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => Scaffold(
          backgroundColor: _ink,
          appBar: AppBar(backgroundColor: _ink, foregroundColor: Colors.white, title: Text(title)),
          body: posts.isEmpty
              ? Center(child: Text(title == 'Saved' ? "Posts you've bookmarked will show here." : "Posts you've liked will show here.", textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF))))
              : ListView(padding: const EdgeInsets.all(16), children: [for (final post in posts) _postCard(context, data, post)]),
        )));
  }

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _gold),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Color(0x55FFFFFF)),
      onTap: onTap,
    );
  }

  Future<void> _compose(BuildContext context) async {
    final text = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(key: const Key('connect-post-text'), controller: text, maxLines: 4, maxLength: 500, style: const TextStyle(color: Colors.white), decoration: _field('What did you practice today?')),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _ink),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
    final body = text.text.trim();
    text.dispose();
    if (ok == true && body.isNotEmpty && context.mounted) {
      await _guard(context, () => data.post(body));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: data.name);
    final bio = TextEditingController(text: data.bio);
    var focus = data.focus;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatefulBuilder(
          builder: (ctx, set) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: _field('Display name')),
              const SizedBox(height: 8),
              TextField(controller: bio, style: const TextStyle(color: Colors.white), decoration: _field('Bio')),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in _focus) _chip(f, focus == f, () => set(() => focus = f)),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _ink),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      try {
        await data.saveProfile(name.text.trim().isEmpty ? data.name : name.text.trim(), focus, bio.text.trim());
      } on Object catch (e) {
        if (context.mounted) _toast(context, e);
      }
    }
    name.dispose();
    bio.dispose();
  }
}

class _Peer extends StatelessWidget {
  const _Peer({required this.data, required this.person});
  final _ConnectData data;
  final _Person person;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final on = data.follows.contains(person.id);
        final theirPosts = [for (final p in data.posts) if (p.authorId == person.id) p];
        return Scaffold(
          backgroundColor: _ink,
          appBar: AppBar(backgroundColor: _ink, foregroundColor: Colors.white, title: Text(person.username)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: _avatar(person.avatar, person.name, 44)),
              const SizedBox(height: 12),
              Center(child: Text(person.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              Center(child: Text(person.category, style: const TextStyle(color: _gold))),
              if (person.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(child: Text(person.bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xCCFFFFFF)))),
              ],
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _ctaButton(on ? 'Following' : 'Follow', () => _guard(context, () => data.toggleFollow(person.id)))),
                const SizedBox(width: 10),
                Expanded(child: _ctaButton('Message', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Thread(data: data, person: person))))),
              ]),
              const SizedBox(height: 16),
              for (final post in theirPosts) _postCard(context, data, post),
            ],
          ),
        );
      },
    );
  }
}

class _Inbox extends StatefulWidget {
  const _Inbox({required this.data});
  final _ConnectData data;

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.data.loadInbox();
      _error = null;
    } on Object catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: const Color(0xF5060C18),
        foregroundColor: Colors.white,
        title: const Text('Messages'),
        actions: [
          TextButton(
            onPressed: () => _newChat(context),
            child: const Text('+ New', style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
          if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF)))));
          if (data.inbox.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No messages yet.\nTap + New or open someone’s profile to say hello.', textAlign: TextAlign.center, style: TextStyle(color: Color(0x99FFFFFF))),
              ),
            );
          }
          return RefreshIndicator(
            color: _gold,
            onRefresh: _load,
            child: ListView(
              children: [
                for (final c in data.inbox)
                  if (c['with'] is Map) _chatRow(context, data, c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chatRow(BuildContext context, _ConnectData data, Map<String, dynamic> c) {
    final person = _Person.from(c['with'] as Map);
    final preview = '${c['lastMine'] == true ? 'You: ' : ''}${c['lastText'] ?? ''}';
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Thread(data: data, person: person)));
        _load();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Row(children: [
          _avatar(person.avatar, person.name, 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(person.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _newChat(BuildContext context) {
    final people = widget.data.people;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10141C),
      builder: (ctx) => people.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Text('No one else has joined Connect yet.', style: TextStyle(color: Color(0x99FFFFFF))))
          : ListView(children: [
              for (final p in people)
                ListTile(
                  leading: _avatar(p.avatar, p.name, 18),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(p.category, style: const TextStyle(color: _gold, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Thread(data: widget.data, person: p)));
                  },
                ),
            ]),
    );
  }
}

class _Thread extends StatefulWidget {
  const _Thread({required this.data, required this.person});
  final _ConnectData data;
  final _Person person;

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final _text = TextEditingController();
  var _stickers = false;
  var _loading = true;
  var _sending = false;
  Timer? _poll;
  static const _stickersList = ['🙏', '🎧', '✨', '🔥', '💫', '🤍'];

  @override
  void initState() {
    super.initState();
    _load();
    // New replies arrive by polling every 10 s while this chat is open.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      await widget.data.loadThread(widget.person.id);
    } on Object catch (e) {
      if (!quiet && mounted) _toast(context, e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _text.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _stickers = false;
      _sending = true;
    });
    try {
      await widget.data.send(widget.person.id, text);
      if (preset == null) _text.clear();
    } on Object catch (e) {
      if (mounted) _toast(context, e);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.data, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final lines = widget.data.linesFor(widget.person.id);
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          Material(
            color: const Color(0xF5060C18),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                    const Expanded(child: Text('NowssB Connect', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 48),
                  ]),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Peer(data: widget.data, person: widget.person))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(children: [
                        _avatar(widget.person.avatar, widget.person.name, 18),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.person.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(widget.person.category, style: const TextStyle(color: _gold, fontSize: 12)),
                        ])),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : lines.isEmpty
                    ? Center(child: Text('Say hello to ${widget.person.name}.', style: const TextStyle(color: Color(0x88FFFFFF))))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final e in lines) _bubble(e),
                        ],
                      ),
          ),
          if (_stickers)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in _stickersList)
                    GestureDetector(
                      onTap: () => _sendText(s),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(s, style: const TextStyle(fontSize: 28))),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 8 + MediaQuery.paddingOf(context).bottom),
            child: Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('connect-message'),
                  controller: _text,
                  style: const TextStyle(color: Colors.white),
                  decoration: _field('Message…'),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              IconButton(onPressed: () => setState(() => _stickers = !_stickers), icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xCCFFFFFF))),
              IconButton(key: const Key('connect-send'), onPressed: _sending ? null : () => _sendText(), icon: const Icon(Icons.send, color: _gold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> e) {
    final mine = e['mine'] == true;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? _gold : const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('${e['text']}', style: TextStyle(color: mine ? _ink : Colors.white)),
      ),
    );
  }
}

String _msg(Object e) => e is EconomyException ? e.message : 'Something went wrong. Try again.';

void _toast(BuildContext context, Object e) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(_msg(e))));
}

Future<void> _guard(BuildContext context, Future<void> Function() run) async {
  try {
    await run();
  } on Object catch (e) {
    if (context.mounted) _toast(context, e);
  }
}

Widget _avatar(String url, String name, double r) {
  final letter = CircleAvatar(
    radius: r,
    backgroundColor: const Color(0xFF1A1A2E),
    child: Text(name.isEmpty ? 'N' : name[0].toUpperCase(), style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: r * 0.8)),
  );
  if (url.isEmpty) return letter;
  return ClipOval(child: Image.network(url, width: r * 2, height: r * 2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => letter));
}

Widget _offline(_ConnectData data) {
  return Scaffold(
    backgroundColor: _ink,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(data.error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          _ctaButton('Try again', () {
            data.ready = false;
            data.load();
          }),
        ]),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x1FE8D5A3), border: Border.all(color: const Color(0x4DE8D5A3))),
          child: Icon(icon, color: _gold, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(text, style: const TextStyle(color: Color(0xD1FFFFFF), fontSize: 14, height: 1.4)))),
      ]),
    );
  }
}

class _Hd extends StatelessWidget {
  const _Hd(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(text.toUpperCase(), style: const TextStyle(color: Color(0x47FFFFFF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: _gold, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
    );
  }
}

Widget _chip(String label, bool on, VoidCallback tap) {
  return GestureDetector(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: on ? _gold : const Color(0x22111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? _gold : const Color(0x33FFFFFF)),
      ),
      child: Text(label, style: TextStyle(color: on ? _ink : Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    ),
  );
}

Widget _shot(String url, String label) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1028))),
        Positioned(left: 10, bottom: 8, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

Widget _personRow(BuildContext context, _ConnectData data, _Person person) {
  final on = data.follows.contains(person.id);
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Peer(data: data, person: person))),
        child: _avatar(person.avatar, person.name, 22),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Peer(data: data, person: person))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            Text(person.category, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 12)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: () => _guard(context, () => data.toggleFollow(person.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: on ? const Color(0xFF1A1E28) : _gold, borderRadius: BorderRadius.circular(16)),
          child: Text(on ? 'Following' : 'Follow', style: TextStyle(color: on ? Colors.white : _ink, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ),
    ]),
  );
}

Widget _postCard(BuildContext context, _ConnectData data, _Post post) {
  final author = data.person(post.authorId);
  final mine = post.authorId == data.uid;
  final liked = data.liked.contains(post.id);
  final saved = data.saved.contains(post.id);
  final name = mine ? (data.name.isEmpty ? 'You' : data.name) : (post.authorName.isEmpty ? 'NowssB member' : post.authorName);
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: const Color(0xF0101014), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x18FFFFFF))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          type: MaterialType.transparency,
          child: ListTile(
          leading: _avatar(mine ? data.avatar : post.authorAvatar, name, 18),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: Text(mine ? data.focus : post.authorFocus, style: const TextStyle(color: _gold, fontSize: 12)),
          onTap: author == null || mine ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Peer(data: data, person: author))),
          ),
        ),
        if (post.image.isNotEmpty)
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.network(post.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1028))),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(post.caption, style: const TextStyle(color: Colors.white)),
        ),
        Row(children: [
          IconButton(onPressed: () => _guard(context, () => data.toggleLike(post.id)), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? const Color(0xFFE06A8A) : Colors.white)),
          if (post.likes > 0) Text('${post.likes}', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
          IconButton(onPressed: () => data.toggleSave(post.id), icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? _gold : Colors.white)),
          const Spacer(),
          if (author != null && !mine)
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _Thread(data: data, person: author))),
              child: const Text('Message', style: TextStyle(color: _gold)),
            ),
        ]),
      ],
    ),
  );
}

Widget _stat(String n, String l) => Expanded(
      child: Column(
        children: [
          Text(n, style: const TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l.toUpperCase(), style: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );

Widget _top(String title, VoidCallback back) {
  return SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(children: [
        GestureDetector(
          onTap: back,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x29FFFFFF))),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
          ),
        ),
        Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
        const SizedBox(width: 34),
      ]),
    ),
  );
}

Widget _cta(String label, VoidCallback onTap) {
  return SafeArea(
    top: false,
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: _ctaButton(label, onTap)),
  );
}

Widget _ctaButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)]),
      ),
      child: Text(label, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 15)),
    ),
  );
}

InputDecoration _field(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
      filled: true,
      fillColor: const Color(0xFF12161E),
      counterStyle: const TextStyle(color: Color(0x66FFFFFF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x22FFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x22FFFFFF))),
    );
