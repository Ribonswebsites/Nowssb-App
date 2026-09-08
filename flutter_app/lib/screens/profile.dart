import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/content.dart';
import '../data/practice_progress.dart';
import '../shell/nav_shell.dart';
import 'sound_library.dart';
import 'player_settings.dart';
import 'practice.dart';
import 'progress/progress_screen.dart';
import 'quick_access.dart';
import 'store.dart';

const _accent = Color(0xFFE3BD7D);
const _text = Color(0xFFF5F5F3);
const _dim = Color(0xFF8C8C8C);
const _faint = Color(0xFF565656);
const _border = Color(0x24FFFFFF);
const _borderSoft = Color(0x14FFFFFF);
const _surface = Color(0x0BFFFFFF);
const _mono = 'Roboto Mono';

/// Same prebuilt banner library as `nowssb-nm.js` `NWSB_BANNERS`.
const kNwsbBanners = <String>[
  'https://media.nowssb.com/migrated-images/fc3d4da65185cd05_grok_image_1782591933705_qq3l9g.jpg',
  'https://media.nowssb.com/migrated-images/b0311b51f4665417_grok_image_1782591857840_tbznap.jpg',
  'https://media.nowssb.com/migrated-images/e5c7f3703725755d_grok_image_1782592051446_womamz.jpg',
  'https://media.nowssb.com/migrated-images/df58ad45365e63d0_grok_image_1782591669371_kqnaf9.jpg',
  'https://media.nowssb.com/migrated-images/89c64c87db948180_grok_image_1782591627828_lmde11.jpg',
  'https://media.nowssb.com/migrated-images/517802ba6a6c3a6c_grok_image_1782591559591_yxgud5.jpg',
  'https://media.nowssb.com/migrated-images/671fd0928171078a_grok_image_1782591561380_ytpn3b.jpg',
  'https://media.nowssb.com/migrated-images/58d0a40a97d4a693_grok_image_1782591732123_epmpiu.jpg',
];

const kDefaultAvatar =
    'https://media.nowssb.com/migrated-images/1590b73b14f17aee_image-131_jyrnhx.jpg';


