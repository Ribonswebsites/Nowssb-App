/// NowssB Connect — real community feed, profiles, search, and chat.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/connect_service.dart';
import 'connect_call.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _service = ConnectService.instance;
  final _search = TextEditingController();
  int _tab = 0;
  String _query = '';
  final _following = <String, bool>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'NowssB',
      title: 'Connect',
      film: 'assets/video/connect-banner.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverToBoxAdapter(child: _tabs()),
        SliverToBoxAdapter(child: _incomingCallBanner()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(child: _body()),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset('assets/media/image/logo-disc-8b052034.webp', width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NowssB Connect', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 3),
                Text('People, practice, and conversation', style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
              ],
            ),
          ),
          IconButton(onPressed: _openComposer, icon: const Icon(Icons.add_circle_outline, color: NwsbColors.goldLight)),
        ],
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Feed', 'People', 'Chats'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == i ? NwsbColors.goldLight : const Color(0x22FFFFFF), width: _tab == i ? 2 : 1))),
                  child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(color: _tab == i ? NwsbColors.goldLight : const Color(0x99FFFFFF), fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _incomingCallBanner() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('calls').where('calleeUid', isEqualTo: _service.uid).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final ringing = snapshot.data!.docs.where((doc) => doc.data()['status'] == 'ringing').toList();
        if (ringing.isEmpty) return const SizedBox.shrink();
        final call = ringing.first;
        final data = call.data();
        final callerUid = data['callerUid']?.toString() ?? '';
        final callerName = data['callerName']?.toString() ?? 'NowssB Practitioner';
        final kind = data['kind']?.toString() == 'video' ? 'video' : 'audio';
        return Container(margin: const EdgeInsets.fromLTRB(20, 14, 20, 0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF191923), borderRadius: BorderRadius.circular(16), border: Border.all(color: NwsbColors.goldLight.withValues(alpha: .5))), child: Row(children: [const Icon(Icons.call, color: NwsbColors.goldLight), const SizedBox(width: 10), Expanded(child: Text('$callerName is calling you', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), TextButton(onPressed: () async { await call.reference.update({'status': 'declined'}); }, child: const Text('Decline')), FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectCallScreen(peerUid: callerUid, peerName: callerName, kind: kind, callId: call.id, incoming: true))), child: const Text('Answer'))]));
      },
    );
  }

  Widget _body() {
    if (_tab == 1) return _people();
    if (_tab == 2) return _chats();
    return _feed();
  }

  Widget _feed() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.feed(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorCard(snapshot.error!);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = [...snapshot.data!.docs]..sort((a, b) => _time(b).compareTo(_time(a)));
        if (docs.isEmpty) {
          return _emptyCard('Your Connect feed starts here', 'Share a practice or find a practitioner to begin.');
        }
        return Column(children: [for (final doc in docs) _postCard(doc)]);
      },
    );
  }

  int _time(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()?['createdAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  Widget _postCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final mediaUrl = data['mediaUrl']?.toString() ?? '';
    final name = data['displayName']?.toString() ?? 'NowssB Practitioner';
    final caption = data['caption']?.toString() ?? '';
    final location = data['location']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x1FFFFFFF))),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          _avatar(data['photoURL']?.toString(), name, 42),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          if (location.isNotEmpty) Text(location, style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 11)),
        ])),
        if (mediaUrl.isNotEmpty)
          data['mediaType']?.toString().startsWith('video') == true
              ? Container(height: 260, color: const Color(0xFF101018), alignment: Alignment.center, child: const Icon(Icons.play_circle_outline, size: 54, color: NwsbColors.goldLight))
              : Image.network(mediaUrl, width: double.infinity, height: 260, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image_outlined, color: Color(0x66FFFFFF))))),
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(onPressed: () => _like(doc.id), icon: const Icon(Icons.favorite_border, color: Colors.white)),
            IconButton(onPressed: () => _comment(doc.id), icon: const Icon(Icons.chat_bubble_outline, color: Colors.white)),
            const Spacer(),
            Text('${data['likeCount'] ?? 0} likes', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
          ]),
          if (caption.isNotEmpty) Text(caption, style: const TextStyle(color: Color(0xDDFFFFFF), height: 1.45)),
        ])),
      ]),
    );
  }

  Widget _people() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.profiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorCard(snapshot.error!);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final people = snapshot.data!.docs.where((doc) {
          if (doc.id == _service.uid) return false;
          final d = doc.data();
          final value = '${d['displayName'] ?? ''} ${d['username'] ?? ''} ${d['category'] ?? ''}'.toLowerCase();
          return value.contains(_query.toLowerCase());
        }).toList();
        return Column(children: [
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search, color: NwsbColors.goldLight), hintText: 'Search NowssB practitioners', hintStyle: const TextStyle(color: Color(0x66FFFFFF)), filled: true, fillColor: const Color(0xFF101018), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          if (people.isEmpty) _emptyCard('No practitioners found', 'Try a different name, username, or practice area.'),
          for (final doc in people) _personCard(doc),
        ]);
      },
    );
  }

  Widget _personCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final uid = doc.id;
    final name = data['displayName']?.toString() ?? 'NowssB Practitioner';
    final following = _following[uid] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
      child: Row(children: [
        _avatar(data['photoURL']?.toString(), name, 46),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(onTap: () => _openProfile(doc), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), Text('@${data['username'] ?? 'practitioner'} · ${data['category'] ?? 'Practitioner'}', style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 12))]))),
        OutlinedButton(onPressed: () => _toggleFollow(uid, following), child: Text(following ? 'Following' : 'Follow')),
      ]),
    );
  }

  Widget _chats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.profiles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final people = snapshot.data!.docs.where((doc) => doc.id != _service.uid).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Start a conversation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Messages are stored in your private NowssB conversation.', style: TextStyle(color: Color(0x88FFFFFF), fontSize: 12)),
          const SizedBox(height: 14),
          for (final doc in people) _personCardForChat(doc),
        ]);
      },
    );
  }

  Widget _personCardForChat(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final name = data['displayName']?.toString() ?? 'NowssB Practitioner';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      leading: _avatar(data['photoURL']?.toString(), name, 44),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text('@${data['username'] ?? 'practitioner'}', style: const TextStyle(color: Color(0x88FFFFFF))),
      trailing: const Icon(Icons.chevron_right, color: NwsbColors.goldLight),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectChatScreen(peerUid: doc.id, peerName: name))),
    );
  }

  Widget _avatar(String? url, String name, double size) {
    if (url != null && url.isNotEmpty) return ClipOval(child: Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialAvatar(name, size)));
    return _initialAvatar(name, size);
  }

  Widget _initialAvatar(String name, double size) => Container(width: size, height: size, decoration: const BoxDecoration(color: Color(0xFF191923), shape: BoxShape.circle), alignment: Alignment.center, child: Text(name.isEmpty ? 'N' : name[0].toUpperCase(), style: const TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800)));

  Widget _emptyCard(String title, String body) => Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))), child: Column(children: [const Icon(Icons.groups_outlined, color: NwsbColors.goldLight, size: 34), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF), height: 1.4))]));

  Widget _errorCard(Object error) => _emptyCard('Connect is temporarily unavailable', error.toString());

  Future<void> _toggleFollow(String uid, bool currentlyFollowing) async {
    try {
      await _service.follow(uid, !currentlyFollowing);
      if (mounted) setState(() => _following[uid] = !currentlyFollowing);
    } catch (error) { _showError(error); }
  }

  Future<void> _like(String postId) async {
    try { await _service.likePost(postId); } catch (error) { _showError(error); }
  }

  Future<void> _comment(String postId) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Comment on NowssB'), content: TextField(controller: controller, autofocus: true, maxLength: 500, decoration: const InputDecoration(hintText: 'Write a thoughtful comment')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Post'))]));
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    try { await _service.commentPost(postId, value); } catch (error) { _showError(error); }
  }

  Future<void> _openProfile(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final d = doc.data() ?? <String, dynamic>{};
    final name = d['displayName']?.toString() ?? 'NowssB Practitioner';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NwsbColors.deep,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(d['photoURL']?.toString(), name, 76),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text('@${d['username'] ?? 'practitioner'}', style: const TextStyle(color: Color(0x99FFFFFF))),
            const SizedBox(height: 12),
            Text(d['bio']?.toString() ?? 'A NowssB practitioner building a daily sound practice.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.45)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (doc.id == _service.uid) {
                        _editProfile(d);
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectChatScreen(peerUid: doc.id, peerName: name)));
                      }
                    },
                    child: Text(doc.id == _service.uid ? 'Edit profile' : 'Message'),
                  ),
                ),
                const SizedBox(width: 8),
                if (doc.id != _service.uid) ...[
                  IconButton(onPressed: () { Navigator.pop(sheetContext); Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectCallScreen(peerUid: doc.id, peerName: name, kind: 'audio'))); }, icon: const Icon(Icons.call_outlined, color: NwsbColors.goldLight)),
                  IconButton(onPressed: () { Navigator.pop(sheetContext); Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectCallScreen(peerUid: doc.id, peerName: name, kind: 'video'))); }, icon: const Icon(Icons.videocam_outlined, color: NwsbColors.goldLight)),
                ],
                IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close, color: Color(0x99FFFFFF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(Map<String, dynamic> data) async {
    final name = TextEditingController(text: data['displayName']?.toString() ?? '');
    final username = TextEditingController(text: data['username']?.toString() ?? '');
    final bio = TextEditingController(text: data['bio']?.toString() ?? '');
    final category = TextEditingController(text: data['category']?.toString() ?? 'Practitioner');
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NwsbColors.deep,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(sheetContext).viewInsets.bottom + 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit NowssB profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: name, maxLength: 80, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Display name')),
                TextField(controller: username, maxLength: 32, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Username')),
                TextField(controller: category, maxLength: 80, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Practice area')),
                TextField(controller: bio, maxLength: 500, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Bio')),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Save profile'))),
              ],
            ),
          ),
        );
      },
    );
    final values = <String>[name.text, username.text, bio.text, category.text];
    name.dispose();
    username.dispose();
    bio.dispose();
    category.dispose();
    if (result != true) return;
    try {
      await _service.updatePublicProfile(displayName: values[0], username: values[1], bio: values[2], category: values[3]);
      if (mounted) setState(() {});
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openComposer() async {
    final caption = TextEditingController();
    final location = TextEditingController();
    XFile? media;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NwsbColors.deep,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(sheetContext).viewInsets.bottom + 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New NowssB post', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(controller: caption, maxLength: 2200, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Share your practice…', hintStyle: TextStyle(color: Color(0x66FFFFFF)))),
                  const SizedBox(height: 8),
                  TextField(controller: location, maxLength: 120, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Location (optional)', hintStyle: TextStyle(color: Color(0x66FFFFFF)))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          media = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('Add photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          media = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.video_library_outlined),
                        label: const Text('Add video'),
                      ),
                      FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Share')),
                    ],
                  ),
                  if (media != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(media!.name, style: const TextStyle(color: Color(0x99FFFFFF)))),
                ],
              ),
            );
          },
        );
      },
    );
    final captionValue = caption.text;
    final locationValue = location.text;
    caption.dispose();
    location.dispose();
    if (result != true) return;
    try {
      await _service.createPost(caption: captionValue, media: media, location: locationValue);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your NowssB post was shared.')));
    } catch (error) {
      _showError(error);
    }
  }
}

