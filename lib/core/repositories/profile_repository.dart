import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Model ---
class Profile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String? houseId;
  final String status;
  // Directory fields (committee position / guard shift & post)
  final String? position;
  final String? shift;
  final String? post;
  final bool onDuty;

  Profile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.houseId,
    required this.status,
    this.position,
    this.shift,
    this.post,
    this.onDuty = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      houseId: json['house_id'] as String?,
      status: json['status'] as String? ?? 'inactive',
      position: json['position'] as String?,
      shift: json['shift'] as String?,
      post: json['post'] as String?,
      onDuty: json['on_duty'] as bool? ?? false,
    );
  }
}

// --- Provider ---
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// autoDispose so the cached profile is dropped when no screen is watching it
// (e.g. after logout), preventing the previous account's name/avatar from
// leaking into the next sign-in.
final currentProfileProvider = FutureProvider.autoDispose<Profile?>((
  ref,
) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).getProfile(user.id);
});

// --- Repository ---
class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<Profile?> getProfile(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();
      return Profile.fromJson(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Update the signed-in user's own profile row (RLS allows self-update).
  Future<void> updateMyProfile(Map<String, dynamic> fields) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null || fields.isEmpty) return;
    await _supabase.from('profiles').update(fields).eq('id', uid);
  }
}
