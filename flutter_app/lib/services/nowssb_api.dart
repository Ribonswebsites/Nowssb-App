import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/models.dart';

/// The public Worker URL contains no credentials. Groq remains server-side.
class NowssbApi {
  NowssbApi._();

  static const baseUrl = 'https://nowssb-api.ribonpatil2.workers.dev';
  static final NowssbApi instance = NowssbApi._();

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const NowssbApiException('Sign in to use this NowssB feature.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const NowssbApiException('Your NowssB sign-in session needs refreshing.');
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'X-NowssB-Client': 'flutter',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PronunciationScore> scoreRecording({
    required File file,
    required Word word,
    String? language,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const NowssbApiException('The recording is empty.');
    if (bytes.length > 25 * 1024 * 1024) {
      throw const NowssbApiException('The recording is larger than 25 MB.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/groq/score'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'audio_base64': base64Encode(bytes),
            'mime_type': 'audio/mp4',
            'model': 'whisper-large-v3-turbo',
            'target': word.word,
            'phonetic': word.phonetic.isNotEmpty ? word.phonetic : word.word,
            'prompt': '${word.word} ${word.phonetic}',
            if (language != null && language.isNotEmpty) 'language': language,
          }),
        )
        .timeout(const Duration(seconds: 45));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NowssbApiException(
        body['error']?.toString() ?? 'Pronunciation scoring failed.',
      );
    }
    return PronunciationScore.fromJson(body);
  }

  Future<String> complete({
    required List<Map<String, String>> messages,
    String? system,
    String model = 'openai/gpt-oss-20b',
    int maxTokens = 400,
    double temperature = 0.4,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/groq/complete'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'messages': messages,
            'model': model,
            'max_completion_tokens': maxTokens,
            'temperature': temperature,
            if (system != null && system.isNotEmpty) 'system': system,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NowssbApiException(body['error']?.toString() ?? 'AI request failed.');
    }
    final choices = body['choices'];
    final firstChoice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = firstChoice is Map ? firstChoice['message'] : null;
    final content = message is Map ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const NowssbApiException('The AI returned no text.');
    }
    return content.trim();
  }

  Future<String> assistantChat({
    required String mode,
    required List<Map<String, String>> messages,
    String? context,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/assistant/chat'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'mode': mode == 'coach' ? 'coach' : 'support',
            'messages': messages,
            if (context != null && context.trim().isNotEmpty) 'context': context.trim(),
          }),
        )
        .timeout(const Duration(seconds: 35));

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NowssbApiException(body['error']?.toString() ?? 'Assistant request failed.');
    }
    final message = body['message'];
    if (message is! String || message.trim().isEmpty) {
      throw const NowssbApiException('The assistant returned no text.');
    }
    return message.trim();
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'error': 'Unexpected server response.'};
    } catch (_) {
      return <String, dynamic>{'error': 'The server returned invalid JSON.'};
    }
  }
}

class PronunciationScore {
  const PronunciationScore({
    required this.score,
    required this.transcript,
    required this.target,
    required this.phonetic,
    required this.matchedSyllables,
    required this.totalSyllables,
  });

  final int score;
  final String transcript;
  final String target;
  final String phonetic;
  final int matchedSyllables;
  final int totalSyllables;

  factory PronunciationScore.fromJson(Map<String, dynamic> json) {
    return PronunciationScore(
      score: ((json['score'] as num?)?.round() ?? 0).clamp(0, 100).toInt(),
      transcript: '${json['transcript'] ?? ''}',
      target: '${json['target'] ?? ''}',
      phonetic: '${json['phonetic'] ?? ''}',
      matchedSyllables: (json['matched'] as num?)?.toInt() ?? 0,
      totalSyllables: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class NowssbApiException implements Exception {
  const NowssbApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
