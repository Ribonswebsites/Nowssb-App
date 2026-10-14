import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../shell/nav_shell.dart';
import '../widgets/app_backdrop.dart';

/// Profile. Three horizontal rails of glass practice cards over the app's
/// own background film. The old profile, the hamburger menu and the settings
/// page are gone — this screen is the replacement.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppBackdrop(),
          SafeArea(
            bottom: false,
            child: _ProfileBody(),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.asset,
    required this.title,
    required this.time,
    required this.rating,
    required this.sessions,
    required this.joined,
    required this.slot,
  });

  final String asset;
  final String title;
  final String time;
  final String rating;
  final String sessions;
  final String joined;
  final String slot;
}

const _breath = <_CardData>[
  _CardData(
    asset: 'assets/profile/rails/01.jpg',
    title: 'Trusting the Breath',
    time: '4 min',
    rating: '4.9',
    sessions: '8',
    joined: '+12',
    slot: 'profile.breath.1',
  ),
  _CardData(
    asset: 'assets/profile/rails/02.jpg',
    title: 'Quiet Inhale',
    time: '6 min',
    rating: '4.8',
    sessions: '6',
    joined: '+8',
    slot: 'profile.breath.2',
  ),
  _CardData(
    asset: 'assets/profile/rails/03.jpg',
    title: 'Lotus at Dusk',
    time: '8 min',
    rating: '4.7',
    sessions: '5',
    joined: '+6',
    slot: 'profile.breath.3',
  ),
  _CardData(
    asset: 'assets/profile/rails/04.jpg',
    title: 'Sheer Stillness',
    time: '5 min',
    rating: '4.9',
    sessions: '7',
    joined: '+9',
    slot: 'profile.breath.4',
  ),
  _CardData(
    asset: 'assets/profile/rails/05.jpg',
    title: 'The First Breath',
    time: '7 min',
    rating: '4.6',
    sessions: '4',
    joined: '+4',
    slot: 'profile.breath.5',
  ),
];

const _sound = <_CardData>[
  _CardData(
    asset: 'assets/profile/rails/06.jpg',
    title: 'Listening Room',
    time: '12 min',
    rating: '4.8',
    sessions: '12',
    joined: '+2k',
    slot: 'profile.sound.1',
  ),
  _CardData(
    asset: 'assets/profile/rails/07.jpg',
    title: 'Heart of Sound',
    time: '9 min',
    rating: '4.7',
    sessions: '9',
    joined: '+18',
    slot: 'profile.sound.2',
  ),
  _CardData(
    asset: 'assets/profile/rails/08.jpg',
    title: 'Still Water',
    time: '11 min',
    rating: '4.9',
    sessions: '10',
    joined: '+11',
    slot: 'profile.sound.3',
  ),
  _CardData(
    asset: 'assets/profile/rails/09.jpg',
    title: 'Violet Silk',
    time: '14 min',
    rating: '4.8',
    sessions: '11',
    joined: '+7',
    slot: 'profile.sound.4',
  ),
  _CardData(
    asset: 'assets/profile/rails/10.jpg',
    title: 'Morning Seat',
    time: '10 min',
    rating: '4.6',
    sessions: '8',
    joined: '+15',
    slot: 'profile.sound.5',
  ),
];

const _still = <_CardData>[
  _CardData(
    asset: 'assets/profile/rails/11.jpg',
    title: 'Seven Days of Breath',
    time: '18 min',
    rating: '4.9',
    sessions: '16',
    joined: '+21',
    slot: 'profile.still.1',
  ),
  _CardData(
    asset: 'assets/profile/rails/12.jpg',
    title: 'The Quiet Path',
    time: '16 min',
    rating: '4.8',
    sessions: '14',
    joined: '+9',
    slot: 'profile.still.2',
  ),
  _CardData(
    asset: 'assets/profile/rails/13.jpg',
    title: 'Rings of Sound',
    time: '15 min',
    rating: '4.7',
    sessions: '13',
    joined: '+5',
    slot: 'profile.still.3',
  ),
  _CardData(
    asset: 'assets/profile/rails/14.jpg',
    title: 'Night Shore',
    time: '20 min',
    rating: '4.8',
    sessions: '12',
    joined: '+3',
    slot: 'profile.still.4',
  ),
  _CardData(
    asset: 'assets/profile/rails/15.jpg',
    title: 'Shabdapathy',
    time: '12 min',
    rating: '4.9',
    sessions: '9',
    joined: '+16',
    slot: 'profile.still.5',
  ),
];

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 128),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Portrait(),
          ),
        ),
        _SectionHead('Breath', 'profile.section.breath'),
        _Rail(cards: _breath),
        SizedBox(height: 22),
        _SectionHead('Sound', 'profile.section.sound'),
        _Rail(cards: _sound),
        SizedBox(height: 22),
        _SectionHead('Stillness', 'profile.section.still'),
        _Rail(cards: _still),
      ],
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: EditableImage.asset(
          'assets/profile/rails/avatar_a.jpg',
          width: 53,
          height: 53,
          fit: BoxFit.cover,
          slot: 'profile.portrait',
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFC9A4B5),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, this.slot);

  final String title;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditableLabel(
            slot,
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
              height: 1,
              shadows: [
                Shadow(color: Color(0x99000000), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(width: 3),
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Text(
              '5',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.cards});

  final List<_CardData> cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 372,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _PracticeCard(data: cards[i]),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.data});

  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NavScope.goTo(context, 1),
      child: Container(
        width: 300,
        height: 372,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xB8FFFFFF), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              EditableImage.asset(
                data.asset,
                fit: BoxFit.cover,
                slot: data.slot,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF6B3A62)),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x14000000),
                      Color(0x00000000),
                      Color(0x66000000),
                      Color(0xC414061C),
                    ],
                    stops: [0, 0.38, 0.68, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Joined(count: data.joined, slot: data.slot),
                    const Spacer(),
                    EditableLabel(
                      '${data.slot}.title',
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        height: 1.05,
                        shadows: [
                          Shadow(color: Color(0x80000000), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Meta(
                      time: data.time,
                      rating: data.rating,
                      sessions: data.sessions,
                      slot: data.slot,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: _Continue(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Joined extends StatelessWidget {
  const _Joined({required this.count, required this.slot});

  final String count;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 34,
      child: Stack(
        children: [
          const Positioned(left: 0, top: 0, child: _Face('assets/profile/rails/avatar_a.jpg', 'profile.face.a')),
          const Positioned(left: 22, top: 0, child: _Face('assets/profile/rails/avatar_b.jpg', 'profile.face.b')),
          Positioned(
            left: 48,
            top: 0,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: EditableLabel(
                  '$slot.joined',
                  count,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face(this.asset, this.slot);

  final String asset;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(1.6),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: EditableImage.asset(
          asset,
          width: 31,
          height: 31,
          fit: BoxFit.cover,
          slot: slot,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFFD7B4C4)),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.time,
    required this.rating,
    required this.sessions,
    required this.slot,
  });

  final String time;
  final String rating;
  final String sessions;
  final String slot;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xF2FFFFFF),
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1,
    );
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 5),
        EditableLabel('$slot.time', time, style: style),
        const SizedBox(width: 14),
        const Icon(Icons.star_rounded, color: Color(0xFFFFD60A), size: 20),
        const SizedBox(width: 3),
        EditableLabel('$slot.rating', rating, style: style),
        const SizedBox(width: 14),
        const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        EditableLabel('$slot.sessions', sessions, style: style),
      ],
    );
  }
}

class _Continue extends StatelessWidget {
  const _Continue();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
      ],
    );
  }
}
