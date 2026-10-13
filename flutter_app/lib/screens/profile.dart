import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../app_update.dart';
import '../data/firebase.dart';
import '../data/settings.dart';

import '../data/cart_bag.dart';
import '../data/content.dart';
import '../data/entitlements.dart';
import 'store/cart_pages.dart';
import '../data/earn_wallet.dart';
import '../features/bazaar/bazaar_screen.dart';
import '../features/circle/circle_screen.dart';
import '../features/earn/earn_hub_screen.dart';
import '../features/earn/earnings_screen.dart';
import '../features/economy/economy_api.dart';
import '../features/economy/reward_fx.dart';
import '../features/economy/economy_theme.dart';
import '../features/economy/money.dart';
import '../features/gifts/gifts_screen.dart';
import '../features/vault/vault_screen.dart';
import '../data/phone_notifications.dart';
import '../data/practice_progress.dart';
import '../shell/nav_shell.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/app_thinking_loader.dart';
import 'app_settings.dart';
import 'auth_gate.dart';
import 'saved_words.dart';
import 'sound_library.dart';
import '../features/notifications/inbox_screen.dart';
import 'progress/progress_screen.dart';
import 'quick_access.dart';
import 'store.dart';
import 'subscription.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../widgets/glass_black_card.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';
import '../features/programs/program_cards.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../pages/profile/new_profile_page.dart';
import '../pages/profile/profile_flag.dart';

const _accent = Color(0xFFE3BD7D);
const _pBg = Colors.black;
const _pInk = _text;
const _pSub = _dim;
const _text = Color(0xFFF5F5F3);
const _dim = Color(0xFF8C8C8C);
const _faint = Color(0xFF565656);
const _border = Color(0x24FFFFFF);
const _borderSoft = Color(0x14FFFFFF);
const _surface = Color(0x14FFFFFF);
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
/// Entry point. Shows the rebuilt page when `newui_profile` is on
/// (admins always; users only once Ribon flips the flag), else the old page.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => ProfileFlagGate(
        newUi: (_) => const NewProfilePage(),
        legacy: (_) => const LegacyProfileScreen(),
      );
}

class LegacyProfileScreen extends StatefulWidget {
  const LegacyProfileScreen({super.key});

