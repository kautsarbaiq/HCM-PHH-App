import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// HCA (boss 16/07): everything that currently needs the admin's attention —
/// shown as the "Needs your attention" feed on the admin dashboard.
class PendingSignup {
  final String userId;
  final String email;
  final String fullName;
  final String createdAt;

  PendingSignup({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory PendingSignup.fromJson(Map<String, dynamic> json) => PendingSignup(
    userId: json['user_id'].toString(),
    email: (json['email'] ?? '').toString(),
    fullName: (json['full_name'] ?? '').toString(),
    createdAt: (json['created_at'] ?? '').toString(),
  );
}

class AdminAttention {
  final List<PendingSignup> signups;
  final int pendingEvents;
  final int pendingBookings;
  final int pendingForms;

  AdminAttention({
    required this.signups,
    required this.pendingEvents,
    required this.pendingBookings,
    required this.pendingForms,
  });

  bool get isEmpty =>
      signups.isEmpty &&
      pendingEvents == 0 &&
      pendingBookings == 0 &&
      pendingForms == 0;
}

final adminAttentionRepositoryProvider = Provider<AdminAttentionRepository>((
  ref,
) {
  return AdminAttentionRepository(Supabase.instance.client);
});

final adminAttentionProvider = FutureProvider.autoDispose<AdminAttention>((
  ref,
) {
  return ref.read(adminAttentionRepositoryProvider).load();
});

class AdminAttentionRepository {
  final SupabaseClient _supabase;
  AdminAttentionRepository(this._supabase);

  Future<AdminAttention> load() async {
    // Pending signups need the SECURITY DEFINER RPC (auth.users is not
    // readable directly). The rest are simple pending-status counts.
    List<PendingSignup> signups = [];
    try {
      final rows = await _supabase.rpc('admin_pending_signups');
      signups = (rows as List)
          .map((j) => PendingSignup.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Non-admins (or PHH) simply get an empty list.
    }

    final events = await _supabase
        .from('events')
        .count(CountOption.exact)
        .eq('status', 'pending');
    final bookings = await _supabase
        .from('bookings')
        .count(CountOption.exact)
        .eq('status', 'Pending');
    final forms = await _supabase
        .from('form_submissions')
        .count(CountOption.exact)
        .eq('status', 'pending');

    return AdminAttention(
      signups: signups,
      pendingEvents: events,
      pendingBookings: bookings,
      pendingForms: forms,
    );
  }

  /// Approve = the account becomes active (email marked confirmed).
  Future<void> approveSignup(String userId) async {
    await _supabase.rpc('admin_approve_signup', params: {'p_user_id': userId});
  }

  /// Reject = the never-activated account is removed.
  Future<void> rejectSignup(String userId) async {
    await _supabase.rpc('admin_reject_signup', params: {'p_user_id': userId});
  }
}
