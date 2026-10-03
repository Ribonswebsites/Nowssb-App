/// Google Sign-In failures that mean "this build's Android OAuth client /
/// signing certificate isn't registered" (ApiException 10 = DEVELOPER_ERROR,
/// 12500 = SIGN_IN_FAILED from a misconfigured client), told apart from
/// every other error. Matching any "10" in the text used to catch network
/// timeouts ("…10 s…") and showed developer-only setup steps to members.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final _apiStatus = RegExp(r'apiexception:\s*(10|12500)\b', caseSensitive: false);

/// True only for the Android OAuth / certificate misconfiguration.
bool isGoogleConfigError(PlatformException e) {
  final msg = '${e.message ?? ''} ${e.details ?? ''}';
  if (e.code.toLowerCase() == 'developer_error' || msg.toLowerCase().contains('developer_error')) return true;
  return e.code == 'sign_in_failed' && _apiStatus.hasMatch(msg);
}

/// What a member sees for [isGoogleConfigError]; the developer detail only
/// goes to the log.
String googleConfigMessage(PlatformException e) {
  debugPrint('NowssB Google sign-in misconfigured for this build (add package com.nowssb.app and its SHA-1/SHA-256 '
      'to the Firebase Android app): ${e.code} ${e.message}');
  return 'Google sign-in isn’t available in this copy of NowssB right now. Sign in with email or phone instead.';
}