/// Account / settings Profile — distinct from [PracticeProgressScreen].
///
/// Shows avatar, Quick Access, Shop, Preferences. The Progress teaser opens
/// Progress as a pushed route; this widget must never return Progress as its
/// own body (that made Profile and Progress feel identical).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late SharedPreferences _prefs;
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _photo;
  String? _bannerUrl;
  String? _avatarUrl;
  bool _soundOn = true;
  int _duration = 15;
  TimeOfDay _reminder = const TimeOfDay(hour: 7, minute: 0);
  String _voice = 'female';
  final Map<int, bool> _weekDone = {};
  bool _loading = true;
  bool _recentOpen = false;
  String _toast = '';
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_onLiveProgress);
    PracticeProgress.instance.start();
    _load();
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    // Profile is a bottom-nav root — go to Connect home.
    NavScope.goTo(context, 0);
  }

  void _openQuick(String name) {
    switch (name) {
      case 'Sessions':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
      case 'Saved':
      case 'Liked':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoundLibraryScreen()));
      case 'Journal':
        // Journal is account activity — not the My Progress orb screen.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()));
      case 'Settings':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayerSettingsScreen()));
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()));
    }
  }

  void _openShop(String label) {
    switch (label) {
      case 'Cart':
      case 'Wishlist':
      case 'Orders':
        NavScope.goTo(context, 3);
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
    }
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final savedName = _prefs.getString('nowssb_name');
    _nameController.text = savedName?.trim().isNotEmpty == true ? savedName! : 'Practitioner';
    _soundOn = _prefs.getString('nowssb_sound') != 'off';
    _duration = _prefs.getInt('nowssb_duration') ?? 15;
    final savedTime = _prefs.getString('nowssb_reminder');
    if (savedTime != null && savedTime.contains(':')) {
      final parts = savedTime.split(':');
      _reminder = TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts[1]) ?? 0);
    }
    _voice = _prefs.getString('nowssb_voice') ?? 'female';
    _bannerUrl = _prefs.getString('nwsb_local_banner');
    _avatarUrl = _prefs.getString('nwsb_local_photo');
    for (int i = 0; i < 7; i++) {
      final key = 'week_$i';
      if (_prefs.containsKey(key)) _weekDone[i] = _prefs.getBool(key) ?? false;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_onLiveProgress);
    _nameController.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  String get _reminderText => '${_reminder.hour.toString().padLeft(2, '0')}:${_reminder.minute.toString().padLeft(2, '0')}';

  void _showToast(String message) {
    _toast = message;
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: 26,
        right: 26,
        bottom: 26,
        child: IgnorePointer(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                radius: 999,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(_toast, style: const TextStyle(fontSize: 13, color: _text)),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(milliseconds: 1800), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _nameController.text);
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(.72),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF101012),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: _borderSoft)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 32,
            style: const TextStyle(color: _text, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Practitioner name',
              labelStyle: TextStyle(color: _dim),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _border)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accent)),
            ),
            onSubmitted: (_) => Navigator.pop(context, controller.text),
          ),
        ),
      ),
    );
    if (result == null) return;
    final value = result.trim().isEmpty ? 'Practitioner' : result.trim();
    _nameController.text = value;
    await _prefs.setString('nowssb_name', value);
    if (mounted) setState(() {});
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    setState(() => _photo = File(file.path));
  }

  Future<void> _pickReminder() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _reminder,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _accent)), child: child!),
    );
    if (value == null) return;
    _reminder = value;
    await _prefs.setString('nowssb_reminder', _reminderText);
    setState(() {});
  }

  void _onLiveProgress() { if (mounted) setState(() {}); }

  void _toggleWeek(int i, int today) async {
    if (i > today) return;
    final value = !(_weekDone[i] ?? (i < today));
    setState(() => _weekDone[i] = value);
    await _prefs.setBool('week_$i', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(strokeWidth: 1, color: _accent)));
    final int today = (DateTime.now().weekday - 1).clamp(0, 6).toInt();
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: _accent),
        splashFactory: NoSplash.splashFactory,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'SF Pro Display'),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          const Positioned.fill(child: _Background()),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GrainPainter()))),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: double.infinity),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    _banner(),
                    _profileCard(),
                    _progress(),
                    _about(),
                    _quickAccess(),
                    _recentActivity(),
                    _motto(),
                    _weekTracker(today),
                    _preferences(),
                    _shop(),
                    _account(),
                    _quote(),
                    _signOut(),
                  ],
                ),
              ),
            ),
          ),
            if (_recentOpen) _recentSheet(),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    final banner = _bannerUrl;
    return Container(
        height: 150,
        margin: const EdgeInsets.only(top: 20, bottom: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: const Border.fromBorderSide(BorderSide(color: _borderSoft)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner != null && banner.startsWith('http'))
              CachedNetworkImage(imageUrl: banner, fit: BoxFit.cover)
            else
              Image.asset('assets/profile_source/img-banner.png', fit: BoxFit.cover),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.02), Colors.black.withOpacity(.28), Colors.black.withOpacity(.82)]))),
            Positioned(top: 14, left: 14, child: _circleButton(asset: 'assets/icons/icon_01.svg', onTap: _handleBack)),
            Positioned(top: 14, right: 14, child: _circleButton(asset: 'assets/icons/icon_26.svg', onTap: _pickBanner)),
            const Positioned(left: 22, right: 22, bottom: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('My Profile', style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w500, letterSpacing: -1.2, color: Colors.white)), SizedBox(height: 7), Text('YOUR PERSONAL SPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.8, color: Color(0x9EFFFFFF)))])),
          ],
        ),
      );
  }

  Future<void> _pickBanner() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xF00A0A0C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a banner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Same prebuilt library as the website profile.', style: TextStyle(fontSize: 12, color: _dim)),
              const SizedBox(height: 14),
              SizedBox(
                height: 210,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.7),
                  itemCount: kNwsbBanners.length,
                  itemBuilder: (_, i) {
                    final url = kNwsbBanners[i];
                    final on = url == _bannerUrl;
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, url),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: on ? _accent : _borderSoft, width: on ? 2 : 1),
                          image: DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await _prefs.setString('nwsb_local_banner', chosen);
    setState(() => _bannerUrl = chosen);
    _showToast('Banner updated');
  }

  Widget _profileCard() => GlassCard(
        margin: const EdgeInsets.only(bottom: 34),
        radius: 22,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 138,
          child: Row(
            children: [
              SizedBox(
                width: 132,
                child: Stack(children: [
                  const Positioned.fill(child: ColoredBox(color: Color(0xFF0A0A0A))),
                  Positioned.fill(child: Transform.scale(scale: 1.16, child: Opacity(opacity: .98, child: Image.asset('assets/profile_source/img-ring.png', fit: BoxFit.cover, alignment: const Alignment(.0, -.16))))),
                  Positioned(
                    top: 18,
                    right: 17,
                    child: Container(
                      width: 76,
                      height: 76,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A0A0A),
                        border: Border.all(color: const Color(0x99E8D5A3), width: 1.2),
                        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(2, 3))],
                      ),
                      child: _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: (_avatarUrl != null && _avatarUrl!.startsWith('http')) ? _avatarUrl! : kDefaultAvatar,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(child: Text((_nameController.text.trim().isEmpty ? 'P' : _nameController.text.trim().substring(0, 1)).toUpperCase(), style: const TextStyle(fontFamily: _mono, fontSize: 24, fontWeight: FontWeight.w600, color: _text))),
                            ),
                    ),
                  ),
                  Positioned(right: 10, bottom: 10, child: _circleButton(asset: 'assets/icons/icon_02.svg', size: 28, onTap: _pickPhoto)),
                ]),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('PRACTITIONER', style: TextStyle(fontSize: 11, letterSpacing: 2, color: _accent, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(children: [Flexible(child: Text(_nameController.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -.2))), const SizedBox(width: 8), InkWell(onTap: _editName, child: SvgPicture.asset('assets/icons/icon_03.svg', width: 13, height: 13, colorFilter: const ColorFilter.mode(_dim, BlendMode.srcIn)))]),
                    const SizedBox(height: 6),
                    const Flexible(child: Text('Practicing daily, growing steadily.', maxLines: 2, style: TextStyle(fontSize: 12.5, height: 1.45, color: _dim))),
                    const SizedBox(height: 9),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5), decoration: BoxDecoration(color: const Color(0x08FFFFFF), border: const Border.fromBorderSide(BorderSide(color: _border)), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _accent, blurRadius: 6)])), const SizedBox(width: 6), const Text('Free Plan', style: TextStyle(fontSize: 11.5, letterSpacing: .45))])),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _progress() {
    final p = PracticeProgress.instance;
    void openProgress() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeProgressScreen(words: ContentStore.instance.library),
        ),
      );
    }

    return SectionBlock(
      title: 'Your Progress',
      trailing: _viewAll(icon: 'assets/icons/icon_05.svg', onTap: openProgress),
      child: InkWell(
        onTap: openProgress,
        borderRadius: BorderRadius.circular(22),
        child: GlassCard(
          margin: const EdgeInsets.only(bottom: 0),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _TeaserStat('${p.streak}', 'Streak'),
                    const SizedBox(width: 10),
                    _TeaserStat('${p.totalSessions}', 'Sessions'),
                    const SizedBox(width: 10),
                    _TeaserStat('${p.uniqueWords}', 'Words'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderSoft),
                  color: const Color(0x14FFFFFF),
                ),
                alignment: Alignment.center,
                child: _svgIcon('assets/icons/icon_16.svg', 14, _dim),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _about() => GlassCard(
        margin: const EdgeInsets.only(bottom: 40),
        padding: const EdgeInsets.all(22),
        image: 'assets/profile_source/img-about.jpeg',
        overlay: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xB8000000), Color(0x61000000), Color(0xBF000000)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [SvgPicture.asset('assets/icons/icon_04.svg', width: 15, height: 15, colorFilter: const ColorFilter.mode(_dim, BlendMode.srcIn)), const SizedBox(width: 9), const Text('About NowssB', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 14),
          const FractionallySizedBox(widthFactor: .78, child: Text('Before a word had a spelling, it had a sound. NowssB works backward from the dictionary — past the meaning, past the letters — to the breath and vibration a word first came from, so you practice the origin, not just the definition.', style: TextStyle(fontSize: 14, height: 1.65, color: _dim))),
        ]),
      );

  Widget _quickAccess() => SectionBlock(
        marginBottom: 38,
        title: 'Quick Access',
        trailing: _viewAll(icon: 'assets/icons/icon_05.svg', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()))),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          image: 'assets/profile_source/img-qa.jpeg',
          overlay: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xC7000000), Color(0x52000000), Color(0xCC000000)]),
          child: Row(children: List.generate(5, (i) {
            final names = ['Sessions', 'Saved', 'Liked', 'Journal', 'Settings'];
            return Expanded(child: Padding(padding: EdgeInsets.only(right: i == 4 ? 0 : 8), child: _quickItem(names[i], i + 6)));
          })),
        ),
      );

  Widget _quickItem(String name, int iconIndex) => InkWell(
        onTap: () => _openQuick(name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 14, 3, 11),
          decoration: BoxDecoration(color: const Color(0x0FFFFFFF), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0x59000000), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), borderRadius: BorderRadius.circular(11)), child: Center(child: SvgPicture.asset('assets/icons/icon_${iconIndex.toString().padLeft(2, '0')}.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(_text, BlendMode.srcIn)))),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: _dim)),
          ]),
        ),
      );

  Widget _recentActivity() {
    final data = [('Morning Calm', 'Guided Meditation', '2h ago', 'assets/profile_source/img-act1.jpeg'), ('Deep Breathing', 'Breathwork Session', '1d ago', 'assets/profile_source/img-act2.jpeg'), ('Body Scan', 'Sleep Wind-Down', '3d ago', 'assets/profile_source/img-act3.jpeg')];
    return SectionBlock(
      marginBottom: 40,
      title: 'Recent Activity',
      trailing: _viewAll(icon: 'assets/icons/icon_11.svg', onTap: () => setState(() => _recentOpen = true), pill: true),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(children: data.asMap().entries.map((entry) {
          final i = entry.key; final x = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(border: Border(bottom: i == data.length - 1 ? BorderSide.none : const BorderSide(color: _borderSoft))),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(13), child: Container(width: 48, height: 48, decoration: BoxDecoration(image: DecorationImage(image: AssetImage(x.$4), fit: BoxFit.cover), border: const Border.fromBorderSide(BorderSide(color: _borderSoft))))),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(x.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _dim))])),
              const SizedBox(width: 10), Text(x.$3, style: const TextStyle(fontSize: 12, color: _faint)), const SizedBox(width: 10), _circleButton(asset: 'assets/icons/icon_${(12 + i).toString().padLeft(2, '0')}.svg', size: 30, onTap: () => _showToast(x.$1)),
            ]),
          );
        }).toList()),
      ),
    );
  }

  Widget _motto() => GlassCard(
        margin: const EdgeInsets.only(bottom: 40),
        minHeight: 210,
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
        image: 'assets/profile_source/img-motto.jpeg',
        overlay: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x8C000000), Color(0x40000000), Color(0x99000000)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Text('“', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, color: _accent)), const SizedBox(width: 8), const Text('MY MOTTO', style: TextStyle(fontSize: 11, letterSpacing: 2, color: _dim, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 16),
          const FractionallySizedBox(widthFactor: .66, child: Text.rich(TextSpan(children: [TextSpan(text: 'My Focus.\nBreathe.\nLet go.\n'), TextSpan(text: 'Grow.', style: TextStyle(color: _accent))]), style: TextStyle(fontSize: 25, height: 1.22, fontWeight: FontWeight.w300))),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _compactQuick('Practice', '$_duration min', 15)), const SizedBox(width: 5), Expanded(child: _compactQuick('Reminder', _reminderText, 17)), const SizedBox(width: 5), Expanded(child: _compactQuick('Voice', _voice == 'female' ? 'Female' : 'Male', 19)), const SizedBox(width: 5), Expanded(child: _compactQuick('Plan', 'Free', 21))]),
        ]),
      );

  Widget _compactQuick(String label, String value, int icon) => Container(
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 9),
        decoration: BoxDecoration(color: const Color(0x85040405), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0x29E3BD7D), border: Border.all(color: const Color(0x59E3BD7D)), borderRadius: BorderRadius.circular(10)), child: Center(child: SvgPicture.asset('assets/icons/icon_${icon.toString().padLeft(2, '0')}.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn)))), SvgPicture.asset('assets/icons/icon_${(icon + 1).toString().padLeft(2, '0')}.svg', width: 12, height: 12, colorFilter: const ColorFilter.mode(_faint, BlendMode.srcIn))]), const SizedBox(height: 9), Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 7, letterSpacing: .7, color: _dim)), const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))]),
      );

  Widget _weekTracker(int today) => Container(
        margin: const EdgeInsets.only(bottom: 44),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
          final done = _weekDone[i] ?? (i < today);
          final future = i > today;
          return GestureDetector(
            onTap: future ? null : () => _toggleWeek(i, today),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? const Color(0xFFF2F2F0) : Colors.transparent, border: Border.all(color: future ? _borderSoft : (i == today ? const Color(0xD9FFFFFF) : _borderSoft), width: i == today ? 1.5 : 1)),
              child: Center(child: Text(const ['M','T','W','T','F','S','S'][i], style: TextStyle(fontFamily: _mono, fontSize: 13, fontWeight: i == today ? FontWeight.w600 : FontWeight.w400, color: done ? Colors.black : (future ? _dim.withOpacity(.32) : _dim)))),
            ),
          );
        })),
      );

  Widget _preferences() => _sectionList('Preferences', [
        _listRow('Sound Feedback', trailing: ToggleSwitch(value: _soundOn, onChanged: (v) async { setState(() => _soundOn = v); await _prefs.setString('nowssb_sound', v ? 'on' : 'off'); })),
        _listRow('Practice Duration', trailing: Row(mainAxisSize: MainAxisSize.min, children: [_roundAction('assets/icons/icon_24.svg', () async { final v = math.max(5, _duration - 5).toInt(); setState(() => _duration = v); await _prefs.setInt('nowssb_duration', v); }), const SizedBox(width: 14), SizedBox(width: 56, child: Text('$_duration min', textAlign: TextAlign.center, style: const TextStyle(fontFamily: _mono, fontSize: 14))), const SizedBox(width: 14), _roundAction('assets/icons/icon_25.svg', () async { final v = math.min(60, _duration + 5).toInt(); setState(() => _duration = v); await _prefs.setInt('nowssb_duration', v); })])),
        _listRow('Daily Reminder', trailing: InkWell(onTap: _pickReminder, borderRadius: BorderRadius.circular(999), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: const Color(0x08FFFFFF), border: const Border.fromBorderSide(BorderSide(color: _border)), borderRadius: BorderRadius.circular(999)), child: Text(_reminderText, style: const TextStyle(fontFamily: _mono, fontSize: 13.5))))),
        _listRow('Playback Voice', trailing: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(border: const Border.fromBorderSide(BorderSide(color: _border)), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [_voiceButton('Female'), _voiceButton('Male')]))),
        _listRow('App Version', muted: true, trailing: const Text('v2.4.1', style: TextStyle(fontSize: 13, color: _dim))),
      ]);

  Widget _voiceButton(String label) => InkWell(
        onTap: () async { final v = label.toLowerCase(); setState(() => _voice = v); await _prefs.setString('nowssb_voice', v); },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6), decoration: BoxDecoration(color: _voice == label.toLowerCase() ? const Color(0xFFF2F2F0) : Colors.transparent, borderRadius: BorderRadius.circular(999)), child: Text(label, style: TextStyle(fontSize: 12.5, color: _voice == label.toLowerCase() ? Colors.black : _dim))),
      );

  Widget _shop() => _sectionList('Shop & Orders', [
        _shopRow('Cart', '2', 26), _shopRow('Wishlist', '5', 28), _shopRow('Orders', '3', 30),
      ]);

  Widget _account() => _sectionList('Account', [
        _listRow('Member Since', trailing: const Text('Jan 2025', style: TextStyle(fontSize: 13, color: _dim))),
        _listRow('Current Plan', trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Text('Free', style: TextStyle(fontSize: 13, color: _dim)), const SizedBox(width: 10), InkWell(onTap: () => _showToast('Upgrade flow not wired up yet'), child: const Text('Upgrade', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)))])),
      ]);

  Widget _quote() => GlassCard(
        margin: const EdgeInsets.only(bottom: 34),
        minHeight: 170,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        image: 'assets/profile_source/img-quote.jpeg',
        overlay: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xB3000000), Color(0x52000000), Color(0xC7000000)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('“', style: TextStyle(fontFamily: 'Georgia', fontSize: 38, color: _faint, height: 1)), const SizedBox(height: 8), const FractionallySizedBox(widthFactor: .70, child: Text('Long before there was language, there was only sound.', style: TextStyle(fontSize: 17, height: 1.5))), const SizedBox(height: 16), const Text('— THE IDEA BEHIND NOWSSB', style: TextStyle(fontSize: 11, letterSpacing: 1.3, color: _dim))]),
      );

  Widget _signOut() => InkWell(
        onTap: () { _showToast('Signed out'); _handleBack(); },
        borderRadius: BorderRadius.circular(22),
        child: Container(margin: const EdgeInsets.only(bottom: 30), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x08FFFFFF), border: const Border.fromBorderSide(BorderSide(color: _border)), borderRadius: BorderRadius.circular(22)), alignment: Alignment.center, child: const Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
      );

  Widget _sectionList(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionLabel(title), GlassCard(margin: const EdgeInsets.only(bottom: 40), padding: const EdgeInsets.all(4), child: Column(children: rows))]);

  Widget _listRow(String label, {required Widget trailing, bool muted = false}) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _borderSoft))), child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontSize: 14.5, color: muted ? _faint : _text))), const SizedBox(width: 12), trailing]));

  Widget _shopRow(String label, String count, int icon) => InkWell(onTap: () => _openShop(label), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _borderSoft))), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(border: Border.all(color: _borderSoft), borderRadius: BorderRadius.circular(11)), child: Center(child: SvgPicture.asset('assets/icons/icon_${icon.toString().padLeft(2, '0')}.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(_text, BlendMode.srcIn)))), const SizedBox(width: 13), Expanded(child: Text(label, style: const TextStyle(fontSize: 14.5))), Text(count, style: const TextStyle(fontFamily: _mono, fontSize: 12.5, color: _faint)), const SizedBox(width: 6), SvgPicture.asset('assets/icons/icon_16.svg', width: 14, height: 14, colorFilter: const ColorFilter.mode(_faint, BlendMode.srcIn))])));

  Widget _viewAll({required String icon, required VoidCallback onTap, bool pill = false}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(padding: pill ? const EdgeInsets.symmetric(horizontal: 9, vertical: 6) : EdgeInsets.zero, decoration: pill ? BoxDecoration(color: const Color(0x08FFFFFF), border: const Border.fromBorderSide(BorderSide(color: _border)), borderRadius: BorderRadius.circular(999)) : null, child: Row(mainAxisSize: MainAxisSize.min, children: [const Text('View All', style: TextStyle(fontSize: 12, color: _dim)), const SizedBox(width: 5), SvgPicture.asset(icon, width: pill ? 16 : 13, height: pill ? 16 : 13, colorFilter: const ColorFilter.mode(_dim, BlendMode.srcIn))])));

  Widget _svgIcon(String asset, double size, Color color) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(Icons.circle_outlined, size: size, color: color.withOpacity(.45)),
      );

  Widget _circleButton({required String asset, required VoidCallback onTap, double size = 38}) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0x52000000), shape: BoxShape.circle, border: const Border.fromBorderSide(BorderSide(color: Color(0x29FFFFFF)))), child: Center(child: _svgIcon(asset, size * .47, _text)))));

  Widget _roundAction(String asset, VoidCallback onTap) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _border)), child: Center(child: _svgIcon(asset, 13, _text)))));

  Widget _recentSheet() => Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () => setState(() => _recentOpen = false), child: Container(color: Colors.black.withOpacity(.68)))),
        Align(alignment: Alignment.bottomCenter, child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(16), child: _AnimatedSheet(child: GlassCard(radius: 28, padding: const EdgeInsets.all(20), backgroundColor: const Color(0xE60A0A0C), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionLabel('Activity Library', bottom: 6), const Text('More recent sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -.4))])), _circleButton(asset: 'assets/icons/icon_32.svg', onTap: () => setState(() => _recentOpen = false))]),
          const SizedBox(height: 16),
          SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal, children: ['All','Meditation','Breathwork','Sleep'].map((x) => Padding(padding: const EdgeInsets.only(right: 7), child: _SheetTab(label: x))).toList())),
          const SizedBox(height: 14),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width <= 360 ? 1 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.55, children: const [
            _MoreCard('Evening Reset', 'Guided Meditation · 4d ago', 'assets/profile_source/img-act1.jpeg'), _MoreCard('Box Breathing', 'Breathwork · 5d ago', 'assets/profile_source/img-act2.jpeg'), _MoreCard('Night Drift', 'Sleep Wind-Down · 6d ago', 'assets/profile_source/img-act3.jpeg'), _MoreCard('Focus Flow', 'Mindfulness · 7d ago', 'assets/profile_source/img-motto.jpeg'),
          ]),
        ])))))),
      ]);
}

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(image: const DecorationImage(image: AssetImage('assets/profile_source/img-bg.jpeg'), fit: BoxFit.cover, alignment: Alignment.topCenter), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x26000000), Color(0xB8000000), Color(0xEA000000)])), child: const SizedBox.expand());
}

