import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps PostgREST calls from firing with a stale access token.
///
/// Bug reported 26/08: the admin dashboard showed
///   `PostgrestException(message: , code: 401, details: Error in Postgrest
///    response for method HEAD, hint: )`
/// The empty message is the giveaway — `.count()` issues a HEAD request, and a
/// HEAD response carries no body for PostgREST to put a message in. Reproduced
/// against the live API: a valid token returns 200, an expired one returns
/// exactly that bodiless 401.
///
/// Supabase refreshes tokens in the background, so a query fired right after a
/// cold start (or after the laptop wakes from sleep) can race the refresh and
/// go out with the expired token.
class SessionGuard {
  const SessionGuard._();

  /// Refreshes the session when the stored token is expired or nearly so.
  /// Never throws — if the refresh fails the caller still gets to try, and a
  /// genuinely signed-out user is handled by the router.
  static Future<void> ensureFresh() async {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    if (session == null) return;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return;

    // Refresh a minute early so a request in flight cannot expire mid-way.
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    if (expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) return;

    try {
      await auth.refreshSession();
    } catch (e) {
      debugPrint('SessionGuard: refresh failed: $e');
    }
  }

  /// Runs [action], and if it fails with an auth error, refreshes the session
  /// and tries once more. Use for reads that must not die on a stale token.
  static Future<T> run<T>(Future<T> Function() action) async {
    await ensureFresh();
    try {
      return await action();
    } on PostgrestException catch (e) {
      if (e.code != '401' && e.code != 'PGRST301') rethrow;
      // Stale token slipped through — force a refresh and retry once.
      try {
        await Supabase.instance.client.auth.refreshSession();
      } catch (_) {
        throw Exception(
          'Your session has expired. Please sign in again.',
        );
      }
      return await action();
    }
  }
}
