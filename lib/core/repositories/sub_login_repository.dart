import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A family login (wife / child) created by the main resident account.
/// Boss batch 08/08 point 5.
class SubLogin {
  final String userId;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  SubLogin({
    required this.userId,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  factory SubLogin.fromJson(Map<String, dynamic> j) => SubLogin(
        userId: j['user_id'].toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
      );
}

final subLoginRepositoryProvider = Provider<SubLoginRepository>((ref) {
  return SubLoginRepository(Supabase.instance.client);
});

/// The family logins belonging to the signed-in resident.
final mySubLoginsProvider =
    FutureProvider.autoDispose<List<SubLogin>>((ref) async {
  return ref.read(subLoginRepositoryProvider).list();
});

/// True when THIS login is itself a family sub-account — such an account may
/// not create further logins, so the section is hidden for them.
final isSubLoginProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.read(subLoginRepositoryProvider).isSubLogin();
});

class SubLoginRepository {
  final SupabaseClient _supabase;
  SubLoginRepository(this._supabase);

  Future<List<SubLogin>> list() async {
    final rows = await _supabase.rpc('my_sub_logins');
    if (rows is! List) return const [];
    return rows
        .map((r) => SubLogin.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isSubLogin() async {
    try {
      final v = await _supabase.rpc('is_sub_login');
      return v == true;
    } catch (_) {
      // Older databases without migration 33 simply behave as before.
      return false;
    }
  }

  /// Creates the family login server-side (only service_role can add auth
  /// users). Throws with the server's message so the UI can show it as-is.
  Future<void> create({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _invoke({
      'action': 'create',
      'full_name': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<void> remove(String userId) async {
    await _invoke({'action': 'delete', 'user_id': userId});
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    final res = await _supabase.functions.invoke(
      'resident-create-sublogin',
      body: body,
    );
    final data = res.data;
    if (res.status != 200) {
      final msg = (data is Map && data['error'] != null)
          ? data['error'].toString()
          : 'Request failed (${res.status})';
      throw Exception(msg);
    }
  }
}