class ConnectChatScreen extends StatefulWidget {
  const ConnectChatScreen({super.key, required this.peerUid, required this.peerName});
  final String peerUid;
  final String peerName;

  @override
  State<ConnectChatScreen> createState() => _ConnectChatScreenState();
}

class _ConnectChatScreenState extends State<ConnectChatScreen> {
  final _service = ConnectService.instance;
  final _composer = TextEditingController();

  @override
  void dispose() { _composer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: NwsbColors.deep,
        actions: [
          IconButton(onPressed: () => _startCall('audio'), icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () => _startCall('video'), icon: const Icon(Icons.videocam_outlined)),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messages()),
          _input(),
        ],
      ),
    );
  }

  Widget _messages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.messages(widget.peerUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Start your first NowssB message.', style: TextStyle(color: Color(0x99FFFFFF))));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, index) {
            final data = docs[index].data();
            final mine = data['from'] == _service.uid;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(color: mine ? const Color(0xFF8F7444) : const Color(0xFF191923), borderRadius: BorderRadius.circular(16)),
                child: Text(data['text']?.toString() ?? '', style: const TextStyle(color: Colors.white, height: 1.35)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _input() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Message ${widget.peerName}…',
                  hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
                  filled: true,
                  fillColor: const Color(0xFF101018),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, color: NwsbColors.goldLight),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async { final text = _composer.text; _composer.clear(); try { await _service.sendMessage(widget.peerUid, text); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); } }
  Future<void> _startCall(String kind) async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConnectCallScreen(peerUid: widget.peerUid, peerName: widget.peerName, kind: kind))); }
}
