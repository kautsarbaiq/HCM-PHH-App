import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_repository.dart'; // To reuse Profile model

class House {
  final String id;
  final String houseNumber;
  final String houseType;
  final String status;
  final String? ownerId;
  final String? address; // Full street address (optional).

  // Joined fields
  final Profile? owner;

  House({
    required this.id,
    required this.houseNumber,
    required this.houseType,
    required this.status,
    this.ownerId,
    this.address,
    this.owner,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'] as String,
      houseNumber: json['house_number'] as String,
      houseType: json['house_type'] as String,
      status: json['status'] as String,
      ownerId: json['owner_id'] as String?,
      address: json['address'] as String?,
      owner: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'house_number': houseNumber,
      'house_type': houseType,
      'status': status,
      'owner_id': ownerId,
      'address': address,
    };
  }
}

final houseRepositoryProvider = Provider<HouseRepository>((ref) {
  return HouseRepository(Supabase.instance.client);
});

class HouseRepository {
  final SupabaseClient _supabase;

  HouseRepository(this._supabase);

  Future<List<House>> getAllHouses() async {
    final response = await _supabase
        .from('houses')
        .select('*, profiles!houses_owner_id_fkey(*)')
        .order('house_number');

    return (response as List).map((json) => House.fromJson(json)).toList();
  }

  /// Returns null when the house isn't visible (RLS) or no longer exists.
  /// `.single()` used to throw a 406 (PGRST116) in that case, which showed up
  /// as a failed request on every profile load.
  Future<House?> getHouseById(String id) async {
    final response = await _supabase
        .from('houses')
        .select('*, profiles!houses_owner_id_fkey(*)')
        .eq('id', id)
        .maybeSingle();

    return response == null ? null : House.fromJson(response);
  }

  Future<House> createHouse(House house) async {
    final response = await _supabase
        .from('houses')
        .insert(house.toJson())
        .select()
        .single();

    return House.fromJson(response);
  }

  Future<House> updateHouse(String id, Map<String, dynamic> updates) async {
    final response = await _supabase
        .from('houses')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return House.fromJson(response);
  }

  Future<void> deleteHouse(String id) async {
    await _supabase.from('houses').delete().eq('id', id);
  }

  /// HCA point 16: an admin creates a login account for a house owner. The
  /// heavy lifting (creating the auth user with service_role, then wiring the
  /// profile to the house/community) happens in the `admin-create-owner` Edge
  /// Function — the anon client can't create auth users. This just invokes it.
  Future<void> createOwnerAccount({
    required String houseId,
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? icNumber,
  }) async {
    try {
      final res = await _supabase.functions.invoke(
        'admin-create-owner',
        body: {
          'house_id': houseId,
          'full_name': fullName,
          'email': email.trim(),
          'password': password,
          'phone': phone,
          'ic_number': icNumber,
        },
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
    } on FunctionException catch (e) {
      // Non-2xx from the function — surface the server's own error message.
      final details = e.details;
      final msg = details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Failed to create owner account (${e.status})';
      throw Exception(msg);
    }
  }
}