  @override
  State<LegacyProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<LegacyProfileScreen> {
  late SharedPreferences _prefs;
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _photo;
  String? _bannerUrl;
  String? _avatarUrl;
  bool _soundOn = true;
  int _duration = 15;
  TimeOfDay _reminder = const TimeOfDay(hour: 7, minute: 0);
  bool _loading = true;
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
        // Practice is a bottom-nav root — switch tab, don't push a copy.
        NavScope.goTo(context, 1);
      case 'Saved':
      case 'Liked':
        // The words saved with the heart in the player.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedWordsScreen()));
      case 'Journal':
        // Journal is account activity — the one inbox (messages, request
        // replies, purchases, rewards), not the My Progress orb screen.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InboxScreen()));
      case 'Settings':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()));
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()));
    }
  }

  void _openShop(String label) {
    switch (label) {
      case 'Cart':
      case 'Orders':
        // The bag, with "Your purchases" (server-confirmed) under it.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartPage()));
      case 'Wishlist':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WishlistPage()));
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
    }
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final savedName = _prefs.getString('nowssb_name');
    final accountName = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser?.displayName?.trim() : null;
    _nameController.text = savedName?.trim().isNotEmpty == true ? savedName! : (accountName?.isNotEmpty == true ? accountName! : 'Practitioner');
    _soundOn = _prefs.getString('nowssb_sound') != 'off';
    // Practice duration is the player's sleep timer (Settings), so the
    // player really stops after it. 0 = no limit.
    _duration = math.max(0, _durationSteps.indexOf(Settings.instance.sleepTimer)) * 15;
    final savedTime = _prefs.getString('nowssb_reminder');
    if (savedTime != null && savedTime.contains(':')) {
      final parts = savedTime.split(':');
      _reminder = TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts[1]) ?? 0);
    }
    _bannerUrl = _prefs.getString('nwsb_local_banner');
    _avatarUrl = _prefs.getString('nwsb_local_photo');
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
    if (result == null || !mounted) return;
    final value = result.trim().isEmpty ? 'Practitioner' : result.trim();
    _nameController.text = value;
    await _prefs.setString('nowssb_name', value);
    if (!mounted) return;
    setState(() {});
    await _saveAccountName(value);
  }

  /// The name is the account's: Firebase displayName, users/{uid} and the
  /// public profile (website Discover) all get it.
  Future<void> _saveAccountName(String value) async {
    if (!NwsbFirebase.ready) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await user.updateDisplayName(value);
      final db = FirebaseFirestore.instance;
      await db.doc('users/${user.uid}').set({'displayName': value}, SetOptions(merge: true));
      await db.doc('publicProfiles/${user.uid}').set({'uid': user.uid, 'displayName': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      // Once-per-account: server verifies name + photo/bio/username.
      reportEarn('profile_complete');
    } catch (e) {
      debugPrint('NowssB profile name: $e');
      if (mounted) _showToast('Saved on this phone. Your account name will update when you are online.');
    }
  }

  static const _durationSteps = ['Off', '15 Min', '30 Min', '45 Min', '1 Hour'];
  String get _durationText => _duration == 0 ? 'No limit' : '$_duration min';
  Future<void> _stepDuration(int by) async {
    final v = (_duration + by).clamp(0, 60).toInt();
    if (!mounted) return;
    setState(() => _duration = v);
    await Settings.instance.setSleepTimer(_durationSteps[v ~/ 15]);
  }

  /// Cloudflare Pages function that signs a one-time R2 PUT for this user's avatar.
  static const _kAvatarUploadUrl = 'https://nowssb.com/api/account/upload-url';

  String _imageContentType(String path) {
    final dot = path.lastIndexOf('.');
    final e = (dot < 0 || dot < path.lastIndexOf('/')) ? '' : path.substring(dot + 1).toLowerCase();
    switch (e) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _imageExt(String path, String contentType) {
    final dot = path.lastIndexOf('.');
    final e = (dot < 0 || dot < path.lastIndexOf('/')) ? '' : path.substring(dot + 1).toLowerCase();
    if (e == 'png' || e == 'webp' || e == 'jpg' || e == 'jpeg') {
      return e == 'jpeg' ? 'jpg' : e;
    }
    if (contentType == 'image/png') return 'png';
    if (contentType == 'image/webp') return 'webp';
    return 'jpg';
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;
    final local = File(picked.path);
    setState(() => _photo = local);
    await _persistPhoto(local);
  }

  /// Upload the picked file to R2, then remember the public URL locally and on the account.
  Future<void> _persistPhoto(File file) async {
    if (!NwsbFirebase.ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save your profile photo.')),
        );
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to save your profile photo.')),
        );
      }
      return;
    }
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large. Max size is 5 MB.')),
        );
        return;
      }
      final contentType = _imageContentType(file.path);
      final ext = _imageExt(file.path, contentType);
      final idToken = await user.getIdToken();
      if (!mounted) return;
      final res = await http
          .post(
            Uri.parse(_kAvatarUploadUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contentType': contentType,
              'ext': ext,
              'contentLength': bytes.length,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      Map<String, dynamic> data = const {};
      try {
        data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      } catch (_) {}
      if (res.statusCode != 200 || data['uploadUrl'] is! String || data['publicUrl'] is! String) {
        throw Exception(data['error'] ?? 'Upload server said ${res.statusCode}.');
      }
      // Content-Type (and Content-Length from the body) were signed into uploadUrl.
      final put = await http
          .put(
            Uri.parse(data['uploadUrl'] as String),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(const Duration(minutes: 2));
      if (!mounted) return;
      if (put.statusCode < 200 || put.statusCode >= 300) {
        throw Exception('Could not store the photo (${put.statusCode}).');
      }
      final publicUrl = data['publicUrl'] as String;
      await _prefs.setString('nwsb_local_photo', publicUrl);
      if (!mounted) return;
      setState(() {
        _avatarUrl = publicUrl;
        // Keep the local File preview until the next load; network URL is the source of truth.
      });
      try {
        await user.updatePhotoURL(publicUrl);
        final db = FirebaseFirestore.instance;
        await db.doc('users/${user.uid}').set({'photoURL': publicUrl}, SetOptions(merge: true));
        await db.doc('publicProfiles/${user.uid}').set({
          'uid': user.uid,
          'photoURL': publicUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Once-per-account: server verifies name + photo/bio/username.
        reportEarn('profile_complete');
      } catch (e) {
        debugPrint('NowssB profile photo account write: $e');
        if (mounted) {
          _showToast('Saved on this phone. Your account photo will update when you are online.');
        }
      }
    } catch (e) {
      debugPrint('NowssB profile photo upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo. ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _pickReminder() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _reminder,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _accent)), child: child!),
    );
    if (value == null || !mounted) return;
    _reminder = value;
    await _prefs.setString('nowssb_reminder', _reminderText);
    if (!mounted) return;
    setState(() {});
  }

  void _onLiveProgress() { if (mounted) setState(() {}); }


  // ───────────────────────── REBUILD-C (Oct 12, 2026) ─────────────────────────
  // Minimal profile: one striking hero (gold sound halo around the avatar),
  // a CLiQ-style member line with the real plan, the real coin balance, then
  // calm grouped rows. Not server-layout driven: layoutChildren() is
  // deliberately not used here so no ui_overrides/server layout can re-add
  // the old banner/promo/quote sections.
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: AppThinkingLoader(label: 'Preparing…', state: OrbState.listening)),
      );
    }
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: _accent),
        splashFactory: NoSplash.splashFactory,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'SF Pro Display'),
      ),
      child: Scaffold(
        backgroundColor: _pBg,
        body: Stack(children: [
          Positioned.fill(child: _rbBackdrop()),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [_banner(), _rbHero()])),
                const SizedBox(height: 26),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
                _rbGroup('Practice', [
                  _rbRow(Icons.insights_rounded, 'Progress', '${PracticeProgress.instance.streak}d', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeProgressScreen(words: ContentStore.instance.library)))),
                  _rbRow(Icons.self_improvement_rounded, 'Practice', '', () => _openQuick('Sessions')),
                  _rbRow(Icons.favorite_border_rounded, 'Saved', '', () => _openQuick('Saved')),
                  _rbRow(Icons.inbox_outlined, 'Journal', '', () => _openQuick('Journal')),
                  _rbRow(Icons.apps_rounded, 'Shortcuts', '', () => _openQuick('More')),
                ]),
                ListenableBuilder(
                  listenable: Listenable.merge([CartBag.instance, Entitlements.instance]),
                  builder: (context, _) => _rbGroup('Shop', [
                    _rbRow(Icons.shopping_bag_outlined, 'Cart', '${CartBag.instance.cartCount}', () => _openShop('Cart')),
                    _rbRow(Icons.bookmark_border_rounded, 'Wishlist', '${CartBag.instance.wishCount}', () => _openShop('Wishlist')),
                    _rbRow(Icons.receipt_long_outlined, 'Orders', '${Entitlements.instance.owned.length}', () => _openShop('Orders')),
                  ]),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([EconomyMirror.instance, EarnWallet.instance]),
                  builder: (context, _) {
                    final m = EconomyMirror.instance;
                                    return _rbGroup('Rewards', [
                      _rbRow(Icons.savings_outlined, 'Vault', '${m.coins}', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VaultScreen()))),
                      _rbRow(Icons.workspace_premium_outlined, 'NowssB Earn', m.live ? m.circleTier : '', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CircleScreen()))),
                      _rbRow(Icons.hub_outlined, 'Earn hub', '', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarnHubScreen()))),
                      _rbRow(Icons.card_giftcard_outlined, 'Gifts', '', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GiftsScreen()))),
                      _rbRow(Icons.account_balance_wallet_outlined, 'Earnings', m.live ? FxBook.instance.formatCents(m.lifetimeCents) : '', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen()))),
                    ]);
                  },
                ),
                _rbGroup('Preferences', [
                  _rbTrail('Sound', Switch(activeColor: Colors.black, activeTrackColor: _accent, value: _soundOn, onChanged: (v) async { setState(() => _soundOn = v); await _prefs.setString('nowssb_sound', v ? 'on' : 'off'); })),
                  _rbTrail('Duration', Row(mainAxisSize: MainAxisSize.min, children: [
                    _rbStep(Icons.remove_rounded, () => _stepDuration(-15)),
                    SizedBox(width: 70, child: Text(_durationText, textAlign: TextAlign.center, style: const TextStyle(fontFamily: _mono, fontSize: 13.5, color: _pInk))),
                    _rbStep(Icons.add_rounded, () => _stepDuration(15)),
                  ])),
                  _rbTrail('Reminder', InkWell(onTap: _pickReminder, borderRadius: BorderRadius.circular(999), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(999)), child: Text(_reminderText, style: const TextStyle(fontFamily: _mono, fontSize: 13.5, color: _pInk))))),
                ]),
                ListenableBuilder(
                  listenable: EconomyMirror.instance,
                  builder: (context, _) => _rbGroup('Account', [
                    _rbTrail('Member since', Text(_memberSince, style: const TextStyle(fontSize: 13, color: _pSub))),
                    _rbRow(Icons.diamond_outlined, 'Plan', _planName, () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()))),
                    _rbRow(Icons.tune_rounded, 'Settings', '', () => _openQuick('Settings')),
                  ]),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _doSignOut,
                    child: const Text('Sign out', style: TextStyle(fontSize: 14, color: _pSub, letterSpacing: .4)),
                  ),
                ),
                ])),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // REBUILD-C 8:22 rule: original NowssB background, grain and banner
  // media exactly as on main 235ae99; layout from the CLiQ Perks ref.
  Widget _rbBackdrop() => Stack(fit: StackFit.expand, children: [
        const _Background(),
        IgnorePointer(child: CustomPaint(painter: _GrainPainter())),
      ]);

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
              EditableImage.asset('assets/profile_source/img-banner.png', fit: BoxFit.cover, slot: 'profile.ProfileScreen'),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.02), Colors.black.withOpacity(.28), Colors.black.withOpacity(.82)]))),
            Positioned(top: 14, left: 14, child: _circleButton(asset: 'assets/icons/icon_01.svg', onTap: _handleBack)),
            Positioned(top: 14, right: 14, child: _circleButton(asset: 'assets/icons/icon_26.svg', onTap: _pickBanner)),
            const Positioned(left: 22, right: 22, bottom: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [EditableLabel('profile.ProfileScreen', 'My Profile', style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w500, letterSpacing: -1.2, color: Colors.white)), SizedBox(height: 7), EditableLabel('profile.ProfileScreen', 'YOUR PERSONAL SPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.8, color: Color(0x9EFFFFFF)))])),
          ],
        ),
      );
  }

  Widget _circleButton({required String asset, required VoidCallback onTap, double size = 38}) => Material(color: Colors.transparent, child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0x52000000), shape: BoxShape.circle, border: const Border.fromBorderSide(BorderSide(color: Color(0x29FFFFFF)))), child: Center(child: EditableSvg.asset(asset, width: size * .47, height: size * .47, colorFilter: const ColorFilter.mode(_text, BlendMode.srcIn), placeholderBuilder: (_) => Icon(Icons.circle_outlined, size: size * .47, color: _dim), slot: 'profile.ProfileScreen')))));

  Widget _rbAvatar() {
    final initial = (_nameController.text.trim().isEmpty ? 'P' : _nameController.text.trim().substring(0, 1)).toUpperCase();
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0A0A0A), border: Border.all(color: const Color(0xCCFFB199), width: 1.2)),
          child: _photo != null
              ? Image.file(_photo!, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: (_avatarUrl != null && _avatarUrl!.startsWith('http')) ? _avatarUrl! : kDefaultAvatar,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(child: Text(initial, style: const TextStyle(fontFamily: _mono, fontSize: 30, color: _text))),
                  errorWidget: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(fontFamily: _mono, fontSize: 30, color: _text))),
                ),
        ),
      ),
      Positioned(
        right: -2,
        bottom: -2,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickPhoto,
            customBorder: const CircleBorder(),
            child: Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.black, width: 1)), child: const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.black)),
          ),
        ),
      ),
    ]);
  }

  Widget _rbHero() => ListenableBuilder(
        listenable: Listenable.merge([EconomyMirror.instance, PracticeProgress.instance]),
        builder: (context, _) {
          final m = EconomyMirror.instance;
          final signedIn = NwsbFirebase.ready && FirebaseAuth.instance.currentUser != null;
          final plan = _planName == 'Free' ? 'Free' : _planName;
          final first = _nameController.text.trim().split(' ').first;
          final until = m.subUntil > 0 && _planName != 'Free' ? DateTime.fromMillisecondsSinceEpoch(m.subUntil) : null;
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return Column(children: [
            const SizedBox(height: 8),
            Text(first.isEmpty ? 'Hello' : 'Hello $first', style: const TextStyle(fontSize: 16, color: _pInk)),
            const SizedBox(height: 4),
            Text("You're on ${plan.toUpperCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _pInk)),
            const SizedBox(height: 22),
            // Member card: glass-wrapped black card with the original ring art.
            GlassBlackCard(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 150,
                child: Row(children: [
                  SizedBox(
                    width: 140,
                    child: Stack(children: [
                      Positioned.fill(child: EditableImage.asset('assets/profile_source/img-ring.png', fit: BoxFit.cover, alignment: const Alignment(0, -.16), slot: 'profile.ProfileScreen')),
                      Align(alignment: const Alignment(.1, -.25), child: SizedBox.square(dimension: 76, child: _rbAvatar())),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        InkWell(
                          onTap: _editName,
                          child: Row(children: [
                            Flexible(child: Text(_nameController.text.isEmpty ? 'Your name' : _nameController.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _text))),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined, size: 14, color: _dim),
                          ]),
                        ),
                        const Spacer(),
                        Row(children: [
                          Text(plan.toUpperCase(), style: const TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w700, color: _accent)),
                          const SizedBox(width: 6),
                          const Icon(Icons.auto_awesome, size: 13, color: _accent),
                        ]),
                      ]),
                    ),
                  ),
                ]),
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: .05, curve: Curves.easeOutCubic),
            const SizedBox(height: 22),
            if (signedIn)
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VaultScreen())),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                  child: Row(children: [
                    Expanded(child: Column(children: [
                      const Text('Coins', style: TextStyle(fontSize: 12, color: _pSub)),
                      const SizedBox(height: 4),
                      Text('${m.coins}', style: const TextStyle(fontFamily: _mono, fontSize: 20, color: _pInk)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: _pInk),
                  ]),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0x1FFFFFFF), foregroundColor: _text, side: const BorderSide(color: _border), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
                child: const Text('VIEW PLANS', style: TextStyle(letterSpacing: 1.6, fontSize: 13)),
              ),
            ),
            if (until != null) ...[
              const SizedBox(height: 10),
              Text('Valid until ${until.day} ${months[until.month - 1]} ${until.year}', style: const TextStyle(fontSize: 12, color: _pSub)),
            ],
          ]);
        },
      );

  Widget _rbGroup(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 6, bottom: 10), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, letterSpacing: 2.2, color: _pSub))),
          GlassBlackCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, thickness: .5, indent: 62, color: _borderSoft),
                  rows[i],
                ],
              ]),
            ),
          ),
        ]),
      );

  Widget _rbRow(IconData icon, String label, String value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14E3BD7D)), child: Icon(icon, size: 16, color: _accent)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: _pInk))),
            if (value.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 8), child: Text(value, style: const TextStyle(fontFamily: _mono, fontSize: 13, color: _pInk))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _pSub),
          ]),
        ),
      );

  Widget _rbTrail(String label, Widget trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(62, 12, 16, 12),
        child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: _pInk))), trailing]),
      );

  Widget _rbStep(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _border)), child: Icon(icon, size: 14, color: _pInk))),
      );

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
              const EditableLabel('profile.ProfileScreen', 'Choose a banner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const EditableLabel('profile.ProfileScreen', 'Same prebuilt library as the website profile.', style: TextStyle(fontSize: 12, color: _dim)),
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
    if (chosen == null || !mounted) return;
    await _prefs.setString('nwsb_local_banner', chosen);
    if (!mounted) return;
    setState(() => _bannerUrl = chosen);
    _showToast('Banner updated');
  }

  String get _planName => EconomyMirror.instance.plan;

  /// Small glass pill with the signed-in user's existing coin balance
  /// (EconomyMirror). Hidden when there is no signed-in wallet.
  Widget _earnLink(String label, Widget page) => InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(BorderSide(color: _border)),
          ),
          child: EditableLabel('profile.ProfileScreen', label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
        ),
      );

  Widget _quickItem(String name, int iconIndex) => InkWell(
        onTap: () => _openQuick(name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 14, 3, 11),
          decoration: BoxDecoration(color: const Color(0x0FFFFFFF), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0x59000000), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), borderRadius: BorderRadius.circular(11)), child: Center(child: EditableSvg.asset('assets/icons/icon_${iconIndex.toString().padLeft(2, '0')}.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(_text, BlendMode.srcIn), slot: 'profile.ProfileScreen'))),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: _dim)),
          ]),
        ),
      );

  static String _coinReason(String r) {
    final k = r.split(':').first;
    const names = {
      'login': 'Daily sign-in', 'quest': 'Quest', 'scratch': 'Scratch card', 'checkout': 'Coins at checkout', 'checkout-release': 'Coins returned',
      'sale-coins': 'Sale coins', 'expired': 'Coins expired', 'gift': 'Gift', 'box': 'Gift box', 'spin': 'Spin', 'season': 'Season reward',
      'league': 'League reward', 'mastery': 'Mastery', 'practice': 'Practice', 'explore': 'Explored a page', 'coins-back': 'Coins back on a purchase',
    };
    for (final e in names.entries) {
      if (k.startsWith(e.key)) return e.value;
    }
    return r.isEmpty ? 'Coins' : r;
  }

  // Real counts: the bag and wishlist (CartBag) and the items this account
  // owns (users/{uid}/owned, via Entitlements).

  static String _ago(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  /// Practice history → cards, with each word's first library category.
  List<({String word, String cat, String when})> get _recentSessions {
    final lib = {for (final w in ContentStore.instance.library) w.word.toLowerCase(): w};
    return [
      for (final m in PracticeProgress.instance.sessionsSnapshot)
        if ('${m['word'] ?? ''}'.isNotEmpty && !'${m['word']}'.contains('Streak restore'))
          (
            word: '${m['word']}',
            cat: (lib['${m['word']}'.toLowerCase()]?.categories.isNotEmpty ?? false)
                ? lib['${m['word']}'.toLowerCase()]!.categories.first
                : 'Practice',
            when: _ago('${m['completedAt'] ?? m['date'] ?? ''}'),
          ),
    ];
  }

  String get _memberSince {
    final user = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    final t = user?.metadata.creationTime;
    if (t == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[t.month - 1]} ${t.year}';
  }

  Future<void> _doSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171E),
        title: const EditableLabel('profile.SignOutDialog', 'Sign out?', style: TextStyle(color: _text)),
        content: const EditableLabel(
          'profile.SignOutDialog',
          'You will need to choose an account the next time you sign in.',
          style: TextStyle(color: _dim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const EditableLabel('profile.SignOutDialog', 'Stay signed in'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const EditableLabel('profile.SignOutDialog', 'Sign out', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Same path as Settings: Google disconnect + Firebase signOut.
    // EconomyMirror clears the wallet on authStateChanges (user == null).
    const webClient =
        '1024709686012-h1h9glk84uti9cbqpht5d09igdqb8pgu.apps.googleusercontent.com';
    final google =
        GoogleSignIn(scopes: const ['email'], serverClientId: webClient);
    try {
      await google.disconnect();
    } catch (_) {}
    try {
      await google.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    NotificationBanner.items.value = const [];
    AuthGate.askForAccount();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  // Calm list: one glass-wrapped black card, rows with thin inset dividers.
}

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(image: DecorationImage(image: slotImageProvider(context, 'profile.Background', 'assets/profile_source/img-bg.jpeg', const AssetImage('assets/profile_source/img-bg.jpeg')), fit: BoxFit.cover, alignment: Alignment.topCenter), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Color(0xE6000000), Color(0xFF000000)])), child: const SizedBox.expand());
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
  Widget build(BuildContext context) {
    // Sprint 2026-10-12: calm glass wrapper around a black card.
    if (image == null) {
      return Container(
        width: double.infinity,
        margin: margin,
        constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
        child: GlassBlackCard(
          radius: radius + 4,
          frame: 5,
          intensity: .45,
          padding: EdgeInsets.zero,
          child: Stack(children: [
            if (overlay != null) Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: overlay))),
            Padding(padding: padding, child: child),
          ]),
        ),
      );
    }
    return _imageCard(context);
  }

  Widget _imageCard(BuildContext context) => Container(
        margin: margin,
        constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: const Border.fromBorderSide(BorderSide(color: _borderSoft)), color: backgroundColor ?? _surface, image: image == null ? null : DecorationImage(image: slotImageProvider(context, 'profile.GlassCard', image!, AssetImage(image!)), fit: BoxFit.cover, alignment: Alignment.center)),
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
  final bool expanded;
  final Widget? figure;
  const _TeaserStat(this.value, this.label, {this.expanded = true, this.figure});
  @override
  Widget build(BuildContext context) {
    final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x570C0C0E),
            border: Border.all(color: const Color(0x1CFFFFFF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              figure ?? Text(value, style: const TextStyle(fontFamily: _mono, fontSize: 22, fontWeight: FontWeight.w600, height: 1, color: _text)),
              const SizedBox(height: 6),
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1.1, color: _dim)),
            ],
          ),
        );
    return expanded ? Expanded(child: chip) : chip;
  }
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

