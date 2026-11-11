/// Coins are never credited silently. A real activity (open the app, word of
/// the day, a full listen, a share, a page visit…) only *offers* its coins:
/// a gold glass card asks "Collect". Only that tap calls the server
/// (reportAction), then the coins fly into the wallet and today's bar shows
/// what is collected and what is still left today.
///
/// Uncollected offers wait on this phone (SharedPreferences) for the rest of
/// the IST day; the server's daily limits are per day, so an offer from an
/// earlier day is dropped instead of being paid against today.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/quotes_live.dart' show DailyQuoteGate;
import '../../screens/splash.dart' show SplashGate;
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import '../../widgets/swipe_away.dart';
import 'economy_api.dart';
import 'reward_fx.dart' show coinsIn, playCoins;
import 'reward_overlay.dart';

/// One activity's coins waiting for a Collect tap.
class PendingEarn {
  const PendingEarn({required this.action, this.key = '', required this.coins, required this.title});
  final String action;
  final String key;
  final int coins;
  final String title;
  String get id => '$action:$key';
  Map<String, dynamic> toJson() => {'action': action, 'key': key, 'coins': coins, 'title': title};
  static PendingEarn fromJson(Map m) => PendingEarn(
        action: '${m['action'] ?? ''}',
        key: '${m['key'] ?? ''}',
        coins: (m['coins'] as num?)?.toInt() ?? 0,
        title: '${m['title'] ?? ''}',
      );
}

/// Today's coin picture, all from the server summary (no made-up numbers).
class CoinDay {
  const CoinDay({required this.collected, required this.left, required this.ceiling});
  final int collected;

  /// Coins still earnable today: the open daily activities, capped by what
  /// is left under the server's daily free-coin ceiling.
  final int left;
  final int ceiling;
  int get total => collected + left;
  double get fraction => total <= 0 ? 0 : (collected / total).clamp(0.0, 1.0);

  /// Null until the server summary has loaded.
  static CoinDay? fromSummary(Map<String, dynamic> summary, {int pending = 0}) {
    final today = summary['today'];
    if (today is! Map) return null;
    final collected = (today['freeCoins'] as num?)?.toInt();
    final ceiling = ((today['ceilingNow'] ?? today['ceiling']) as num?)?.toInt();
    if (collected == null || ceiling == null || ceiling <= 0) return null;
    var open = 0;
    for (final a in (today['actions'] as List?) ?? const []) {
      if (a is! Map || a['free'] == false) continue;
      final per = '${a['per'] ?? 'day'}';
      if (per != 'day' && per != 'key') continue;
      final limit = (a['limit'] as num?)?.toInt() ?? 1;
      final done = (a['done'] as num?)?.toInt() ?? 0;
      open += math.max(0, limit - done) * ((a['coins'] as num?)?.toInt() ?? 0);
    }
    final room = math.max(0, ceiling - collected);
    return CoinDay(collected: collected, left: math.min(room, math.max(open, pending)), ceiling: ceiling);
  }
}

class PendingCoins extends ChangeNotifier {
  PendingCoins._();
  static final instance = PendingCoins._();

  static const _prefsKey = 'nwsb_pending_coins_v1';

  /// The server's default amounts (functions/_lib/economy/config.js), used
  /// only for the card's label until the summary loads. The flight always
  /// uses what the server actually credited.
  static const _fallback = <String, (int, String)>{
    'open': (5, 'Open the app'),
    'ring_listen': (5, 'Practice Ring · listen'),
    'ring_say': (8, 'Practice Ring · say it aloud'),
    'ring_reflect': (12, 'Practice Ring · save or reflect'),
    'word_of_day': (10, 'Word of the day'),
    'sound_bath': (10, 'Sound Bath session'),
    'quote': (3, 'Read or share the daily quote'),
    'read_meaning': (8, 'Read one meaning to the end'),
    'explore': (2, 'Visit a program page'),
    'first_share': (15, 'First share of a word'),
    'echo_first_post': (10, 'First Echo Wall post'),
  };

  final List<PendingEarn> items = [];
  final Set<String> _handled = {}; // collected (or offered) today
  String _day = '';
  bool _loaded = false;
  Future<void>? _loading;
  bool _showing = false;
  bool busy = false;
  Timer? _debounce;
  Timer? _retry;
  int _retries = 0;

