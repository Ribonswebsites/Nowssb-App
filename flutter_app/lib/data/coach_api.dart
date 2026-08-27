library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CoachApiException implements Exception {
  const CoachApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CoachAction {
  const CoachAction({required this.type, required this.label});

  final String type;
  final String label;

  factory CoachAction.fromJson(Map<String, dynamic> json) => CoachAction(
        type: '${json['type'] ?? ''}',
        label: '${json['label'] ?? 'Continue'}',
      );
}

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.actions = const [],
  });

  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;
  final List<CoachAction> actions;

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
        id: '${json['id'] ?? ''}',
        role: '${json['role'] ?? 'assistant'}',
        content: '${json['content'] ?? ''}',
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
        actions: (json['actions'] is List)
            ? (json['actions'] as List)
                .whereType<Map>()
                .map((item) => CoachAction.fromJson(Map<String, dynamic>.from(item)))
                .toList(growable: false)
            : const [],
      );

  Map<String, String> toHistoryJson() => {'role': role, 'content': content};
}

class CoachConversation {
  const CoachConversation({required this.id, required this.messages});

  final String? id;
  final List<CoachMessage> messages;
}

class CoachReply {
  const CoachReply({required this.conversationId, required this.message});

  final String conversationId;
  final CoachMessage message;
}

class CoachApi {
  CoachApi({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://nowssb.com/api/coach');

  final http.Client _client;
  final Uri _baseUri;

  Future<String> _token() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const CoachApiException('Sign in to chat with your coach.');
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const CoachApiException('Your sign-in expired. Please sign in again.');
    }
    return idToken;
  }

  Future<CoachConversation> loadHistory({String? conversationId}) async {
    final token = await _token();
    final uri = conversationId == null
        ? _baseUri
        : _baseUri.replace(queryParameters: {'conversationId': conversationId});
    final response = await _client.get(uri, headers: _headers(token));
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachApiException(_errorMessage(data, 'Could not load your coach history.'), statusCode: response.statusCode);
    }
    final messages = (data['messages'] is List)
        ? (data['messages'] as List)
            .whereType<Map>()
            .map((item) => CoachMessage.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <CoachMessage>[];
    return CoachConversation(id: data['conversationId'] as String?, messages: messages);
  }

  Future<CoachReply> send({
    required String message,
    required List<CoachMessage> history,
    required Map<String, dynamic> context,
    String? conversationId,
  }) async {
    final text = message.trim();
    if (text.isEmpty) throw const CoachApiException('Write a message first.');
    final token = await _token();
    final response = await _client
        .post(
          _baseUri,
          headers: {..._headers(token), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': text,
            'conversationId': conversationId,
            'history': history
                .where((item) => item.role == 'user' || item.role == 'assistant')
                .toList()
                .reversed
                .take(20)
                .toList()
                .reversed
                .map((item) => item.toHistoryJson())
                .toList(),
            'context': context,
          }),
        )
        .timeout(const Duration(seconds: 30));
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachApiException(_errorMessage(data, 'The coach is temporarily unavailable. Please retry.'), statusCode: response.statusCode);
    }
    final rawMessage = data['message'];
    if (rawMessage is! Map) throw const CoachApiException('The coach returned an invalid response. Please retry.');
    return CoachReply(
      conversationId: '${data['conversationId'] ?? conversationId ?? ''}',
      message: CoachMessage.fromJson(Map<String, dynamic>.from(rawMessage)),
    );
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _errorMessage(Map<String, dynamic> data, String fallback) {
    final value = data['error'];
    return value is String && value.isNotEmpty ? value : fallback;
  }
}
