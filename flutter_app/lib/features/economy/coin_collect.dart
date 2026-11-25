/// Coins are never credited silently. Only two kinds of thing earn coins:
/// finishing a real task (a full practice, a share, a first post, a finished
/// profile, a friend's link) and the daily check-in (the first launch of
/// the IST day, once). Opening or visiting a page never earns coins. A
/// reward only *offers* its coins: a frosted glass card asks "Collect".
/// Only that tap calls the server (reportAction). The coins fly into the wallet and today's bar counts
/// up only after that credit is confirmed. If the phone is offline, the
/// coins stay pending and the card shows they will collect when online;
/// the balance does not change.
///
/// Later (or tapping outside) puts the card away for the rest of this run:
/// it does not come back when another page opens. Waiting coins can be
/// collected any time from the Coins wallet, and the card is offered again
/// at most once, on the next app launch.
///
/// Uncollected offers wait on this phone (SharedPreferences) for the rest of
/// the IST day; the server's daily limits are per day, so an offer from an
/// earlier day is dropped instead of being paid against today.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/quotes_live.dart' show DailyQuoteGate;
import '../../screens/splash.dart' show SplashGate;
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import '../../widgets/swipe_away.dart';
import 'economy_api.dart';
import 'reward_fx.dart' show coinsIn, playCoins;
import 'reward_overlay.dart';
import '../../widgets/restyle_kit.dart' show KitActionPill, kKitMuted;
import 'package:nowssb/data/app_haptics.dart';

/// One activity's coins waiting for a Collect tap.
class PendingEarn {
  const PendingEarn({required this.action, this.key = '', required this.coins, required this.title});
  final String action;
  final String key;
  final int coins;
  final String title;
  String get id => '$action:$key';