class _SheetTab extends StatelessWidget { final String label; final bool active; final VoidCallback onTap; const _SheetTab({required this.label, required this.active, required this.onTap}); @override Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(999),child:AnimatedContainer(duration:const Duration(milliseconds:160),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:active?const Color(0x26E3BD7D):const Color(0x08FFFFFF),border:Border.all(color:active?const Color(0x59E3BD7D):_borderSoft),borderRadius:BorderRadius.circular(999)),child:EditableLabel('profile.SheetTab', label,style:TextStyle(fontSize:12,color:active?_accent:_dim)))); }

class _MoreCard extends StatelessWidget { final String title,sub,image; const _MoreCard(this.title,this.sub,this.image); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:const Color(0x06FFFFFF),border:Border.all(color:_borderSoft),borderRadius:BorderRadius.circular(18)),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(13),child:EditableImage.asset(image,width:54,height:54,fit:BoxFit.cover, slot: 'profile.MoreCard')),const SizedBox(width:10),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[EditableLabel('profile.MoreCard', title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w600)),const SizedBox(height:4),EditableLabel('profile.MoreCard', sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,color:_faint))])),Container(width:24,height:24,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:_borderSoft)),alignment:Alignment.center,child:const EditableLabel('profile.MoreCard', '↗',style:TextStyle(fontSize:12,color:_dim)))])); }
