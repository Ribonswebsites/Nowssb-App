/// People — search everyone by name, email, uid or phone; filter by plan,
/// blocked, online, helper, expired and join date. Tap a person for the
/// full profile and every action.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_data.dart';
import 'admin_kit.dart';
import 'person_admin.dart';

class PeopleAdminScreen extends StatefulWidget {
  const PeopleAdminScreen({super.key, this.initialFilter = 'all'});
  final String initialFilter;
  @override
  State<PeopleAdminScreen> createState() => _PeopleAdminScreenState();
}

class _PeopleAdminScreenState extends State<PeopleAdminScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  late String _filter = widget.initialFilter;
  String _tier = '';
  DateTimeRange? _joined;
  List<Map<String, dynamic>> _rows = [];
  int _total = 0;
  String _note = '';
  String _source = '';
  bool _loading = true;
  bool _more = false;
  Object? _err;
  bool _local = false;

  static const _filters = {
    'all': 'Everyone',
    'online': 'Online now',
    'today': 'Seen 24h',
    'plan': 'Subscribers',
    'expired': 'Expired',
    'blocked': 'Blocked',
    'helper': 'Helpers',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  Map<String, dynamic> _body(int offset) => {
        'q': _q.text.trim(),
        'filter': _filter,
        'tier': _tier,
        'offset': offset,
        'limit': 40,
        if (_joined != null) 'joinedFrom': _joined!.start.millisecondsSinceEpoch,
        if (_joined != null) 'joinedTo': _joined!.end.add(const Duration(days: 1)).millisecondsSinceEpoch,
      };

  Future<void> _load({bool append = false}) async {
    setState(() {
      if (!append) _loading = true;
      _more = append;
      _err = null;
    });
    try {
      final r = await AdminData.run('users', _body(append ? _rows.length : 0));
      final rows = ((r['rows'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() {
        _rows = append ? [..._rows, ...rows] : rows;
        _total = (r['total'] as num?)?.toInt() ?? rows.length;
        _note = '${r['note'] ?? ''}';
        _source = '${r['source'] ?? ''}';
        _local = r['local'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _more = false;
        });
      }
    }
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _load);
  }

  Future<void> _pickJoined() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _joined,
      builder: (ctx, child) => Theme(data: adminTheme(), child: child!),
    );
    if (r == null) return;
    setState(() => _joined = r);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Members',
      title: 'People',
      actions: [
        IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: kGold)),
      ],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: Column(children: [
          TextField(
            controller: _q,
            onChanged: _search,
            onSubmitted: (_) => _load(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: kGold),
              hintText: 'Name, email, uid or phone',
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: kDim),
                      onPressed: () {
                        _q.clear();
                        _load();
                      }),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in _filters.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Pill(e.value, dense: true, selected: _filter == e.key, onTap: () {
                    setState(() => _filter = e.key);
                    _load();
                  }),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Pill(_joined == null ? 'Joined: any' : 'Joined ${fmtDate(_joined!.start)} – ${fmtDate(_joined!.end)}',
                    icon: Icons.date_range_rounded, dense: true, selected: _joined != null, onTap: _pickJoined),
              ),
              if (_joined != null)
                Pill('Clear dates', dense: true, onTap: () {
                  setState(() => _joined = null);
                  _load();
                }),
            ]),
          ),
          if (_filter == 'plan') ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Padding(padding: const EdgeInsets.only(right: 6), child: Pill('All plans', dense: true, selected: _tier.isEmpty, onTap: () {
                  setState(() => _tier = '');
                  _load();
                })),
                for (final t in kTiers.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Pill(t.value, dense: true, color: kTierColors[t.key]!, selected: _tier == t.key, onTap: () {
                      setState(() => _tier = t.key);
                      _load();
                    }),
                  ),
              ]),
            ),
          ],
        ]),
      ),
      body: _loading
          ? const OrbLoading(label: 'Finding people…')
          : _err != null
              ? AdminProblem(error: _err!, onRetry: _load)
              : RefreshIndicator(
                  color: kGold,
                  onRefresh: () async {
                    AdminData.retryServer();
                    await _load();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
                    itemCount: _rows.length + 2,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (_local) MissingSecrets(AdminData.serverMissing, what: 'Admin server is off — searching Firestore profiles in the app. For every account, set:'),
                            Text('${fmtNum(_total)} ${_total == 1 ? 'person' : 'people'} · from ${_source == 'auth' ? 'Firebase Auth + profiles' : 'Firestore profiles'}',
                                style: const TextStyle(color: kDim, fontSize: 12)),
                            if (_note.isNotEmpty && !_local) Text(_note, style: const TextStyle(color: kFaint, fontSize: 11)),
                          ]),
                        );
                      }
                      if (i == _rows.length + 1) {
                        if (_rows.isEmpty) return const EmptyNote('Nobody matches.', icon: Icons.person_search_rounded);
                        if (_rows.length >= _total) return const SizedBox(height: 20);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                              child: _more
                                  ? const CircularProgressIndicator(color: kGold)
                                  : Pill('Load more (${_total - _rows.length} left)', onTap: () => _load(append: true))),
                        );
                      }
                      return _PersonTile(_rows[i - 1], onChanged: _load);
                    },
                  ),
                ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.r, {required this.onChanged});
  final Map<String, dynamic> r;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final plan = (r['plan'] as Map?) ?? const {};
    final name = '${r['name'] ?? ''}'.trim();
    final email = '${r['email'] ?? ''}';
    final restr = (r['restrictions'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: () async {
          await pushAdmin(context, PersonAdminScreen(uid: '${r['uid']}', seed: r));
          onChanged();
        },
        child: Row(children: [
          Avatar(name: name.isNotEmpty ? name : email, photo: '${r['photo'] ?? ''}', online: r['online'] == true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isNotEmpty ? name : (email.isNotEmpty ? email : 'No name yet'),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
              Text(email.isNotEmpty && name.isNotEmpty ? email : '${r['uid']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5)),
              const SizedBox(height: 5),
              Wrap(spacing: 5, runSpacing: 4, children: [
                Tag('${plan['name'] ?? 'Free'}', color: plan['active'] == true ? (kTierColors[plan['tier']] ?? kGold) : kFaint),
                if (r['blocked'] == true || r['disabled'] == true) const Tag('Blocked', color: kRose, icon: Icons.block_rounded),
                if (r['helper'] == true) const Tag('Helper', color: kSky),
                if (restr.isNotEmpty) Tag('${restr.length} restricted', color: kAmber),
                for (final p in ((r['providers'] as List?) ?? const []).take(2)) Tag('$p'.replaceAll('.com', ''), color: kFaint),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(r['online'] == true ? 'online' : fmtAgo(r['lastSeen']),
                style: TextStyle(color: r['online'] == true ? kMint : kFaint, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('joined ${fmtDate(r['createdAt'])}', style: const TextStyle(color: kFaint, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}