  /// Ids already put in front of the user this run (so "Later" is not asked
  /// again in a loop, but a reward that arrives while the card is up is).
  final Set<String> _shownIds = {};

  /// Tests: do not wait for the splash and the daily quote.
  @visibleForTesting
  static bool debugIgnoreGates = false;

  /// Tests: skip the overlay and storage timing.
  @visibleForTesting
  static bool Function()? debugAutoShow;

  int get total => items.fold(0, (s, e) => s + e.coins);

  static String today() {
    final n = DateTime.now().toUtc().add(const Duration(minutes: 330));
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// One load at a time: an offer and a show that start together used to
  /// both clear and refill the list, which could drop or double an offer.
  Future<void> _load() {
    if (_loaded && _day == today()) return Future<void>.value();
    return _loading ??= _doLoad().whenComplete(() => _loading = null);
  }

  Future<void> _doLoad() async {
    final d = today();
    if (_loaded && _day == d) return;
    _day = d;
    items.clear();
    _handled.clear();
    _shownIds.clear();
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw != null) {
        final m = jsonDecode(raw);
        if (m is Map && m['day'] == d) {
          for (final i in (m['items'] as List?) ?? const []) {
            if (i is Map) items.add(PendingEarn.fromJson(i));
          }
          _handled.addAll(((m['handled'] as List?) ?? const []).map((e) => '$e'));
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, jsonEncode({'day': _day, 'items': items.map((e) => e.toJson()).toList(), 'handled': _handled.toList()}));
    } catch (_) {}
  }

  @visibleForTesting
  Future<void> debugReset() async {
    items.clear();
    _handled.clear();
    _loaded = false;
    _loading = null;
    _showing = false;
    busy = false;
    _shownIds.clear();
    _retries = 0;
    _debounce?.cancel();
    _retry?.cancel();
  }

  Map? _serverAction(String action) {
    final acts = ((EconomyMirror.instance.summary['today'] as Map?)?['actions'] as List?) ?? const [];
    for (final a in acts) {
      if (a is Map && a['id'] == action) return a;
    }
    return null;
  }

