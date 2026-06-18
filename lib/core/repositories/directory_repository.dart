import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_repository.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepository(Supabase.instance.client);
});

class DirectoryRepository {
  final SupabaseClient _supabase;

  DirectoryRepository(this._supabase);

  /// Committee members = profiles that have a `position` set.
  Future<List<Profile>> getCommittee() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .not('position', 'is', null)
        .order('full_name', ascending: true);
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  /// Security guards = profiles with role 'guard' (on-duty ones first).
  Future<List<Profile>> getGuards() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'guard')
        .order('on_duty', ascending: false)
        .order('full_name', ascending: true);
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }
}