class _GrainPainter extends CustomPainter {
  final math.Random _r = math.Random(9);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (int i = 0; i < 2400; i++) {
      p.color = Colors.white.withOpacity(.018 + _r.nextDouble() * .018);
      final x = _r.nextDouble() * size.width, y = _r.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, .7, .7), p);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final String? image;
  final Gradient? overlay;
  final Color? backgroundColor;
  final double? minHeight;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin, this.radius = 22, this.image, this.overlay, this.backgroundColor, this.minHeight});
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), color: backgroundColor ?? _surface, image: image == null ? null : DecorationImage(image: AssetImage(image!), fit: BoxFit.cover, alignment: Alignment.center)),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: Stack(children: [if (overlay != null) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: overlay))), Padding(padding: padding, child: child)])),
      );
}

class SectionLabel extends StatelessWidget {
  final String text; final double bottom;
  const SectionLabel(this.text, {super.key, this.bottom = 14});
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(bottom: bottom), child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1.54, color: _dim)));
}

class SectionBlock extends StatelessWidget {
  final String title; final Widget child; final Widget? trailing; final double marginBottom;
  const SectionBlock({super.key, required this.title, required this.child, this.trailing, this.marginBottom = 38});
  @override Widget build(BuildContext context) => Container(margin: EdgeInsets.only(bottom: marginBottom), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [SectionLabel(title, bottom: 14), if (trailing != null) trailing!]), child]));
}