  /// A real activity happened: hold its coins and ask the user to collect.
  /// Nothing is credited here.
  Future<void> offer(String action, {String? key}) async {
    await _load();
    final k = key ?? '';
    final id = '$action:$k';
    if (_handled.contains(id) || items.any((e) => e.id == id)) return;
    final server = _serverAction(action);
    if (server != null) {
      final limit = (server['limit'] as num?)?.toInt() ?? 1;
      final done = (server['done'] as num?)?.toInt() ?? 0;
      if (done >= limit) return; // already earned today on the server
    }
    final fb = _fallback[action];
    final coins = (server?['coins'] as num?)?.toInt() ?? fb?.$1 ?? 0;
    if (coins <= 0) return;
    items.add(PendingEarn(action: action, key: k, coins: coins, title: '${server?['title'] ?? fb?.$2 ?? 'NowssB activity'}'));
    _handled.add(id);
    await _save();
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () => unawaited(show()));
  }

  /// Resolves once the splash and the daily quote are out of the way (the
  /// card used to open underneath them and was never seen), or after a
  /// failsafe so it can never wait forever.
  Future<void> _whenClear() {
    bool clear() => debugIgnoreGates || (SplashGate.done.value && DailyQuoteGate.done.value);
    if (clear()) return Future<void>.value();
    final c = Completer<void>();
    late VoidCallback on;
    Timer? cap;
    void finish() {
      SplashGate.done.removeListener(on);
      DailyQuoteGate.done.removeListener(on);
      cap?.cancel();
      if (!c.isCompleted) c.complete();
    }
    on = () {
      if (clear()) finish();
    };
    SplashGate.done.addListener(on);
    DailyQuoteGate.done.addListener(on);
    cap = Timer(const Duration(seconds: 12), finish);
    return c.future;
  }

  void _retryLater() {
    if (RewardOverlay.quiet || _retries >= 40) return;
    _retries++;
    _retry?.cancel();
    _retry = Timer(const Duration(milliseconds: 600), () => unawaited(show()));
  }

  /// Shows the Collect card for everything waiting (no-op when empty).
  ///
  /// It always shows for an uncollected reward: if the screen is not ready
  /// (no navigator yet, splash or the daily quote still up) it waits and
  /// tries again instead of silently giving up. Coins move only on the
  /// Collect tap; Later and a dismissed card leave them waiting.
  Future<void> show() async {
    await _load();
    // Widget tests switch plays off: no gate waits or retries to leave behind.
    if (items.isEmpty || _showing || RewardOverlay.quiet) return;
    _showing = true;
    Future<int>? collecting;
    List<PendingEarn> shown = const [];
    var played = false;
    try {
      await _whenClear();
      if (items.isEmpty) return;
      shown = List.of(items);
      await RewardOverlay.enqueue((nav) async {
        played = true;
        _shownIds.addAll(shown.map((e) => e.id));
        await nav.push<bool>(RawDialogRoute<bool>(
          // Only Collect, Later or a swipe closes it: a stray tap on the
          // dim area must not make the reward vanish.
          barrierDismissible: false,
          barrierLabel: 'coins',
          barrierColor: const Color(0xCC03060C),
          transitionDuration: const Duration(milliseconds: 420),
          transitionBuilder: (context, a, _, child) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          pageBuilder: (context, _, __) => SwipeAway(
            onDismissed: () => Navigator.of(context).maybePop(false),
            child: Center(
              child: CoinOfferCard(
                items: shown,
                day: CoinDay.fromSummary(EconomyMirror.instance.summary, pending: shown.fold(0, (s, e) => s + e.coins)),
                onCollect: () {
                  // The bar and the flight start on this very tap; the
                  // server call runs alongside, never in front of them.
                  collecting ??= collectBatch(shown);
                  Navigator.of(context).pop(true);
                },
                onLater: () => Navigator.of(context).pop(false),
              ),
            ),
          ),
        ));
      });
    } finally {
      _showing = false;
    }
    if (!played) {
      // The overlay could not play (no navigator yet): try again soon.
      _retryLater();
      return;
    }
    _retries = 0;
    if (collecting != null) await collecting;
    // A reward that arrived while the card was open gets its own card.
    if (items.any((e) => !_shownIds.contains(e.id))) unawaited(show());
  }

  /// Credits everything waiting. Tests and the card's tap both land here.
  Future<int> collect() => collectBatch(List.of(items));

  /// The user tapped Collect for [batch]: show the top coin bar and the
  /// flight at once with the coins that were offered, and credit them on the
  /// server in parallel. Returns the coins the server actually credited.
  Future<int> collectBatch(List<PendingEarn> batch) async {
    await _load();
    final todo = [for (final e in batch) if (items.any((x) => x.id == e.id)) e];
    if (busy || todo.isEmpty) return 0;
    busy = true;
    notifyListeners();
    final offered = todo.fold(0, (s, e) => s + e.coins);
    final mirror = EconomyMirror.instance;
    final before = mirror.coins;
    final day0 = CoinDay.fromSummary(mirror.summary, pending: offered);
    final dayAfter = day0 == null
        ? null
        : CoinDay(collected: day0.collected + offered, left: math.max(0, day0.left - offered), ceiling: day0.ceiling);
    HapticFeedback.mediumImpact();
    // Immediate: not queued behind anything, not behind the network.
    final flight = playCoins(null, offered, balanceAfter: before + offered, day: dayAfter, immediate: true);
    var gained = 0;
    var kept = 0;
    try {
      for (final e in todo) {
        try {
          final r = await EconomyApi.call('reportAction', {'action': e.action, if (e.key.isNotEmpty) 'key': e.key});
          gained += coinsIn(r);
          items.removeWhere((x) => x.id == e.id);
        } on EconomyException catch (x) {
          // Offline / switching on: keep it waiting. Anything else (already
          // earned, limit, unknown) is settled by the server: drop it.
          if (x.code == 'offline' || x.code == 'timeout' || x.code == 'not-configured' || x.code == 'unauthenticated') {
            kept += e.coins;
            continue;
          }
          items.removeWhere((x) => x.id == e.id);
        }
      }
      await _save();
      // Today's numbers refresh in the background, after the animation has
      // already started.
      unawaited(EconomyApi.call('summary').then((_) {}, onError: (_) {}));
      if (gained < offered) _tell(kept > 0 ? 'No connection. Your $kept coins are saved to collect later.' : 'Those coins were already collected today.');
    } finally {
      busy = false;
      notifyListeners();
    }
    await flight;
    return gained;
  }

  void _tell(String text) {
    final ctx = RewardOverlay.navigatorKey.currentContext;
    final m = ctx == null ? null : ScaffoldMessenger.maybeOf(ctx);
    m?.showSnackBar(SnackBar(content: Text(text)));
  }
}

