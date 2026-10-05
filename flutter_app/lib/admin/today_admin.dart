/// Who signed in — a list, not a number. Each person with the first and
/// last time they opened NowssB that day (India time), how many times,
/// platform, OS and app build; online now in mint. Server action `today`
/// (presenceDays/{day}/people + users.lastSeenAt), or the same from
/// Firestore when the admin server is off.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_data.dart';
import 'admin_kit.dart';
import 'person_admin.dart';

String _hm(dynamic v) {
  final ms = msOf(v);
  if (ms <= 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _device(Map r) => [
      '${r['platform'] ?? ''}'.isEmpty ? '' : ('${r['platform']}' == 'ios' ? 'iOS' : 'Android'),
      '${r['build'] ?? ''}'.isEmpty ? '' : 'build ${r['build']}',
      _osShort('${r['os'] ?? ''}'),
    ].where((e) => e.isNotEmpty).join(' · ');

String _osShort(String os) {
  if (os.isEmpty) return '';
  return os.length > 28 ? '${os.substring(0, 28)}…' : os;
}

/// One row: avatar, name/email, first → last time, opens, device.
class SignedInRow extends StatelessWidget {
  const SignedInRow(this.r, {super.key});
  final Map r;
  @override
  Widget build(BuildContext context) {
    final name = '${r['name'] ?? ''}'.trim();
    final email = '${r['email'] ?? ''}';
    final online = r['online'] == true;
    final opens = (r['opens'] as num?)?.toInt() ?? 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        onTap: () => pushAdmin(context, PersonAdminScreen(uid: '${r['uid']}')),
        child: Row(children: [
          Avatar(name: name.isNotEmpty ? name : email, photo: '${r['photo'] ?? ''}', size: 34, online: online),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isNotEmpty ? name : (email.isNotEmpty ? email : '${r['uid']}'),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(
                [if (name.isNotEmpty && email.isNotEmpty) email, _device(r)].where((e) => e.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kFaint, fontSize: 10.5),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(online ? 'online · ${_hm(r['last'])}' : _hm(r['last']),
                style: TextStyle(color: online ? kMint : Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            Text('first ${_hm(r['first'])} · ${opens}x', style: const TextStyle(color: kFaint, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

/// The Dashboard block: today's people, newest first, refreshed each minute.
class TodaySection extends StatefulWidget {
  const TodaySection({super.key, this.max = 12});
  final int max;
  @override
  State<TodaySection> createState() => _TodaySectionState();
}

class _TodaySectionState extends State<TodaySection> {
  Map<String, dynamic>? _d;
  Object? _err;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await AdminData.run('today', {'tzOffsetMin': kDayTzMin});
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final rows = ((d?['rows'] as List?) ?? const []).cast<Map>();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHead(d == null ? 'Loading…' : '${fmtNum(d['total'] as num? ?? 0)} people · ${fmtNum(d['online'] as num? ?? 0)} online now', 'Signed in today',
          trailing: Pill('All', dense: true, icon: Icons.open_in_full_rounded, onTap: () => pushAdmin(context, const TodayAdminScreen()))),
      if (d == null && _err != null)
        Text('Could not load today’s list: $_err', style: const TextStyle(color: kAmber, fontSize: 11.5))
      else if (d == null)
        const Padding(padding: EdgeInsets.all(16), child: OrbLoading(label: 'Finding who opened NowssB today…', size: 40))
      else if (rows.isEmpty)
        const EmptyNote('Nobody has opened the app yet today (India time).', icon: Icons.nightlight_round)
      else ...[
        for (final r in rows.take(widget.max)) SignedInRow(r),
        if (rows.length > widget.max)
          Align(
            alignment: Alignment.centerLeft,
            child: Pill('See all ${rows.length}', dense: true, onTap: () => pushAdmin(context, const TodayAdminScreen())),
          ),
      ],
    ]);
  }
}

/// Full list for one day, with search and the last 14 days to pick from.
class TodayAdminScreen extends StatefulWidget {
  const TodayAdminScreen({super.key});
  @override
  State<TodayAdminScreen> createState() => _TodayAdminScreenState();
}

class _TodayAdminScreenState extends State<TodayAdminScreen> {
  late String _day = dayKeyOf(DateTime.now().millisecondsSinceEpoch);
  Map<String, dynamic>? _d;
  Object? _err;
  bool _busy = false;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final d = await AdminData.run('today', {'day': _day, 'tzOffsetMin': kDayTzMin});
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final days = [for (var i = 0; i < 14; i++) dayKeyOf(now - i * kDay)];
    final needle = _q.text.trim().toLowerCase();
    final rows = ((_d?['rows'] as List?) ?? const []).cast<Map>().where((r) {
      if (needle.isEmpty) return true;
      return ['name', 'email', 'uid', 'platform', 'build'].any((k) => '${r[k] ?? ''}'.toLowerCase().contains(needle));
    }).toList();
    return AdminPage(
      eyebrow: _d == null ? 'Sign-ins' : '${fmtNum(_d!['total'] as num? ?? 0)} people · ${fmtNum(_d!['online'] as num? ?? 0)} online',
      title: _day == days.first ? 'Signed in today' : 'Signed in $_day',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kGold))
              : const Icon(Icons.refresh_rounded, color: kGold),
        ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Column(children: [
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Pill(d == days.first ? 'Today' : (d == days[1] ? 'Yesterday' : d.substring(5)), dense: true, selected: _day == d, onTap: () {
                    setState(() => _day = d);
                    _load();
                  }),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: kGold), hintText: 'Name, email, build'),
          ),
        ]),
      ),
      body: _d == null
          ? (_err != null ? AdminProblem(error: _err!, onRetry: _load) : const OrbLoading(label: 'Reading sign-ins…'))
          : RefreshIndicator(
              color: kGold,
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 60), children: [
                const Text('Times are this phone’s clock. A day is India time, midnight to midnight.', style: TextStyle(color: kFaint, fontSize: 10.5)),
                const SizedBox(height: 8),
                if (rows.isEmpty) const EmptyNote('Nobody on this day.', icon: Icons.nightlight_round),
                for (final r in rows) SignedInRow(r),
              ]),
            ),
    );
  }
}
