import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A parking bay belonging to a house (HCA points 14-15). Admins create bays
/// with numbers; the resident assigns their car plate to a bay.
class ParkingBay {
  final String id;
  final String houseId;
  final String bayNumber;
  final String? plate;
  final String? vehicleDetails;

  ParkingBay({
    required this.id,
    required this.houseId,
    required this.bayNumber,
    this.plate,
    this.vehicleDetails,
  });

  factory ParkingBay.fromJson(Map<String, dynamic> json) => ParkingBay(
    id: json['id'] as String,
    houseId: json['house_id'] as String,
    bayNumber: json['bay_number'] as String,
    plate: json['plate'] as String?,
    vehicleDetails: json['vehicle_details'] as String?,
  );
}

final parkingRepositoryProvider = Provider<ParkingRepository>((ref) {
  return ParkingRepository(Supabase.instance.client);
});

/// Bays for a specific house (admin houses page + resident profile).
final houseParkingProvider = FutureProvider.autoDispose
    .family<List<ParkingBay>, String>((ref, houseId) {
      return ref.read(parkingRepositoryProvider).baysForHouse(houseId);
    });

/// The signed-in resident's own bays (their profile).
final myParkingProvider = FutureProvider.autoDispose<List<ParkingBay>>((ref) {
  return ref.read(parkingRepositoryProvider).myBays();
});

class ParkingRepository {
  final SupabaseClient _supabase;
  ParkingRepository(this._supabase);

  Future<List<ParkingBay>> baysForHouse(String houseId) async {
    final rows = await _supabase
        .from('parking_bays')
        .select()
        .eq('house_id', houseId)
        .order('bay_number');
    return (rows as List).map((j) => ParkingBay.fromJson(j)).toList();
  }

  Future<List<ParkingBay>> myBays() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];
    final me = await _supabase
        .from('profiles')
        .select('house_id')
        .eq('id', uid)
        .maybeSingle();
    final houseId = me?['house_id'] as String?;
    if (houseId == null) return [];
    return baysForHouse(houseId);
  }

  // --- admin ---
  Future<void> addBay(String houseId, String bayNumber) async {
    await _supabase.from('parking_bays').insert({
      'house_id': houseId,
      'bay_number': bayNumber,
    });
  }

  Future<void> deleteBay(String id) async {
    await _supabase.from('parking_bays').delete().eq('id', id);
  }

  // --- resident: assign their plate to a bay ---
  Future<void> assignPlate(String bayId, String? plate, String? details) async {
    await _supabase
        .from('parking_bays')
        .update({
          'plate': (plate?.trim().isEmpty ?? true) ? null : plate!.trim(),
          'vehicle_details': (details?.trim().isEmpty ?? true)
              ? null
              : details!.trim(),
        })
        .eq('id', bayId);
  }
}