  /// What the card says for this reward (real copy, not the server's id).
  String get label => action == 'open' ? 'Daily check-in' : title;
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
      if (a is! Map || a['free'] == false || PendingCoins._pageVisits.contains(a['id'])) continue;
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
    'first_share': (15, 'First share of a word'),
    'echo_first_post': (10, 'First Echo Wall post'),
    'profile_complete': (50, 'Complete your profile'),
    'referral_welcome': (100, 'Welcome gift from a friend’s link'),
    'referral_friend': (50, 'A friend joined with your link'),
  };

  /// Server actions that are page visits, not tasks. They are never offered.
  static const _pageVisits = {'explore'};

  final List<PendingEarn> items = [];
  final Set<String> _handled = {}; // collected (or offered) today
  String _day = '';
  bool _loaded = false;
  Future<void>? _loading;
  bool _showing = false;
  bool busy = false;
  /// Snapshot taken at the start of a credit, used only after it confirms.
  int? _balanceBefore;
  CoinDay? _dayBefore;
  Timer? _debounce;
  Timer? _retry;
  int _retries = 0;

  /// Ids already put in front of the user this run (so "Later" is not asked
  /// again in a loop, but a reward that arrives while the card is up is).
  final Set<String> _shownIds = {};

  /// Ids put away with Later this run. They are not shown again until the
  /// next launch (or the user opens them from the Coins wallet).
  final Set<String> _snoozed = {};

  /// The launch card has been offered this run (the home shell can be
  /// rebuilt many times in one run; the launch card is offered once).
  bool _launchShown = false;

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
    _snoozed.clear();
    _launchShown = false;
    _retries = 0;
    _balanceBefore = null;
    _dayBefore = null;
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
    if (_pageVisits.contains(action)) return; // visiting a page earns nothing
    await _load();
    final k = key ?? '';
    final id = '$action:$k';
    if (_handled.contains(id) || items.any((e) => e.id == id)) return;
    var server = _serverAction(action);
    if (server == null && action == 'open' && EconomyMirror.instance.uid != null) {
      // A fresh install has no record of today's check-in on the phone:
      // ask the server first, so a reinstall the same day offers nothing.
      try {
        await EconomyApi.call('summary').timeout(const Duration(seconds: 5));
      } catch (_) {}
      server = _serverAction(action);
      if (_handled.contains(id) || items.any((e) => e.id == id)) return;
    }
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

  /// Loads what is waiting on this phone (the Coins wallet lists it).
  Future<void> ensureLoaded() async {
    await _load();
    notifyListeners();
  }

  /// The home shell is up. Offers the card for what is waiting once per
  /// run, including coins put away with Later on an earlier launch.
  Future<void> showOnLaunch() {
    if (_launchShown) return Future<void>.value();
    _launchShown = true;
    return show(includeSnoozed: true);
  }

  /// The Coins wallet's Collect: everything waiting, Later or not.
  Future<void> showWaiting() => show(includeSnoozed: true);

  /// Shows the Collect card for everything waiting (no-op when empty).
  /// Rewards put away with Later this run are left out unless
  /// [includeSnoozed] (launch and the wallet).
  ///
  /// It always shows for an uncollected reward: if the screen is not ready
  /// (no navigator yet, splash or the daily quote still up) it waits and
  /// tries again instead of silently giving up. Coins move only on the
  /// Collect tap; Later and a dismissed card leave them waiting.
  Future<void> show({bool includeSnoozed = false}) async {
    await _load();
    List<PendingEarn> due() => [for (final e in items) if (includeSnoozed || !_snoozed.contains(e.id)) e];
    // Widget tests switch plays off: no gate waits or retries to leave behind.
    if (due().isEmpty || _showing || RewardOverlay.quiet || RewardOverlay.adminSilenced) return;
    _showing = true;
    Future<int>? collecting;
    List<PendingEarn> shown = const [];
    var played = false;
    try {
      await _whenClear();
      if (due().isEmpty) return;
      shown = due();
      await RewardOverlay.enqueue((nav) async {
        played = true;
        _launchShown = true; // a card this run counts as this launch's card
        _shownIds.addAll(shown.map((e) => e.id));
        await nav.push<bool>(RawDialogRoute<bool>(
          // A tap on the dim area is the same as Later: the coins stay
          // pending and nothing is collected.
          barrierDismissible: true,
          barrierLabel: 'coins',
          barrierColor: const Color(0x8C03060C),
          transitionDuration: const Duration(milliseconds: 420),
          transitionBuilder: (context, a, _, child) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          pageBuilder: (context, _, __) => Center(
            child: SwipeAway(
              onDismissed: () => Navigator.of(context).maybePop(false),
              child: CoinOfferCard(
                items: shown,
                day: CoinDay.fromSummary(EconomyMirror.instance.summary, pending: shown.fold(0, (s, e) => s + e.coins)),
                onCollect: () {
                  // Credit first; the fly-in starts only after this
                  // resolves with a confirmed gain (see after the route).
                  collecting ??= collectBatch(shown, animate: false);
                  return collecting!;
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
    final pending = collecting;
    if (pending != null) {
      final gained = await pending;
      // The card pops itself once the credit is confirmed; the fly-in
      // runs only now, on the confirmed amount, never on an optimistic one.
      if (gained > 0) await _playConfirmed(gained);
    }
    // Later, a tap outside or a swipe: put away for the rest of this run.
    for (final e in shown) {
      if (items.any((x) => x.id == e.id)) _snoozed.add(e.id);
    }
    notifyListeners();
    // A reward that arrived while the card was open gets its own card.
    if (items.any((e) => !_shownIds.contains(e.id) && !_snoozed.contains(e.id))) unawaited(show());
  }

  /// Credits everything waiting. Tests and the card's tap both land here.
  Future<int> collect() => collectBatch(List.of(items));

  /// The user tapped Collect for [batch]: credit them on the server first.
  /// The fly-in and the wallet count-up run only after that credit is
  /// confirmed, and only for the coins the server actually granted.
  /// When [animate] is false (the Collect card), the caller plays the
  /// flight after the card has closed. Returns the coins credited.
  Future<int> collectBatch(List<PendingEarn> batch, {bool animate = true}) async {
    final gained = await _creditBatch(batch);
    if (animate && gained > 0) await _playConfirmed(gained);
    return gained;
  }

  Future<int> _creditBatch(List<PendingEarn> batch) async {
    await _load();
    final todo = [for (final e in batch) if (items.any((x) => x.id == e.id)) e];
    if (busy || todo.isEmpty) return 0;
    busy = true;
    notifyListeners();
    final offered = todo.fold(0, (s, e) => s + e.coins);
    final mirror = EconomyMirror.instance;
    _balanceBefore = mirror.coins;
    _dayBefore = CoinDay.fromSummary(mirror.summary, pending: offered);
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
      if (gained > 0) {
        // Refresh today's numbers in the background; the bar uses the
        // confirmed gain, not this round-trip.
        unawaited(EconomyApi.call('summary').then((_) {}, onError: (_) {}));
      }
      if (gained == 0 && kept > 0) {
        // The card shows the saved state itself while it is still up.
        if (!_showing) _tell('Saved, will collect when online.');
      } else if (gained > 0 && kept > 0) {
        _tell('Saved, $kept will collect when online.');
      } else if (gained < offered) {
        _tell('Those coins were already collected today.');
      }
    } finally {
      busy = false;
      notifyListeners();
    }
    return gained;
  }

  /// Fly-in and wallet count-up for a confirmed credit only. Never called
  /// with an optimistic amount, and never when the coins were only saved.
  Future<void> _playConfirmed(int gained) async {
    if (gained <= 0) return;
    AppHaptics.medium();
    final before = _balanceBefore ?? 0;
    final day0 = _dayBefore;
    final dayAfter = day0 == null
        ? null
        : CoinDay(collected: day0.collected + gained, left: math.max(0, day0.left - gained), ceiling: day0.ceiling);
    await playCoins(null, gained, balanceAfter: before + gained, day: dayAfter, immediate: true);
  }

  void _tell(String text) {
    final ctx = RewardOverlay.navigatorKey.currentContext;
    final m = ctx == null ? null : ScaffoldMessenger.maybeOf(ctx);
    m?.showSnackBar(SnackBar(content: Text(text)));
  }
}

/// The Collect card in the NowssB glass (the Player, Sound Library, Store
/// and menu panes): deep-blur frosted glass, white type, the coin, the
/// white pill Collect and an outlined Later.
class CoinOfferCard extends StatefulWidget {
  const CoinOfferCard({super.key, required this.items, required this.day, required this.onCollect, this.onLater});
  final List<PendingEarn> items;
  final CoinDay? day;
  /// Credits the shown coins. Returns how many the server actually granted.
  final Future<int> Function() onCollect;
  final VoidCallback? onLater;

  @override
  State<CoinOfferCard> createState() => _CoinOfferCardState();
}

class _CoinOfferCardState extends State<CoinOfferCard> {
  bool _tapped = false;
  bool _saved = false;

  int get _total => widget.items.fold(0, (s, e) => s + e.coins);

  Future<void> _collect() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    final nav = Navigator.of(context);
    final gained = await widget.onCollect();
    if (!mounted) return;
    if (gained > 0) {
      nav.maybePop(true);
      return;
    }
    final still = widget.items.any((e) => PendingCoins.instance.items.any((x) => x.id == e.id));
    if (still) {
      setState(() => _saved = true);
    } else {
      nav.maybePop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final one = widget.items.length == 1;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 18), blurRadius: 44)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x2EFFFFFF), Color(0x14FFFFFF)],
                    ),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const _Disc(),
                    const SizedBox(height: 16),
                    Text('+$_total coins',
                        key: const Key('coin-collect-amount'),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 6),
                    Text(one ? widget.items.first.label : '${widget.items.length} rewards ready',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 14, fontWeight: FontWeight.w600)),
                    if (one && widget.items.first.action == 'open') ...[
                      const SizedBox(height: 4),
                      const Text('Once a day, for opening NowssB today.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kKitMuted, fontSize: 12.5, height: 1.3)),
                    ],
                    if (!one) ...[
                      const SizedBox(height: 12),
                      for (final e in widget.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13))),
                            Text('+${e.coins}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ]),
                        ),
                    ],
                    if (day != null) ...[
                      const SizedBox(height: 18),
                      CoinDayBar(day: day),
                    ],
                    const SizedBox(height: 20),
                    if (_saved)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text('Saved, will collect when online',
                            key: Key('coin-collect-saved'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, height: 1.3)),
                      )
                    else
                      KitActionPill('Collect', key: const Key('coin-collect-button'), busy: _tapped, onTap: _tapped ? null : _collect),
                    if (widget.onLater != null && (!_tapped || _saved)) ...[
                      const SizedBox(height: 10),
                      KitActionPill(_saved ? 'Close' : 'Later', primary: false, onTap: widget.onLater),
                    ],
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
  const _Disc();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x1FFFFFFF),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      alignment: Alignment.center,
      child: const ClipOval(child: NwsbCoinDisc(size: 66)),
    );
  }
}

/// Today's coins: collected vs still left to collect today (server numbers).
class CoinDayBar extends StatelessWidget {
  const CoinDayBar({super.key, required this.day});
  final CoinDay day;
  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
            backgroundColor: const Color(0x26FFFFFF),
          ),
        ),
      ),
    ]);
  }
}

