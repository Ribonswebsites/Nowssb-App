import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ConnectService {
  ConnectService._();

  static final instance = ConnectService._();
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _apiBase = 'https://nowssb-api.ribonpatil2.workers.dev';

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to use NowssB Connect.');
    return user;
  }

  String get uid => _user.uid;

  Future<void> ensurePublicProfile() async {
    final user = _user;
    final existing = await _db.collection('users').doc(user.uid).get();
    final data = existing.data() ?? <String, dynamic>{};
    final name = data['displayName']?.toString().trim().isNotEmpty == true
        ? data['displayName'].toString()
        : (user.displayName ?? 'NowssB Practitioner');
    final username = data['username']?.toString().trim().isNotEmpty == true
        ? data['username'].toString()
        : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'^\\.|\\.$'), '');
    await _db.collection('publicProfiles').doc(user.uid).set({
      'uid': user.uid,
      'displayName': name,
      'username': username.isEmpty ? 'practitioner' : username,
      'photoURL': data['photoURL'] ?? user.photoURL ?? '',
      'bio': data['bio'] ?? '',
      'category': data['healthFocus'] ?? 'Practitioner',
      'profileVisibility': 'public',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> profiles() => _db
      .collection('publicProfiles')
      .where('profileVisibility', isEqualTo: 'public')
      .limit(100)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> feed() => _db
      .collection('posts')
      .where('visibility', isEqualTo: 'public')
      .limit(50)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> reels() => _db
      .collection('reels')
      .where('visibility', isEqualTo: 'public')
      .limit(50)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String peerUid) {
    final participants = [uid, peerUid]..sort();
    final room = participants.join('_');
    return _db
        .collection('chats')
        .doc(room)
        .collection('messages')
        .orderBy('createdAt')
        .limitToLast(100)
        .snapshots();
  }

  Future<String> ensureChat(String peerUid) async {
    if (peerUid == uid) throw StateError('You cannot message your own profile.');
    final participants = [uid, peerUid]..sort();
    final room = participants.join('_');
    await _db.collection('chats').doc(room).set({
      'participants': participants,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return room;
  }

  Future<void> sendMessage(String peerUid, String text) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 4000) return;
    final room = await ensureChat(peerUid);
    await _db.collection('chats').doc(room).collection('messages').add({
      'from': uid,
      'text': value,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(room).set({
      'lastMessage': value,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> likePost(String postId) async {
    final like = _db.collection('posts').doc(postId).collection('likes').doc(uid);
    final existing = await like.get();
    final post = _db.collection('posts').doc(postId);
    if (existing.exists) {
      await like.delete();
      await post.set({'likeCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    } else {
      await like.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      await post.set({'likeCount': FieldValue.increment(1)}, SetOptions(merge: true));
    }
  }

  Future<void> commentPost(String postId, String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final clean = value.length > 500 ? value.substring(0, 500) : value;
    final post = _db.collection('posts').doc(postId);
    await post.collection('comments').add({
      'uid': uid,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await post.set({'commentCount': FieldValue.increment(1)}, SetOptions(merge: true));
  }

  Future<void> follow(String peerUid, bool shouldFollow) async {
    if (peerUid == uid) return;
    final following = _db.collection('follows').doc(uid).collection('following').doc(peerUid);
    final follower = _db.collection('follows').doc(peerUid).collection('followers').doc(uid);
    final batch = _db.batch();
    if (shouldFollow) {
      batch.set(following, {'uid': peerUid, 'createdAt': FieldValue.serverTimestamp()});
      batch.set(follower, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(following);
      batch.delete(follower);
    }
    await batch.commit();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> following(String peerUid) =>
      _db.collection('follows').doc(uid).collection('following').doc(peerUid).snapshots();

  String _mimeType(XFile file) {
    final supplied = file.mimeType?.trim();
    if (supplied != null && supplied.isNotEmpty && supplied != 'application/octet-stream') return supplied;
    switch (file.path.toLowerCase().split('.').last) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'webm': return 'video/webm';
      default: return 'application/octet-stream';
    }
  }

  Future<String> upload(XFile file, String kind) async {
    final token = await _user.getIdToken(true) ?? '';
    if (token.isEmpty) throw StateError('Your NowssB session expired. Sign in again.');
    final mimeType = _mimeType(file);
    if (mimeType == 'application/octet-stream') throw StateError('This image or video format is not supported.');
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/api/connect/media'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['kind'] = kind
      ..files.add(await http.MultipartFile.fromPath('file', file.path, contentType: MediaType.parse(mimeType)));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(data['error']?.toString() ?? 'Media upload failed.');
    }
    return data['url']?.toString() ?? (throw StateError('Media URL was missing.'));
  }

  Future<void> createReel({required String caption, required XFile media, String location = ''}) async {
    final user = _user;
    final mimeType = _mimeType(media);
    if (!mimeType.startsWith('video/')) throw StateError('Choose a video file for a Reel.');
    final profile = await _db.collection('publicProfiles').doc(uid).get();
    final profileData = profile.data() ?? <String, dynamic>{};
    final mediaUrl = await upload(media, 'reel');
    final cleanCaption = caption.trim();
    final cleanLocation = location.trim();
    await _db.collection('reels').add({
      'uid': uid,
      'displayName': profileData['displayName'] ?? user.displayName ?? 'NowssB Practitioner',
      'photoURL': profileData['photoURL'] ?? user.photoURL ?? '',
      'mediaUrl': mediaUrl,
      'mediaType': mimeType,
      'caption': cleanCaption.length > 2200 ? cleanCaption.substring(0, 2200) : cleanCaption,
      'location': cleanLocation.length > 120 ? cleanLocation.substring(0, 120) : cleanLocation,
      'visibility': 'public',
      'likes': 0,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createStory({required String caption, required XFile media, String location = ''}) async {
    final user = _user;
    final profile = await _db.collection('publicProfiles').doc(uid).get();
    final profileData = profile.data() ?? <String, dynamic>{};
    final mediaUrl = await upload(media, 'story');
    final mimeType = _mimeType(media);
    final cleanCaption = caption.trim();
    final cleanLocation = location.trim();
    await _db.collection('stories').add({
      'uid': uid,
      'displayName': profileData['displayName'] ?? user.displayName ?? 'NowssB Practitioner',
      'photoURL': profileData['photoURL'] ?? user.photoURL ?? '',
      'mediaUrl': mediaUrl,
      'mediaType': mimeType,
      'caption': cleanCaption.length > 2200 ? cleanCaption.substring(0, 2200) : cleanCaption,
      'location': cleanLocation.length > 120 ? cleanLocation.substring(0, 120) : cleanLocation,
      'visibility': 'public',
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createPost({required String caption, XFile? media, String location = ''}) async {
    final user = _user;
    final profile = await _db.collection('publicProfiles').doc(uid).get();
    final profileData = profile.data() ?? {};
    String? mediaUrl;
    String mediaType = 'text';
    if (media != null) {
      mediaUrl = await upload(media, 'post');
      mediaType = _mimeType(media);
    }
    if ((caption.trim().isEmpty) && mediaUrl == null) {
      throw StateError('Add a message or choose an image.');
    }
    final cleanCaption = caption.trim();
    final cleanLocation = location.trim();
    await _db.collection('posts').add({
      'uid': uid,
      'displayName': profileData['displayName'] ?? user.displayName ?? 'NowssB Practitioner',
      'photoURL': profileData['photoURL'] ?? user.photoURL ?? '',
      'mediaUrl': mediaUrl ?? '',
      'mediaType': mediaType,
      'caption': cleanCaption.length > 2200 ? cleanCaption.substring(0, 2200) : cleanCaption,
      'location': cleanLocation.length > 120 ? cleanLocation.substring(0, 120) : cleanLocation,
      'visibility': 'public',
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePublicProfile({required String displayName, required String username, required String bio, required String category}) async {
    final nameValue = displayName.trim();
    final usernameValue = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    if (nameValue.isEmpty || usernameValue.isEmpty) throw StateError('Name and username are required.');
    final cleanName = nameValue.length > 80 ? nameValue.substring(0, 80) : nameValue;
    final cleanUsername = usernameValue.length > 32 ? usernameValue.substring(0, 32) : usernameValue;
    final bioValue = bio.trim();
    final categoryValue = category.trim();
    await _db.collection('publicProfiles').doc(uid).set({
      'uid': uid,
      'displayName': cleanName,
      'username': cleanUsername,
      'bio': bioValue.length > 500 ? bioValue.substring(0, 500) : bioValue,
      'category': categoryValue.length > 80 ? categoryValue.substring(0, 80) : categoryValue,
      'profileVisibility': 'public',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
