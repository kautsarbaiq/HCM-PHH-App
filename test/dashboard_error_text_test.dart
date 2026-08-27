import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bug 26/08: the admin dashboard showed
///   "Could not load stats: PostgrestException(message: , code: 401,
///    details: Error in Postgrest response for method HEAD, hint: )"
/// `.count()` uses HEAD, and a HEAD response has no body, so PostgREST's
/// message is empty. Reproduced against the live API. The UI must not put a
/// blank message in front of the admin.
void main() {
  test('an expired-token 401 reads as a session problem, not a blank', () {
    final text = statsErrorTextForTest(
      const PostgrestException(
        message: '',
        code: '401',
        details: 'Error in Postgrest response for method HEAD',
      ),
    );
    expect(text, contains('session'));
    expect(text, isNot(contains('message: ')));
    expect(text.trim(), isNotEmpty);
  });

  test('a bodiless non-auth error still names the status code', () {
    final text = statsErrorTextForTest(
      const PostgrestException(message: '', code: '503'),
    );
    expect(text, contains('503'));
  });

  test('a normal error keeps its own message', () {
    final text = statsErrorTextForTest(
      const PostgrestException(message: 'relation does not exist', code: '42P01'),
    );
    expect(text, contains('relation does not exist'));
  });
}