class _TeaserStat extends StatelessWidget {
  final String value, label;
  const _TeaserStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x570C0C0E),
            border: Border.all(color: const Color(0x1CFFFFFF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontFamily: _mono, fontSize: 22, fontWeight: FontWeight.w600, height: 1, color: _text)),
              const SizedBox(height: 6),
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1.1, color: _dim)),
            ],
          ),
        ),
      );
}

class ToggleSwitch extends StatelessWidget {
  final bool value; final ValueChanged<bool> onChanged;
  const ToggleSwitch({super.key, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => GestureDetector(onTap: () => onChanged(!value), child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 44, height: 26, padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: value ? const Color(0x24FFFFFF) : const Color(0x08FFFFFF), border: Border.all(color: _border), borderRadius: BorderRadius.circular(999)), child: AnimatedAlign(duration: const Duration(milliseconds: 180), alignment: value ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 20, height: 20, decoration: BoxDecoration(color: value ? Colors.white : _faint, shape: BoxShape.circle)))));
}

class _AnimatedSheet extends StatefulWidget {
  final Widget child; const _AnimatedSheet({required this.child});
  @override State<_AnimatedSheet> createState() => _AnimatedSheetState();
}
class _AnimatedSheetState extends State<_AnimatedSheet> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();
  @override void dispose(){c.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>FadeTransition(opacity: CurvedAnimation(parent:c,curve:Curves.easeOut), child: SlideTransition(position: Tween(begin: const Offset(0,.04),end:Offset.zero).animate(CurvedAnimation(parent:c,curve:Curves.easeOut)), child: widget.child));
}

