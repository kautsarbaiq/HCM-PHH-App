import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_repository.dart';
import 'profile_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final adminResidentsProvider = FutureProvider<List<Profile>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAllResidents();
});

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // --- Houses ---
  Future<List<House>> getAllHouses() async {
    try {
      final response = await _supabase
          .from('houses')
          .select()
          .order('house_number', ascending: true);
      return (response as List).map((json) => House.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching houses: $e');
      throw Exception('Failed to fetch houses');
    }
  }

  Future<void> createHouse(String houseNumber, String unitType, String status) async {
    try {
      await _supabase.from('houses').insert({
        'house_number': houseNumber,
        'unit_type': unitType,
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to create house');
    }
  }

  Future<void> updateHouse(String houseId, String houseNumber, String unitType, String status) async {
    try {
      await _supabase.from('houses').update({
        'house_number': houseNumber,
        'unit_type': unitType,
        'status': status,
      }).eq('id', houseId);
    } catch (e) {
      throw Exception('Failed to update house');
    }
  }

  Future<void> deleteHouse(String houseId) async {
    try {
      await _supabase.from('houses').delete().eq('id', houseId);
    } catch (e) {
      throw Exception('Failed to delete house');
    }
  }

  // --- Residents ---
  Future<List<Profile>> getAllResidents() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'resident')
          .order('created_at', ascending: false);
      return (response as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching residents: $e');
      throw Exception('Failed to fetch residents');
    }
  }

  Future<void> assignHouseToResident(String residentId, String houseId) async {
    try {
      await _supabase.from('profiles').update({
        'house_id': houseId,
      }).eq('id', residentId);
    } catch (e) {
      throw Exception('Failed to assign house');
    }
  }

  Future<void> updateResidentStatus(String residentId, String status) async {
    try {
      await _supabase.from('profiles').update({
        'status': status,
      }).eq('id', residentId);
    } catch (e) {
      throw Exception('Failed to update resident status');
    }
  }
}
