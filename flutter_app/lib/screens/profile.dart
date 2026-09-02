library;

import 'package:flutter/material.dart';

const _bg = AssetImage('assets/profile/profile-01.jpg');
const _ring = AssetImage('assets/profile/profile-02.png');
const _motto = AssetImage('assets/profile/profile-03.jpg');
const _about = AssetImage('assets/profile/profile-04.jpg');
const _quote = AssetImage('assets/profile/profile-05.jpg');
const _quick = AssetImage('assets/profile/profile-06.jpg');
const _activity = AssetImage('assets/profile/profile-07.jpg');
const _progress = AssetImage('assets/profile/profile-10.png');
const _banner = AssetImage('assets/profile/profile-11.png');
const _ink = Color(0xFFF4F2EE);
const _muted = Color(0x99F4F2EE);
const _gold = Color(0xFFE3BD7D);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070708),
      body: Stack(children: [
        Positioned.fill(child: Image(image: _bg, fit: BoxFit.cover)),
        SafeArea(child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _imagePanel(_banner, Padding(padding: const EdgeInsets.fromLTRB(18, 22, 18, 18), child: Row(children: [
                _CircleButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
                const Spacer(),
                const Text('MY PROFILE', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 3)),
              ]))),
              const SizedBox(height: 20),
              _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  SizedBox(width: 74, height: 74, child: Stack(children: [
                    Positioned(left: 4, top: 4, right: 0, bottom: 0, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image(image: const NetworkImage('https://media.nowssb.com/migrated-images/1590b73b14f17aee_image-131_jyrnhx.jpg'), fit: BoxFit.cover, alignment: const Alignment(0.08, 0.16)))),
                    Positioned.fill(child: Image(image: _ring, fit: BoxFit.cover)),
                  ])),
                  const SizedBox(width: 16),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Practitioner', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 2)), SizedBox(height: 5), Text('Practitioner', style: TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w500)), SizedBox(height: 7), Text('Practicing daily, growing steadily.', style: TextStyle(color: _muted, fontSize: 12))])),
                  Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xE6141416), border: Border.all(color: const Color(0x33FFFFFF))), child: const Icon(Icons.edit_outlined, color: _muted, size: 16)),
                ]),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0x1AE3BD7D), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x55E3BD7D))), child: const Text('●  FREE PLAN', style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 1.5))),
              ])),
              const SizedBox(height: 18),
              _section('YOUR PROGRESS', _imagePanel(_progress, Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [_Stat('12', 'DAYS\nDAY STREAK'), _Stat('47', 'TOTAL\nSESSIONS'), _Stat('128', 'LEARNED\nWORDS'), _Stat('5', 'OF 5\nORGANS')] ))),
              _section('ABOUT NOWSSB', _imagePanel(_about, const Text('Before a word had a spelling, it had a sound. NowssB works backward from the dictionary — past the meaning, past the letters — to the breath and vibration a word first came from, so you practice the origin, not just the definition.', style: TextStyle(color: _muted, fontSize: 13, height: 1.6)))),
              _section('QUICK ACCESS', _imagePanel(_quick, Wrap(spacing: 8, runSpacing: 8, children: const [_Quick('Sessions', Icons.local_fire_department_outlined), _Quick('Saved', Icons.bookmark_border), _Quick('Liked', Icons.favorite_border), _Quick('Journal', Icons.menu_book_outlined), _Quick('Settings', Icons.settings_outlined)]))),
              _section('RECENT ACTIVITY', _imagePanel(_activity, Column(children: const [_Activity('Morning Calm', 'Guided Meditation', '2h ago'), _Activity('Deep Breathing', 'Breathwork Session', '1d ago'), _Activity('Body Scan', 'Sleep Wind-Down', '3d ago')] ))),
              _section('MY MOTTO', _imagePanel(_motto, const Text('My Focus.\nBreathe.\nLet go.\nGrow.', style: TextStyle(color: _ink, fontSize: 27, height: 1.28, fontWeight: FontWeight.w400)))),
              _section('PREFERENCES', _panel(Column(children: const [_Pref('Sound Feedback', 'ON'), _Pref('Practice Duration', '15 MIN'), _Pref('Daily Reminder', '07:00'), _Pref('Playback Voice', 'FEMALE'), _Pref('App Version', 'v2.4.1')] ))),
              _section('SHOP & ORDERS', _panel(Column(children: const [_Pref('Cart', '2'), _Pref('Wishlist', '5'), _Pref('Orders', '3')] ))),
              _section('ACCOUNT', _panel(Column(children: const [_Pref('Member Since', 'JAN 2025'), _Pref('Current Plan', 'FREE')] ))),
              const SizedBox(height: 20),
              Center(child: TextButton(onPressed: () {}, child: const Text('SIGN OUT', style: TextStyle(color: _muted, letterSpacing: 2, fontSize: 11)))),
            ])),
          ),
        ])),
      ]),
    );
  }

  Widget _section(String title, Widget child) => Padding(padding: const EdgeInsets.only(top: 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted, fontSize: 10, letterSpacing: 2.5)), const SizedBox(height: 9), child]));
  Widget _imagePanel(ImageProvider image, Widget child) => Container(width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x22FFFFFF)), image: DecorationImage(image: image, fit: BoxFit.cover, colorFilter: const ColorFilter.mode(Color(0xB8000000), BlendMode.darken)), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 22, offset: Offset(0, 10))]), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: child));
  Widget _panel(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xB80D0D10), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x22FFFFFF)), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 22, offset: Offset(0, 10))]), child: child);
}

class _CircleButton extends StatelessWidget { const _CircleButton({required this.icon, required this.onTap}); final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext c) => IconButton(onPressed: onTap, icon: Icon(icon, color: _ink, size: 23)); }
class _Stat extends StatelessWidget { const _Stat(this.number, this.label); final String number, label; @override Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: const TextStyle(color: _ink, fontSize: 27, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: _muted, fontSize: 9, height: 1.35, letterSpacing: 1))]); }
class _Quick extends StatelessWidget { const _Quick(this.label, this.icon); final String label; final IconData icon; @override Widget build(BuildContext c) => Container(width: 88, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), decoration: BoxDecoration(color: const Color(0x66040405), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x18FFFFFF))), child: Column(children: [Icon(icon, color: _gold, size: 19), const SizedBox(height: 7), Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10, letterSpacing: .5))])); }
class _Activity extends StatelessWidget { const _Activity(this.title, this.sub, this.time); final String title, sub, time; @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(children: [const Icon(Icons.circle, color: _gold, size: 7), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontSize: 13)), const SizedBox(height: 3), Text(sub, style: const TextStyle(color: _muted, fontSize: 11))])), Text(time, style: const TextStyle(color: _muted, fontSize: 10))])); }
class _Pref extends StatelessWidget { const _Pref(this.label, this.value); final String label, value; @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: _ink, fontSize: 12, letterSpacing: .8))), Text(value, style: const TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.4)), const SizedBox(width: 8), const Icon(Icons.chevron_right, color: _muted, size: 17)])); }
