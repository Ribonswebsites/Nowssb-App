import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../theme/tokens.dart';

class ConnectCallScreen extends StatefulWidget {
  const ConnectCallScreen({
    super.key,
    required this.peerUid,
    required this.peerName,
    required this.kind,
    this.callId,
    this.incoming = false,
  });

  final String peerUid;
  final String peerName;
  final String kind;
  final String? callId;
  final bool incoming;

  @override
  State<ConnectCallScreen> createState() => _ConnectCallScreenState();
}

class _ConnectCallScreenState extends State<ConnectCallScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _remoteRenderer = RTCVideoRenderer();
  final _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteIceSub;
  DocumentReference<Map<String, dynamic>>? _callDoc;
  String? _activeCallId;
  String _status = 'Connecting…';
  bool _ending = false;
  bool _remoteDescriptionSet = false;

  bool get _video => widget.kind == 'video';

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _end(updateRemote: false);
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _remoteRenderer.initialize();
      await _localRenderer.initialize();
      final user = _auth.currentUser;
      if (user == null) throw StateError('Sign in to use NowssB calls.');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': _video,
      });
      _localRenderer.srcObject = _localStream;
      _peer = await createPeerConnection({
        'iceServers': [
          {'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']}
        ],
      });
      for (final track in _localStream!.getTracks()) {
        await _peer!.addTrack(track, _localStream!);
      }
      _peer!.onTrack = (event) {
        if (event.streams.isNotEmpty && mounted) {
          setState(() => _remoteRenderer.srcObject = event.streams.first);
        }
      };
      if (widget.incoming && widget.callId != null) {
        await _accept(widget.callId!);
      } else {
        await _placeCall(user.uid);
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'Call could not start');
      debugPrint('NowssB call start failed: $error');
    }
  }

  Future<void> _placeCall(String callerUid) async {
    final caller = _auth.currentUser!;
    final ref = await _db.collection('calls').add({
      'callerUid': callerUid,
      'callerName': caller.displayName ?? 'NowssB Practitioner',
      'callerAvatar': caller.photoURL ?? '',
      'calleeUid': widget.peerUid,
      'kind': widget.kind,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _callDoc = ref;
    _activeCallId = ref.id;
    await _wireCaller(ref);
  }

  Future<void> _wireCaller(DocumentReference<Map<String, dynamic>> ref) async {
    final peer = _peer!;
    peer.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        ref.collection('callerCandidates').add(candidate.toMap());
      }
    };
    final offer = await peer.createOffer();
    await peer.setLocalDescription(offer);
    await ref.update({'offer': {'type': offer.type, 'sdp': offer.sdp}});
    _callSub = ref.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final answer = data['answer'];
      if (answer is Map && !_remoteDescriptionSet && answer['sdp'] != null) {
        await peer.setRemoteDescription(RTCSessionDescription(answer['sdp'].toString(), answer['type']?.toString() ?? 'answer'));
        _remoteDescriptionSet = true;
        if (mounted) setState(() => _status = 'Connected');
      }
      if (data['status'] == 'ended' && mounted) {
        setState(() => _status = 'Call ended');
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.of(context).pop();
      }
    });
    _remoteIceSub = ref.collection('calleeCandidates').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data();
          if (d != null) peer.addCandidate(RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']));
        }
      }
    });
  }

  Future<void> _accept(String callId) async {
    final ref = _db.collection('calls').doc(callId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null || data['offer'] is! Map) throw StateError('This NowssB call is no longer available.');
    _callDoc = ref;
    _activeCallId = callId;
    final peer = _peer!;
    peer.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        ref.collection('calleeCandidates').add(candidate.toMap());
      }
    };
    final offer = data['offer'] as Map;
    await peer.setRemoteDescription(RTCSessionDescription(offer['sdp'].toString(), offer['type']?.toString() ?? 'offer'));
    _remoteDescriptionSet = true;
    final answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);
    await ref.update({'answer': {'type': answer.type, 'sdp': answer.sdp}, 'status': 'accepted'});
    if (mounted) setState(() => _status = 'Connected');
    _callSub = ref.snapshots().listen((snap) async {
      if (snap.data()?['status'] == 'ended' && mounted) Navigator.of(context).pop();
    });
    _remoteIceSub = ref.collection('callerCandidates').snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data();
          if (d != null) peer.addCandidate(RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']));
        }
      }
    });
  }

  Future<void> _end({bool updateRemote = true}) async {
    if (_ending) return;
    _ending = true;
    await _callSub?.cancel();
    await _remoteIceSub?.cancel();
    if (updateRemote && _callDoc != null) {
      try { await _callDoc!.update({'status': 'ended'}); } catch (_) {}
    }
    await _localStream?.dispose();
    await _peer?.close();
    _localStream = null;
    _peer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.kind == 'video' ? 'NowssB Video Call' : 'NowssB Voice Call'), backgroundColor: Colors.black),
      body: Stack(children: [
        if (_video && _remoteRenderer.srcObject != null) Positioned.fill(child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))
        else Positioned.fill(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.graphic_eq, color: NwsbColors.goldLight, size: 76), const SizedBox(height: 18), Text(widget.peerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(_status, style: const TextStyle(color: Color(0x99FFFFFF)))])),
        if (_video && _localRenderer.srcObject != null) Positioned(top: 18, right: 18, width: 110, height: 160, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))),
        Positioned(left: 20, right: 20, bottom: 28, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [FloatingActionButton(onPressed: () async { await _end(); if (mounted) Navigator.of(context).pop(); }, backgroundColor: Colors.redAccent, child: const Icon(Icons.call_end))]))
      ]),
    );
  }
}
