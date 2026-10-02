/// The admin console's server: `POST https://nowssb.com/api/admin/<action>`
/// (functions/api/admin/[action].js). Every call carries the admin's
/// Firebase ID token; the server checks it and `admins/{uid}` before it
/// reads or writes anything with the service account. When a Cloudflare
/// secret is missing the server answers 501 with the names — shown as-is.
library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const kAdminApiBase = 'https://nowssb.com/api/admin/';

class AdminApiException implements Exception {
  AdminApiException(this.message, {this.status = 0, this.code = '', this.missing = const []});
  final String message;
  final int status;
  final String code;

  /// Cloudflare variables the server said are missing (names only).
  final List<String> missing;

  bool get notConfigured => status == 501 || code == 'not_configured';

  @override
  String toString() => message;
}

class AdminApi {
  AdminApi._();

  static Future<Map<String, dynamic>> call(String action, [Map<String, dynamic>? body]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw AdminApiException('Sign in first.', status: 401);
    String token;
    try {
      token = (await user.getIdToken()) ?? '';
    } catch (_) {
      throw AdminApiException('Could not refresh the sign-in. Check the connection.');
    }
    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$kAdminApiBase$action'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode(body ?? const {}),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw AdminApiException('Could not reach nowssb.com. Check the connection and try again.');
    }
    Map<String, dynamic> data = const {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map) data = Map<String, dynamic>.from(d);
    } catch (_) {}
    if (res.statusCode == 200) return data;
    final missing = (data['missing'] is List) ? (data['missing'] as List).map((e) => '$e').toList() : <String>[];
    if (res.statusCode == 404 && data.isEmpty) {
      throw AdminApiException('The admin server is not deployed on nowssb.com yet (HTTP 404).', status: 404, code: 'not_deployed');
    }
    throw AdminApiException(
      '${data['error'] ?? 'Server said ${res.statusCode}.'}',
      status: res.statusCode,
      code: '${data['code'] ?? ''}',
      missing: missing,
    );
  }

  /// Unauthenticated health probe — which Cloudflare variables are missing.
  static Future<Map<String, dynamic>> health() async {
    try {
      final r = await http.get(Uri.parse('${kAdminApiBase}whoami')).timeout(const Duration(seconds: 15));
      final d = jsonDecode(r.body);
      return d is Map ? Map<String, dynamic>.from(d) : const {};
    } catch (_) {
      return const {};
    }
  }
}
