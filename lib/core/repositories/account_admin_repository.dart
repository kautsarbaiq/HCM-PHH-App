import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Management-side account operations that need the service_role key and
/// therefore live in the `admin-manage-account` Edge Function. This class only
/// invokes it and turns the server's error text into an [Exception] the UI can
/// show verbatim.
class AccountAdminRepository {
  final SupabaseClient _supabase;
  AccountAdminRepository(this._supabase);

  static const _fn = 'admin-manage-account';

  /// Creates a security guard login in the calling admin's community.
  Future<void> createGuard({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      _invoke({
        'action': 'create_guard',
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone,
      }, failure: 'Failed to create guard account');

  /// Sets a new password on someone else's account (resident, guard, or —
  /// for a super admin — an admin). The office then hands the new password
  /// to the person, who should change it from their profile afterwards.
  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) =>
      _invoke({
        'action': 'reset_password',
        'user_id': userId,
        'new_password': newPassword,
      }, failure: 'Failed to reset password');

  Future<void> _invoke(Map<String, dynamic> body,
      {required String failure}) async {
    try {
      final res = await _supabase.functions.invoke(_fn, body: body);
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map && details['error'] != null
          ? details['error'].toString()
          : '$failure (${e.status})';
      throw Exception(msg);
    }
  }
}

final accountAdminRepositoryProvider = Provider<AccountAdminRepository>(
  (ref) => AccountAdminRepository(Supabase.instance.client),
);
