/// Notifications — phone push to everyone, a plan, free members or one
/// person (FCM HTTP v1 from /api/admin/broadcast; pages through every
/// device), plus the in-app announcement banner every app reads live
/// from `config/app.announcement`.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_control.dart';
import '../widgets/app_control_layer.dart';
import 'admin_api.dart';
import 'admin_data.dart';
import 'admin_kit.dart';
import 'config_store.dart';

class BroadcastAdminScreen extends StatefulWidget {
  const BroadcastAdminScreen({super.key});
  @override
  State<BroadcastAdminScreen> createState() => _BroadcastAdminScreenState();
}

class _BroadcastAdminScreenState extends State<BroadcastAdminScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _uid = TextEditingController();
  final _route = TextEditingController();
  String _audience = 'all';
  String _tier = '';
  bool _sending = false;
  String _progress = '';
  List<String> _missing = const [];

  @override
  void dispose() {
    for (final c in [_title, _body, _uid, _route]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty) {
      adminSnack(context, 'A title is required.', error: true);
      return;
    }
    final who = switch (_audience) {
      'all' => 'every device',
      'plan' => _tier.isEmpty ? 'all subscribers' : '${kTiers[_tier]} subscribers',
      'free' => 'free members',
      _ => 'this person',
    };
    final ok = await confirmAction(context, 'Send to $who?', '“${_title.text.trim()}”\n${_body.text.trim()}', yes: 'Send push');
    if (!ok) return;
    setState(() {
      _sending = true;
      _progress = 'Starting…';
      _missing = const [];
    });
    var sent = 0, failed = 0, skipped = 0, removed = 0, pages = 0;
    String cursor = '';
    String id = '';
    try {
      do {
        final r = await AdminData.run('broadcast', {
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'audience': _audience,
          'tier': _tier,
          'uid': _uid.text.trim(),
          'route': _route.text.trim(),
          if (cursor.isNotEmpty) 'cursor': cursor,
          if (id.isNotEmpty) 'broadcastId': id,
        });
        id = '${r['broadcastId'] ?? id}';
        sent += (r['sent'] as num? ?? 0).toInt();
        failed += (r['failed'] as num? ?? 0).toInt();
        skipped += (r['skipped'] as num? ?? 0).toInt();
        removed += (r['removed'] as num? ?? 0).toInt();
        cursor = '${r['next'] ?? ''}';
        pages++;
        if (mounted) setState(() => _progress = 'Sent $sent · failed $failed · skipped $skipped${cursor.isNotEmpty ? ' · next page…' : ''}');
      } while (cursor.isNotEmpty && pages < 500);
      if (mounted) {
        setState(() => _progress = 'Done: sent $sent, failed $failed, not in audience $skipped, dead tokens removed $removed.');
        adminSnack(context, 'Push sent to $sent devices.');
      }
    } on AdminApiException catch (e) {
      if (mounted) {
        setState(() {
          _progress = e.message;
          _missing = e.missing;
        });
        adminSnack(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) setState(() => _progress = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Reach people',
      title: 'Notifications',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 80), children: [
        const SectionHead('In the app', 'Announcement banner'),
        const _AnnouncementEditor(),
        const SectionHead('On the phone', 'Push notification'),
        Glass(
          radius: 24,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final a in const {'all': 'Everyone', 'plan': 'Subscribers', 'free': 'Free members', 'user': 'One person'}.entries)
                Pill(a.value, selected: _audience == a.key, dense: true, onTap: () => setState(() => _audience = a.key)),
            ]),
            if (_audience == 'plan') ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                Pill('All plans', dense: true, selected: _tier.isEmpty, onTap: () => setState(() => _tier = '')),
                for (final t in kTiers.entries) Pill(t.value, dense: true, color: kTierColors[t.key]!, selected: _tier == t.key, onTap: () => setState(() => _tier = t.key)),
              ]),
            ],
            if (_audience == 'user') ...[
              const SizedBox(height: 8),
              TextField(controller: _uid, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'User id (from People)')),
            ],
            const SizedBox(height: 10),
            TextField(controller: _title, maxLength: 80, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _body, maxLength: 400, maxLines: 4, minLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message')),
            TextField(controller: _route, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Open on tap (optional, e.g. word:om)')),
            const SizedBox(height: 12),
            MissingSecrets(_missing, what: 'Push is off until these are set in Cloudflare (Production):'),
            Row(children: [
              GoldButton('Send push', icon: Icons.send_rounded, busy: _sending, onTap: _send),
              const SizedBox(width: 10),
              Expanded(child: Text(_progress, style: const TextStyle(color: kDim, fontSize: 11.5))),
            ]),
          ]),
        ),
        const SectionHead('History', 'Sent pushes'),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('broadcasts').orderBy('at', descending: true).limit(30).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}', style: const TextStyle(color: kFaint, fontSize: 11));
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) return const EmptyNote('No pushes sent from the console yet.', icon: Icons.notifications_none_rounded);
            return Column(children: [
              for (final d in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Glass(
                    radius: 16,
                    padding: const EdgeInsets.all(11),
                    child: Row(children: [
                      const Icon(Icons.campaign_rounded, color: kGold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${d.data()['title'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${d.data()['audience'] ?? ''}${'${d.data()['tier'] ?? ''}'.isNotEmpty ? ' · ${d.data()['tier']}' : ''} · ${d.data()['by'] ?? ''} · ${fmtDate(d.data()['at'], time: true)}',
                              style: const TextStyle(color: kFaint, fontSize: 10.5)),
                        ]),
                      ),
                      Text('${d.data()['sent'] ?? 0} sent', style: const TextStyle(color: kMint, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _AnnouncementEditor extends StatefulWidget {
  const _AnnouncementEditor();
  @override
  State<_AnnouncementEditor> createState() => _AnnouncementEditorState();
}

class _AnnouncementEditorState extends State<_AnnouncementEditor> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _cta = TextEditingController();
  final _link = TextEditingController();
  bool _on = false;
  bool _dismissible = true;
  String _audience = 'all';
  String _tone = 'gold';
  DateTime? _until;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.doc('config/app').get().then((s) {
      final a = (s.data()?['announcement'] as Map?) ?? const {};
      if (!mounted) return;
      setState(() {
        _on = a['on'] == true;
        _title.text = '${a['title'] ?? ''}';
        _body.text = '${a['body'] ?? ''}';
        _cta.text = '${a['cta'] ?? ''}';
        _link.text = '${a['link'] ?? ''}';
        _dismissible = a['dismissible'] != false;
        _audience = '${a['audience'] ?? 'all'}';
        _tone = '${a['tone'] ?? 'gold'}';
        final u = toMsAny(a['until']);
        _until = u > 0 ? DateTime.fromMillisecondsSinceEpoch(u) : null;
        _loaded = true;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _cta, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _value => {
        'on': _on,
        'id': '${DateTime.now().millisecondsSinceEpoch}',
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'cta': _cta.text.trim(),
        'link': _link.text.trim(),
        'dismissible': _dismissible,
        'audience': _audience,
        'tone': _tone,
        'until': _until?.millisecondsSinceEpoch ?? 0,
      };

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await saveConfig('app', {'announcement': _value}, label: _on ? 'announcement on' : 'announcement off');
      if (mounted) adminSnack(context, _on ? 'Banner is live in every app.' : 'Banner is off.');
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 120, child: OrbLoading(size: 40));
    final preview = AppAnnouncement.fromMap(_value);
    return Glass(
      radius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _on,
          activeThumbColor: kGold,
          onChanged: (v) => setState(() => _on = v),
          title: const Text('Show the banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: const Text('Appears at the top of every screen, live', style: TextStyle(color: kDim, fontSize: 11.5)),
        ),
        TextField(controller: _title, onChanged: (_) => setState(() {}), maxLength: 60, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title')),
        TextField(controller: _body, onChanged: (_) => setState(() {}), maxLength: 200, maxLines: 3, minLines: 1, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Text')),
        Row(children: [
          Expanded(child: TextField(controller: _cta, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Button (optional)'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _link, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Link (https://…)'))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in const {'all': 'Everyone', 'free': 'Free only', 'subscribers': 'Subscribers'}.entries)
            Pill(a.value, dense: true, selected: _audience == a.key, onTap: () => setState(() => _audience = a.key)),
          for (final t in const ['gold', 'mint', 'rose', 'sky'])
            Pill(t, dense: true, selected: _tone == t, onTap: () => setState(() => _tone = t)),
          Pill(_until == null ? 'No end date' : 'Until ${fmtDate(_until)}', icon: Icons.event_rounded, dense: true, selected: _until != null, onTap: () async {
            final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: DateTime.now().add(const Duration(days: 7)),
                builder: (c, w) => Theme(data: adminTheme(), child: w!));
            setState(() => _until = d == null ? null : DateTime(d.year, d.month, d.day, 23, 59));
          }),
          Pill(_dismissible ? 'Can close' : 'Stays', dense: true, selected: _dismissible, onTap: () => setState(() => _dismissible = !_dismissible)),
        ]),
        const SizedBox(height: 12),
        const Text('PREVIEW', style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
        const SizedBox(height: 6),
        AnnouncementBanner(a: preview, onClose: () {}),
        const SizedBox(height: 12),
        GoldButton(_on ? 'Publish banner' : 'Save (off)', icon: Icons.campaign_rounded, busy: _busy, onTap: _save),
      ]),
    );
  }
}
