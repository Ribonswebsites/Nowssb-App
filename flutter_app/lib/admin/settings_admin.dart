/// Settings — the switches every app reads live from `config/app`:
/// force update (remote minimum build, on top of update-policy.json),
/// maintenance (banner or blocking screen), feature flags; plus the store
/// products, helper roles, server status and the full audit log.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_update.dart';
import '../data/billing_config.dart';
import '../data/play_subscriptions.dart';
import '../data/store_catalog.dart';
import '../data/store_prices.dart';
import 'admin_log.dart';
import 'admin_api.dart';
import 'admin_data.dart';
import 'admin_kit.dart';
import 'admin_state.dart';
import 'config_store.dart';
import 'people_admin.dart';

/// Flags the app checks (AppControl.flag). Unknown = on.
const kKnownFlags = {
  'earn': 'Earn program (payouts, referrals, rewards)',
  'gifts': 'Gifts (send / open)',
  'community': 'Community posting',
  'requests': 'Word requests',
};

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});
  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  Map<String, dynamic>? _cfg;
  final _minBuild = TextEditingController();
  final _updateMsg = TextEditingController();
  final _updateUrl = TextEditingController();
  final _mTitle = TextEditingController();
  final _mMsg = TextEditingController();
  final _newFlag = TextEditingController();
  bool _mOn = false;
  bool _mBlock = false;
  Map<String, bool> _flags = {};
  String _busy = '';
  Map<String, dynamic>? _health;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.doc('config/app').get().then((s) {
      final d = s.data() ?? {};
      final m = (d['maintenance'] as Map?) ?? const {};
      if (!mounted) return;
      setState(() {
        _cfg = d;
        _minBuild.text = '${d['minBuild'] ?? 0}';
        _updateMsg.text = '${d['updateMessage'] ?? ''}';
        _updateUrl.text = '${d['updateUrl'] ?? ''}';
        _mOn = m['on'] == true;
        _mBlock = m['blocking'] == true;
        _mTitle.text = '${m['title'] ?? ''}';
        _mMsg.text = '${m['message'] ?? ''}';
        _flags = {for (final k in kKnownFlags.keys) k: true};
        if (d['flags'] is Map) {
          for (final e in (d['flags'] as Map).entries) {
            if (e.value is bool) _flags['${e.key}'] = e.value as bool;
          }
        }
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _cfg = {'_error': '$e'});
    });
    AdminApi.health().then((h) {
      if (mounted) setState(() => _health = h);
    });
  }

  @override
  void dispose() {
    for (final c in [_minBuild, _updateMsg, _updateUrl, _mTitle, _mMsg, _newFlag]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String what, Map<String, dynamic> patch, String label) async {
    setState(() => _busy = what);
    try {
      await saveConfig('app', patch, label: label);
      if (mounted) adminSnack(context, 'Saved — every app has it now.');
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return AdminPage(
      eyebrow: 'Control',
      title: 'Settings',
      body: cfg == null
          ? const OrbLoading(label: 'Reading config/app…')
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 80), children: [
              if (cfg['_error'] != null) Text('${cfg['_error']}', style: const TextStyle(color: kAmber, fontSize: 12)),
              // ── server
              const SectionHead('Server', 'nowssb.com admin API'),
              _ServerCard(health: _health),
              // ── force update
              const SectionHead('Force update', 'Minimum build'),
              Glass(
                radius: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  KV('This phone', 'build ${NwsbAppUpdate.currentBuild}'),
                  KV('Latest (manifest)', NwsbUpdater.instance.available == null ? 'not checked yet' : 'build ${NwsbUpdater.instance.available!.build} · min ${NwsbUpdater.instance.available!.minBuild}'),
                  const Text('update-policy.json (GitHub) still applies; this switch works live without a release. Builds below it see a full-screen “Update NowssB”.',
                      style: TextStyle(color: kFaint, fontSize: 11)),
                  const SizedBox(height: 10),
                  TextField(controller: _minBuild, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Minimum build (0 = off)')),
                  const SizedBox(height: 8),
                  TextField(controller: _updateMsg, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message (optional)')),
                  const SizedBox(height: 8),
                  TextField(controller: _updateUrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Download page (optional, default nowssb.com)')),
                  const SizedBox(height: 12),
                  GoldButton('Save force update', icon: Icons.system_update_rounded, busy: _busy == 'update', onTap: () async {
                    final n = int.tryParse(_minBuild.text.trim()) ?? 0;
                    if (n > NwsbAppUpdate.currentBuild) {
                      final ok = await confirmAction(context, 'Force builds below $n to update?', 'This phone is build ${NwsbAppUpdate.currentBuild}, so it will be asked too (admins included).', yes: 'Force update');
                      if (!ok) return;
                    }
                    await _save('update', {'minBuild': n, 'updateMessage': _updateMsg.text.trim(), 'updateUrl': _updateUrl.text.trim()}, 'minBuild $n');
                  }),
                ]),
              ),
              // ── maintenance
              const SectionHead('Maintenance', 'Banner or blocking screen'),
              Glass(
                radius: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: _mOn, activeThumbColor: kGold, onChanged: (v) => setState(() => _mOn = v), title: const Text('Maintenance on', style: TextStyle(color: Colors.white))),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _mBlock,
                    activeThumbColor: kRose,
                    onChanged: (v) => setState(() => _mBlock = v),
                    title: const Text('Block the app (admins still get in)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Off = a banner at the top only', style: TextStyle(color: kDim, fontSize: 11.5)),
                  ),
                  TextField(controller: _mTitle, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title (default “Back in a moment”)')),
                  const SizedBox(height: 8),
                  TextField(controller: _mMsg, maxLines: 3, minLines: 1, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Message')),
                  const SizedBox(height: 12),
                  GoldButton(_mOn ? 'Turn on maintenance' : 'Save (off)', icon: Icons.construction_rounded, color: _mOn && _mBlock ? kRose : kGold, busy: _busy == 'maint', onTap: () async {
                    if (_mOn && _mBlock) {
                      final ok = await confirmAction(context, 'Block every app?', 'Members see the maintenance screen until you turn it off.', yes: 'Block');
                      if (!ok) return;
                    }
                    await _save('maint', {
                      'maintenance': {'on': _mOn, 'blocking': _mBlock, 'title': _mTitle.text.trim(), 'message': _mMsg.text.trim()},
                    }, _mOn ? (_mBlock ? 'maintenance blocking' : 'maintenance banner') : 'maintenance off');
                  }),
                ]),
              ),
              // ── flags
              const SectionHead('Feature flags', 'Switch features live'),
              Glass(
                radius: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in _flags.entries)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: e.value,
                      activeThumbColor: kMint,
                      onChanged: (v) => setState(() => _flags[e.key] = v),
                      title: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      subtitle: Text(kKnownFlags[e.key] ?? 'Custom flag (AppControl.flag(\'${e.key}\'))', style: const TextStyle(color: kDim, fontSize: 11.5)),
                    ),
                  Row(children: [
                    Expanded(child: TextField(controller: _newFlag, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'New flag name'))),
                    IconButton(
                      onPressed: () {
                        final k = _newFlag.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
                        if (k.isEmpty) return;
                        setState(() {
                          _flags[k] = true;
                          _newFlag.clear();
                        });
                      },
                      icon: const Icon(Icons.add_circle_rounded, color: kGold),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  GoldButton('Save flags', icon: Icons.flag_rounded, busy: _busy == 'flags', onTap: () => _save('flags', {'flags': _flags}, 'flags')),
                ]),
              ),
              // ── store
              const SectionHead('Store', 'Products & prices'),
              const _StoreCard(),
              const _ContentPricesCard(),
              // ── roles
              const SectionHead('Team', 'Admins and helpers'),
              Glass(
                radius: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  KV('You', '${AdminState.instance.email ?? AdminState.instance.uid} · ${AdminState.instance.how}'),
                  const Text('Admins are Firestore admins/{uid} documents (not listable by design). Add one with tools/firebase/admin-tool.mjs mark-admin <uid>.',
                      style: TextStyle(color: kFaint, fontSize: 11)),
                  const SizedBox(height: 10),
                  Pill('Helpers — open the list', icon: Icons.support_agent_rounded, onTap: () => pushAdmin(context, const PeopleAdminScreen(initialFilter: 'helper'))),
                  const SizedBox(height: 4),
                  const Text('Mark or remove a helper from their profile in People.', style: TextStyle(color: kFaint, fontSize: 11)),
                ]),
              ),
              // ── audit
              const SectionHead('Audit', 'Every change'),
              Glass(
                radius: 22,
                onTap: () => pushAdmin(context, const AuditLogScreen()),
                child: const Row(children: [
                  Icon(Icons.history_rounded, color: kGold),
                  SizedBox(width: 10),
                  Expanded(child: Text('Open the full audit log — admin actions, UI Editor history, settings versions', style: TextStyle(color: Colors.white, fontSize: 13))),
                  Icon(Icons.chevron_right_rounded, color: kFaint),
                ]),
              ),
            ]),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.health});
  final Map<String, dynamic>? health;
  @override
  Widget build(BuildContext context) {
    final h = health;
    final missing = ((h?['missing'] as List?) ?? const []).map((e) => '$e').toList();
    final live = h != null && h.isNotEmpty;
    return Glass(
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(live ? (missing.isEmpty ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded) : Icons.cloud_off_rounded, color: live ? (missing.isEmpty ? kMint : kAmber) : kRose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                h == null
                    ? 'Checking…'
                    : !live
                        ? 'Admin API not reachable (not deployed yet?). The console works from Firestore meanwhile.'
                        : missing.isEmpty
                            ? 'All server secrets are set.'
                            : 'Admin API is live; some secrets are missing.',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ]),
        if (missing.isNotEmpty) ...[const SizedBox(height: 10), MissingSecrets(missing, what: 'Set in Cloudflare Pages → Settings → Variables and secrets (Production):')],
        if (AdminData.serverLive == false) const Text('This session is using in-app Firestore mode.', style: TextStyle(color: kFaint, fontSize: 11)),
      ]),
    );
  }
}

