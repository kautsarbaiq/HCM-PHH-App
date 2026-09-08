import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deletes the signed-in user's own account.
///
/// Both stores now require this: an account that can be created in the app
/// must be deletable from inside the app (App Store guideline 5.1.1(v), Play
/// data-deletion policy). The work itself happens in the `delete-my-account`
/// edge function because only the service_role key may touch auth.users.
class AccountDeletionService {
  AccountDeletionService(this._supabase);

  final SupabaseClient _supabase;

  /// Deletes the account, then signs the device out.
  ///
  /// The sign-out is deliberate and unconditional: once the server has removed
  /// the account, the cached session on this phone is worthless, and leaving
  /// the user on a logged-in screen backed by a dead account produces
  /// confusing 401s instead of a clean return to the login page.
  Future<void> deleteMyAccount() async {
    final res = await _supabase.functions.invoke('delete-my-account');
    final data = res.data;
    if (res.status != 200) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Could not delete the account (${res.status})';
      throw Exception(msg);
    }
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // The account is already gone server-side; a failed local sign-out must
      // not be reported to the user as a failed deletion.
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>(
  (ref) => AccountDeletionService(Supabase.instance.client),
);
