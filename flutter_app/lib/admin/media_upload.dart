/// Picking, recording and uploading media for the admin screens.
///
/// Everything lands in Cloudflare R2 (NOT Firebase Storage — the project
/// stays on the free Spark plan): `ui/…` for template replacements,
/// `audio/…` for word recordings, `images/…` for word pictures. The bucket
/// is public-read through its public domain, which is what lets every
/// user's app show them. Writing needs a one-time address from
/// functions/api/admin/upload-url.js, which only admins get.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

enum PickKind { image, video, audio }

String _ext(String path, String fallback) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot < path.lastIndexOf('/')) return fallback;
  final e = path.substring(dot + 1).toLowerCase();
  return e.isEmpty || e.length > 5 ? fallback : e;
}

String contentTypeFor(String path, PickKind kind) {
  final e = _ext(path, '');
  switch (e) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'mp4':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return kind == PickKind.audio ? 'audio/webm' : 'video/webm';
    case 'm4a':
    case 'aac':
      return 'audio/mp4';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
      return 'audio/ogg';
  }
  switch (kind) {
    case PickKind.image:
      return 'image/jpeg';
    case PickKind.video:
      return 'video/mp4';
    case PickKind.audio:
      return 'audio/mp4';
  }
}

/// Asks where from — gallery, camera or files — and returns the file.
Future<File?> pickMedia(BuildContext context, PickKind kind) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF0C1220),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (kind != PickKind.audio)
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
            title: const Text('Gallery', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
        if (kind != PickKind.audio)
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: Colors.white),
            title: const Text('Camera', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
        ListTile(
          leading: const Icon(Icons.folder_open_outlined, color: Colors.white),
          title: const Text('Files', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(ctx, 'files'),
        ),
      ]),
    ),
  );
  if (source == null) return null;
  try {
    if (source == 'files') {
      final res = await FilePicker.platform.pickFiles(
        type: kind == PickKind.image
            ? FileType.image
            : (kind == PickKind.video ? FileType.video : FileType.audio),
      );
      final p = res?.files.single.path;
      return p == null ? null : File(p);
    }
    final picker = ImagePicker();
    final src = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final x = kind == PickKind.video
        ? await picker.pickVideo(source: src)
        : await picker.pickImage(source: src, imageQuality: 92);
    return x == null ? null : File(x.path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open that: $e')));
    }
    return null;
  }
}

class Uploaded {
  const Uploaded(this.url, this.key);

  /// Public address every app loads it from (the R2 public domain).
  final String url;

  /// Object key inside the bucket, e.g. `ui/home_normal.HomeNormal.hero/1727….webp`.
  final String key;
}

/// The Cloudflare endpoint that hands out one-time upload addresses. It
/// checks the Firebase sign-in and the admins list before it signs anything;
/// the R2 keys live only in Cloudflare, never in this app.
const kUploadEndpoint = 'https://nowssb.com/api/admin/upload-url';

/// Uploads [file] straight to Cloudflare R2.
///
/// [area] is `ui` (template replacements), `audio` (word recordings) or
/// `image` (word pictures); [target] is the slot key or word key. The server
/// builds the final object key from those two, so an admin phone cannot
/// write anywhere else in the bucket.
Future<Uploaded> uploadToR2(
  File file,
  String area,
  String target,
  PickKind kind, {
  void Function(double)? onProgress,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Sign in first.');
  final idToken = await user.getIdToken();
  final ext = _ext(file.path, kind == PickKind.audio ? 'm4a' : (kind == PickKind.video ? 'mp4' : 'jpg'));
  final type = contentTypeFor(file.path, kind);
  final res = await http
      .post(
        Uri.parse(kUploadEndpoint),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'area': area, 'target': target, 'ext': ext, 'contentType': type}),
      )
      .timeout(const Duration(seconds: 20));
  Map<String, dynamic> data = const {};
  try {
    data = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  } catch (_) {}
  if (res.statusCode != 200 || data['uploadUrl'] is! String) {
    throw Exception(data['error'] ?? 'Upload server said ${res.statusCode}.');
  }
  final bytes = await file.readAsBytes();
  onProgress?.call(0.1);
  final put = await http
      .put(
        Uri.parse(data['uploadUrl'] as String),
        headers: {'Content-Type': type},
        body: bytes,
      )
      .timeout(const Duration(minutes: 10));
  if (put.statusCode < 200 || put.statusCode >= 300) {
    throw Exception('R2 refused the upload (${put.statusCode}).');
  }
  onProgress?.call(1);
  return Uploaded('${data['publicUrl']}', '${data['key']}');
}