class _StoreCard extends StatefulWidget {
  const _StoreCard();
  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final ps = PlaySubscriptions.instance;
    return Glass(
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final p in kPlayPlans)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: kTierColors[p.tier] ?? kGold, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${p.name} · ${p.yearly ? 'yearly' : 'monthly'}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(p.productId, style: const TextStyle(color: kFaint, fontSize: 10.5)),
                ]),
              ),
              Text(ps.priceFor(p.productId) ?? 'price from Play', style: TextStyle(color: ps.priceFor(p.productId) == null ? kFaint : kGold, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
          ),
        const SizedBox(height: 8),
        const Text('Prices are Google Play’s, in this phone’s currency. Change them in Play Console → Monetize → Subscriptions.', style: TextStyle(color: kFaint, fontSize: 11)),
        const SizedBox(height: 8),
        Pill(_loading ? 'Loading…' : 'Load prices from Play', icon: Icons.storefront_rounded, dense: true, onTap: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await ps.loadProducts();
                } catch (_) {}
                if (mounted) setState(() => _loading = false);
              }),
      ]),
    );
  }
}

/// Word / meaning / signature / ebook prices → `config/store`
/// `{defaults: {kind: ₹}, items: {itemId: ₹}}`. Every card, the product page
/// and Checkout read it live (StorePrices); Checkout pays the total through
/// a Google Play price tier, so only Play price points are offered here.
class _ContentPricesCard extends StatefulWidget {
  const _ContentPricesCard();
  @override
  State<_ContentPricesCard> createState() => _ContentPricesCardState();
}

