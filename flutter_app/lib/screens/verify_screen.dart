/// Get Verified — a real request flow on the existing backend.
///
/// * Request: files a 'verify' item in the admin Requests queue
///   (WordRequestStore → same path the word requests use).
/// * Approval: the team sets `verifyTier` on users/{uid} (Admin → People),
///   and Frequency X subscribers get Blue automatically (functions/_lib/play.js).
/// * Status: read live from the person's own users/{uid} doc (rules allow
///   self-read), plus the time of their request kept on the phone.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_requests.dart';
import '../widgets/glass_list_card.dart';
import 'nwsb_sign_in_sheet.dart';

const _bg = Color(0xFF0B0B10);
const _white = Color(0xFFF4F1EA);
const _prefsKey = 'verify_requested_at_v1';

class VerifyTier {
  const VerifyTier(this.key, this.name, this.color, this.how);
  final String key, name, how;
  final Color color;
}

const kVerifyTiers = <VerifyTier>[
  VerifyTier('blue', 'Blue', Color(0xFF5AA9FF), 'Included with Frequency X, or granted after a profile review.'),
  VerifyTier('silver', 'Silver', Color(0xFFC9CED6), 'Granted by the NowssB team after a profile review.'),
  VerifyTier('gold', 'Gold', Color(0xFFE2B857), 'Granted by the NowssB team after a profile review.'),
  VerifyTier('diamond', 'Diamond', Color(0xFF9EE7FF), 'Granted by the NowssB team after a profile review.'),
];

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, this.debugTier, this.debugRequestedAt});
  /// Test hooks (no Firebase in widget tests).
  final String? debugTier;
  final DateTime? debugRequestedAt;
  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String _tier = '';
  DateTime? _requestedAt;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tier = widget.debugTier ?? '';
    _requestedAt = widget.debugRequestedAt;
    if (widget.debugTier != null || widget.debugRequestedAt != null) return;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_prefsKey);
      if (ms != null && mounted) setState(() => _requestedAt = DateTime.fromMillisecondsSinceEpoch(ms));
    } catch (_) {}
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      _sub = FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots().listen((s) {
        if (mounted) setState(() => _tier = '${s.data()?['verifyTier'] ?? ''}');
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _request() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await NwsbSignInPage.open(context);
      if (FirebaseAuth.instance.currentUser == null) return;
      unawaited(_load());
    }
    if (!mounted) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await WordRequestStore.instance.submit(
        word: 'Verification badge',
        notes: 'Please review my profile for a NowssB verification badge.',
        kind: 'verify',
      );
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, now.millisecondsSinceEpoch);
      if (mounted) setState(() => _requestedAt = now);
      messenger.showSnackBar(const SnackBar(content: Text('Request sent. Your status is shown here.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is ArgumentError ? '${e.message}' : 'The request could not be sent. Try again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  VerifyTier? get _current {
    for (final t in kVerifyTiers) {
      if (t.key == _tier) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    final pending = cur == null && _requestedAt != null;
    final status = cur != null
        ? 'Approved · ${cur.name} badge'
        : pending
            ? 'Pending review · requested ${_fmt(_requestedAt!)}'
            : 'Not verified yet';
    final statusColor = cur?.color ?? (pending ? const Color(0xFFE2B857) : kGlassMuted);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _white,
        elevation: 0,
        title: const Text('Get Verified', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          _Glass(
            child: Row(children: [
              Icon(cur != null ? Icons.verified_rounded : Icons.verified_outlined, color: statusColor, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR STATUS', style: TextStyle(color: kGlassMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                  const SizedBox(height: 4),
                  Text(status, key: const Key('verify-status'), style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          const Text('BADGES', style: TextStyle(color: kGlassMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
          const SizedBox(height: 10),
          for (final t in kVerifyTiers) ...[
            _Glass(
              highlight: t.key == _tier ? t.color : null,
              child: Row(children: [
                Icon(Icons.verified_rounded, color: t.color, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(t.how, style: const TextStyle(color: kGlassMuted, fontSize: 13, height: 1.35)),
                  ]),
                ),
                if (t.key == _tier) Text('Yours', style: TextStyle(color: t.color, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          const Text(
            'The team looks at your profile and activity, then sets the badge that fits. '
            'You get an answer in your notifications, and the badge appears here.',
            style: TextStyle(color: kGlassMuted, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 18),
          if (cur == null)
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('verify-request'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE2B857),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: pending || _sending ? null : _request,
                child: Text(pending ? 'Request sent' : (_sending ? 'Sending…' : 'Request verification'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.highlight});
  final Widget child;
  final Color? highlight;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: highlight?.withValues(alpha: .7) ?? const Color(0x26FFFFFF)),
        ),
        child: child,
      );
}
