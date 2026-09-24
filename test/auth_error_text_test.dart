import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/services/auth_error_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PHH users were shown this verbatim when their Supabase project vanished:
///
///   ClientException with SocketException: Failed host lookup:
///   'kghiryjutwjgfdtbjtuq.supabase.co' (OS Error: No address associated
///   with hostname, errno = 7)
///
/// Nobody can act on that, and the office cannot tell it apart from a wrong
/// password — so they debug the wrong thing.
void main() {
  group('network failures', () {
    test('the exact PHH host-lookup failure reads as a connection problem', () {
      const raw = "ClientException with SocketException: Failed host lookup: "
          "'kghiryjutwjgfdtbjtuq.supabase.co' (OS Error: No address "
          "associated with hostname, errno = 7)";
      expect(isNetworkError(raw), isTrue);
      final msg = friendlyAuthError(raw);
      expect(msg, contains('Cannot reach the server'));
      expect(msg, isNot(contains('SocketException')));
      expect(msg, isNot(contains('supabase.co')),
          reason: 'never show users internal hostnames');
    });

    test('other connectivity failures are covered too', () {
      expect(isNetworkError(const SocketException('no route')), isTrue);
      expect(isNetworkError(TimeoutException('slow')), isTrue);
      expect(isNetworkError('Connection refused'), isTrue);
    });
  });

  group('credential failures still read the same', () {
    test('wrong password keeps its specific wording', () {
      final msg = friendlyAuthError(AuthException('Invalid login credentials'));
      expect(msg, contains('Email or password is incorrect'));
      expect(isNetworkError(AuthException('Invalid login credentials')), isFalse,
          reason: 'a wrong password must never look like a network outage');
    });

    test('unapproved accounts are pointed at the office', () {
      expect(
        friendlyAuthError(AuthException('Email not confirmed')),
        contains('management office'),
      );
    });
  });

  test('anything unexpected stays vague rather than leaking internals', () {
    expect(friendlyAuthError(StateError('boom')), 'Something went wrong. Please try again.');
  });
}