class _ContentPricesCardState extends State<_ContentPricesCard> {
  final _id = TextEditingController();
  String _kind = 'word';
  int? _price;
  String _busy = '';

  static const _kindNames = {'word': 'Words', 'meaning': 'Meanings', 'signature': 'Signature', 'ebook': 'Ebooks'};

  @override
  void initState() {
    super.initState();
    StorePrices.instance.addListener(_tick);
  }

  @override
  void dispose() {
    StorePrices.instance.removeListener(_tick);
    _id.dispose();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _run(String what, Future<void> Function() f, String ok) async {
    setState(() => _busy = what);
    try {
      await f();
      if (mounted) adminSnack(context, ok);
    } catch (e) {
      if (mounted) adminSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _removeItems(List<String> ids, String label) async {
    if (ids.isEmpty) return;
    await FirebaseFirestore.instance.doc('config/store').update({
      for (final id in ids) FieldPath(['items', id]): FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await adminLog('config.store', label, {'removed': ids.join(',')});
  }

  List<String> get _saleIds => [
        for (final c in kRmCategories)
          if (c.id == 'off50')
            for (final w in c.words) 'word:${w.word.toLowerCase()}',
      ];

  Widget _tierPick(String kind, int value, ValueChanged<int> onPick) {
    final tiers = kContentPriceTiers[kind] ?? const <int>[];
    final v = tiers.contains(value) ? value : contentTierFor(kind, value);
    return DropdownButton<int>(
      value: tiers.contains(v) ? v : null,
      dropdownColor: const Color(0xFF15151A),
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: 13),
      items: [for (final t in tiers) DropdownMenuItem(value: t, child: Text('₹$t'))],
      onChanged: (t) => t == null ? null : onPick(t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = StorePrices.instance;
    final items = sp.items.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final saleOn = _saleIds.any(sp.items.containsKey);
    return Glass(
      radius: 22,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Content prices (Google Play)', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Default price for each kind, then per-item prices. Saved to config/store; every app updates live.', style: TextStyle(color: kFaint, fontSize: 11)),
        const SizedBox(height: 8),
        for (final k in _kindNames.keys)
          Row(children: [
            Expanded(child: Text('${_kindNames[k]} · default', style: const TextStyle(color: Colors.white, fontSize: 13))),
            _tierPick(k, sp.defaultFor(k).toInt(), (t) => _run('d$k', () => saveConfig('store', {'defaults': {k: t}}, label: '${_kindNames[k]} default ₹$t'), 'Saved — ${_kindNames[k]} now ₹$t.')),
          ]),
        const Divider(color: Color(0x22FFFFFF), height: 22),
        const Text('Per-item price', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [
          DropdownButton<String>(
            value: _kind,
            dropdownColor: const Color(0xFF15151A),
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: [for (final k in _kindNames.keys) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (k) => setState(() {
              _kind = k ?? 'word';
              _price = null;
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _id,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(isDense: true, hintText: 'word / book id, e.g. phoenix', hintStyle: TextStyle(color: kFaint, fontSize: 12)),
            ),
          ),
          _tierPick(_kind, _price ?? sp.defaultFor(_kind).toInt(), (t) => setState(() => _price = t)),
        ]),
        const SizedBox(height: 8),
        GoldButton('Set item price', icon: Icons.sell_rounded, busy: _busy == 'item', onTap: () {
          final raw = _id.text.trim().toLowerCase();
          if (raw.isEmpty) return;
          final id = raw.contains(':') ? raw : '$_kind:$raw';
          final t = _price ?? sp.defaultFor(_kind).toInt();
          _run('item', () => saveConfig('store', {'items': {id: t}}, label: '$id ₹$t'), 'Saved — $id is ₹$t.');
        }),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final e in items)
            Row(children: [
              Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
              Text('₹${e.value}', style: const TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: 12.5)),
              IconButton(
                tooltip: 'Back to the default',
                icon: const Icon(Icons.close_rounded, color: kFaint, size: 18),
                onPressed: () => _run('rm', () => _removeItems([e.key], '${e.key} price removed'), '${e.key} uses the default again.'),
              ),
            ]),
        ],
        const Divider(color: Color(0x22FFFFFF), height: 22),
        Text(saleOn ? '50% OFF row sale is ON' : '50% OFF row sale', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        const Text('Prices every word in the Atelier “50% OFF” row at half the word default (nearest Play price). Cards show the default struck through.', style: TextStyle(color: kFaint, fontSize: 11)),
        const SizedBox(height: 8),
        Pill(saleOn ? 'End the sale' : 'Start the sale', icon: Icons.local_offer_rounded, dense: true, onTap: _busy.isNotEmpty
            ? null
            : () => saleOn
                ? _run('sale', () => _removeItems(_saleIds, '50% OFF sale ended'), 'Sale ended.')
                : _run('sale', () {
                    final half = contentTierFor('word', sp.defaultFor('word') / 2);
                    return saveConfig('store', {'items': {for (final id in _saleIds) id: half}}, label: '50% OFF sale ₹$half');
                  }, 'Sale is live.')),
      ]),
    );
  }
}

/// adminLog + ui_history + configHistory, newest first, filterable.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _src = 'adminLog';
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection(_src).orderBy('at', descending: true).limit(300);
    return AdminPage(
      eyebrow: 'Audit',
      title: 'Audit log',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Column(children: [
          Row(children: [
            for (final s in const {'adminLog': 'Admin actions', 'ui_history': 'UI Editor', 'configHistory': 'Settings'}.entries)
              Padding(padding: const EdgeInsets.only(right: 6), child: Pill(s.value, dense: true, selected: _src == s.key, onTap: () => setState(() => _src = s.key))),
          ]),
          const SizedBox(height: 6),
          TextField(controller: _q, onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded, color: kGold), hintText: 'Filter')),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey(_src),
        stream: q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return AdminProblem(error: snap.error!);
          if (!snap.hasData) return const OrbLoading();
          final needle = _q.text.trim().toLowerCase();
          final docs = snap.data!.docs.where((d) => needle.isEmpty || d.data().toString().toLowerCase().contains(needle)).toList();
          if (docs.isEmpty) return const EmptyNote('Nothing yet.');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final title = switch (_src) {
                'ui_history' => '${d['kind'] ?? ''} · ${d['page'] ?? ''} · ${d['target'] ?? ''}',
                'configHistory' => 'config/${d['doc'] ?? ''} v${d['version'] ?? ''} · ${d['label'] ?? ''}',
                _ => '${d['summary'] ?? d['action'] ?? ''} · ${d['target'] ?? ''}',
              };
              final who = '${d['email'] ?? d['by'] ?? d['uid'] ?? ''}';
              final detail = switch (_src) {
                'configHistory' => 'changed: ${(d['changed'] as List?)?.join(', ') ?? ''}',
                'ui_history' => '${d['note'] ?? ''}',
                _ => d['detail'] is Map ? (d['detail'] as Map).entries.where((e) => '${e.value}'.isNotEmpty).map((e) => '${e.key}: ${e.value}').join(' · ') : '',
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Glass(
                  radius: 14,
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Text([who, fmtDate(d['at'], time: true), if (d['via'] != null) 'via ${d['via']}'].where((e) => e.isNotEmpty).join(' · '), style: const TextStyle(color: kFaint, fontSize: 10.5)),
                    if (detail.isNotEmpty) Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