class _SheetTab extends StatefulWidget { final String label; const _SheetTab({required this.label}); @override State<_SheetTab> createState()=>_SheetTabState(); }
class _SheetTabState extends State<_SheetTab> { bool active = false; @override Widget build(BuildContext context)=>InkWell(onTap:()=>setState(()=>active=!active),borderRadius:BorderRadius.circular(999),child:AnimatedContainer(duration:const Duration(milliseconds:160),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:active?const Color(0x26E3BD7D):const Color(0x08FFFFFF),border:Border.all(color:active?const Color(0x59E3BD7D):_borderSoft),borderRadius:BorderRadius.circular(999)),child:Text(widget.label,style:TextStyle(fontSize:12,color:active?_accent:_dim)))); }

class _MoreCard extends StatelessWidget { final String title,sub,image; const _MoreCard(this.title,this.sub,this.image); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0x06FFFFFF),border:Border.all(color:_borderSoft),borderRadius:BorderRadius.circular(18)),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset(image,width:54,height:54,fit:BoxFit.cover)),const SizedBox(width:10),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w600)),const SizedBox(height:4),Text(sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:_faint))])),Container(width:24,height:24,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:_borderSoft)),alignment:Alignment.center,child:const Text('↗',style:TextStyle(fontSize:12,color:_dim)))])); }