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

  Future<House> getHouseById(String id) async {
    final response = await _supabase
        .from('houses')
        .select('*, profiles!houses_owner_id_fkey(*)')
        .eq('id', id)
        .single();

    return House.fromJson(response);
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
}