/// The Collect card: black glass with the gold hairline of the
/// Breath · Stillness · Awakening cards, the coins on offer, today's bar
/// and the Collect button.
class CoinOfferCard extends StatefulWidget {
  const CoinOfferCard({super.key, required this.items, required this.day, required this.onCollect, this.onLater});
  final List<PendingEarn> items;
  final CoinDay? day;
  final VoidCallback onCollect;
  final VoidCallback? onLater;

  @override
  State<CoinOfferCard> createState() => _CoinOfferCardState();
}

class _CoinOfferCardState extends State<CoinOfferCard> with SingleTickerProviderStateMixin {
  bool _tapped = false;
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  int get _total => widget.items.fold(0, (s, e) => s + e.coins);

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE4C56A);
    final day = widget.day;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: AnimatedBuilder(
                animation: _t,
                builder: (context, child) {
                  final a = _t.value * 2 * math.pi;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment(math.cos(a), math.sin(a)),
                        end: Alignment(-math.cos(a), -math.sin(a)),
                        colors: const [Color(0xF0101014), Color(0xF0050507), Color(0xF0141210)],
                      ),
                      border: Border.all(color: gold.withValues(alpha: 0.42 + 0.18 * math.sin(a).abs()), width: 1),
                      boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.16), blurRadius: 42)],
                    ),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('COLLECT · RECEIVE · KEEP',
                        style: TextStyle(color: gold, letterSpacing: 3, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _Disc(spin: _t),
                    const SizedBox(height: 14),
                    Text('+$_total coins',
                        key: const Key('coin-collect-amount'),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 4),
                    Text(widget.items.length == 1 ? widget.items.first.title : '${widget.items.length} activities ready',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
                    if (widget.items.length > 1) ...[
                      const SizedBox(height: 10),
                      for (final e in widget.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Expanded(child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13))),
                            Text('+${e.coins}', style: const TextStyle(color: gold, fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                        ),
                    ],
                    if (day != null) ...[
                      const SizedBox(height: 16),
                      CoinDayBar(day: day),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        key: const Key('coin-collect-button'),
                        style: TextButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () {
                          if (_tapped) return;
                          _tapped = true;
                          widget.onCollect();
                        },
                        child: const Text('Collect', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
                      ),
                    ),
                    if (widget.onLater != null)
                      TextButton(
                        onPressed: widget.onLater,
                        child: const Text('Later', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.spin});
  final Animation<double> spin;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: AnimatedBuilder(
        animation: spin,
        builder: (context, child) => Stack(alignment: Alignment.center, children: [
          Transform.rotate(
            angle: spin.value * 2 * math.pi,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [Color(0x00E4C56A), Color(0xAAE4C56A), Color(0x00E4C56A)]),
              ),
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF07070A)),
          ),
          Transform.scale(scale: 1 + 0.04 * math.sin(spin.value * 4 * math.pi), child: child),
        ]),
        child: const ClipOval(child: NwsbCoinDisc(size: 66)),
      ),
    );
  }
}

/// Today's coins: collected vs still left to collect today (server numbers).
class CoinDayBar extends StatelessWidget {
  const CoinDayBar({super.key, required this.day});
  final CoinDay day;
  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE4C56A);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Text('TODAY', style: TextStyle(color: Color(0x99FFFFFF), letterSpacing: 2.4, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${day.collected} collected · ${day.left} left',
                  key: const Key('coin-day-label'),
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: day.fraction),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 6,
            color: gold,
            backgroundColor: const Color(0x26FFFFFF),
          ),
        ),
      ),
    ]);
  }
}

