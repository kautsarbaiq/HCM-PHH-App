import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns whatever sign-in throws into something a resident or guard can act
/// on. Shared by all three login pages so they cannot drift apart.
///
/// WHY THE NETWORK CASES MATTER
///   When a brand's Supabase project is unreachable the phone throws a raw
///   `ClientException with SocketException: Failed host lookup: '<ref>'`,
///   which was shown to users verbatim. It reads like the app is broken and
///   tells nobody anything useful — the office cannot tell it apart from a
///   wrong password, so they hunt for the wrong problem.
///
///   `Failed host lookup` specifically means the server address does not
///   resolve at all. On a working backend that is almost always the phone
///   being offline; if it persists for everyone, the backend itself is gone.
String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email or password is incorrect. Please check your email is '
          'typed correctly (for example: name@gmail.com).';
    }
    if (m.contains('email not confirmed')) {
      return 'Please contact the management office for approval of your '
          'account.';
    }
    if (m.contains('already registered')) {
      return 'This email is already registered — please log in instead.';
    }
    return error.message;
  }

  if (isNetworkError(error)) {
    return 'Cannot reach the server. Check your internet connection and try '
        'again. If this keeps happening, contact the management office.';
  }

  return 'Something went wrong. Please try again.';
}

/// True when the failure is connectivity rather than anything the user typed.
bool isNetworkError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  if (error is HttpException) return true;
  // supabase_flutter wraps dart:io failures in ClientException, whose type we
  // cannot import here without depending on package:http directly — match on
  // the text it carries instead.
  final s = error.toString().toLowerCase();
  return s.contains('failed host lookup') ||
      s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('connection closed') ||
      s.contains('connection refused') ||
      s.contains('network is unreachable') ||
      s.contains('timeoutexception');
}
