import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(supabaseProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseProvider).auth.onAuthStateChange;
});

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up a new RESIDENT account. The role is never sent from the client —
  /// the handle_new_user trigger assigns 'resident'; admins/guards are
  /// promoted by an admin afterwards. (Sending a role in signup metadata
  /// would let anyone register themselves as admin.)
  ///
  /// HCA: [communityCode] (6-digit) links the resident to their community and
  /// [residentType] marks them as house owner or tenant — both resolved
  /// server-side by the handle_new_user trigger.
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String fullName, {
    String? communityCode,
    String? residentType,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        if (communityCode != null) 'community_code': communityCode,
        if (residentType != null) 'resident_type': residentType,
      },
    );
  }

  /// HCA: validate a community code before signup; returns the community name
  /// or null when the code doesn't exist.
  Future<String?> checkCommunityCode(String code) async {
    final rows = await _supabase.rpc(
      'check_community_code',
      params: {'p_code': code},
    );
    if (rows is List && rows.isNotEmpty) {
      return rows.first['name'] as String?;
    }
    return null;
  }

  /// Meeting 20/07 point 1: a resident account is unusable until management
  /// approves it. Returns the current user's approval_status
  /// ('approved' | 'pending' | 'rejected'); defaults to 'approved' for legacy
  /// rows / any read error so existing users are never locked out.
  Future<String> myApprovalStatus() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return 'approved';
    try {
      final row = await _supabase
          .from('profiles')
          .select('approval_status')
          .eq('id', uid)
          .maybeSingle();
      return (row?['approval_status'] as String?) ?? 'approved';
    } catch (_) {
      return 'approved';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
