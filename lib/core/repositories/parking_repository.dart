import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A parking bay belonging to a house (HCA points 14-15). Admins create bays
/// with numbers; the resident assigns their car to a bay.
class ParkingBay {
  final String id;
  final String houseId;
  final String bayNumber;
  final String? plate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? vehicleColor;
  final String? vehicleDetails; // legacy free-text, kept for old rows

  ParkingBay({
    required this.id,
    required this.houseId,
    required this.bayNumber,
    this.plate,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleColor,
    this.vehicleDetails,
  });

  factory ParkingBay.fromJson(Map<String, dynamic> json) => ParkingBay(
    id: json['id'] as String,
    houseId: json['house_id'] as String,
    bayNumber: json['bay_number'] as String,
    plate: json['plate'] as String?,
    vehicleMake: json['vehicle_make'] as String?,
    vehicleModel: json['vehicle_model'] as String?,
    vehicleYear: json['vehicle_year'] as String?,
    vehicleColor: json['vehicle_color'] as String?,
    vehicleDetails: json['vehicle_details'] as String?,
  );

  /// "Honda • Civic • 2020 • Red" from whichever fields are filled, falling
  /// back to the legacy free-text details for rows saved before the split.
  String? get vehicleSummary {
    final parts = [vehicleMake, vehicleModel, vehicleYear, vehicleColor]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return vehicleDetails;
    return parts.join(' • ');
  }
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

/// Every bay grouped by house — the admin houses table shows each house's bay
/// numbers in a column.
final allParkingBaysProvider =
    FutureProvider.autoDispose<Map<String, List<ParkingBay>>>((ref) async {
      final bays = await ref.read(parkingRepositoryProvider).allBays();
      final byHouse = <String, List<ParkingBay>>{};
      for (final b in bays) {
        (byHouse[b.houseId] ??= []).add(b);
      }
      return byHouse;
    });

class ParkingRepository {
  final SupabaseClient _supabase;
  ParkingRepository(this._supabase);

  Future<List<ParkingBay>> baysForHouse(String houseId) async {
    final rows = await _supabase
        .from('parking_bays')
        .select()
        .eq('house_id', houseId)
        .order('bay_number', ascending: true);
    return (rows as List).map((j) => ParkingBay.fromJson(j)).toList();
  }

  Future<List<ParkingBay>> allBays() async {
    final rows = await _supabase
        .from('parking_bays')
        .select()
        .order('bay_number', ascending: true);
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

  // --- resident: assign their car to a bay ---
  Future<void> assignVehicle(
    String bayId, {
    String? plate,
    String? make,
    String? model,
    String? year,
    String? color,
  }) async {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    await _supabase
        .from('parking_bays')
        .update({
          'plate': clean(plate),
          'vehicle_make': clean(make),
          'vehicle_model': clean(model),
          'vehicle_year': clean(year),
          'vehicle_color': clean(color),
          // Saving via the structured form supersedes the legacy free-text —
          // otherwise a cleared bay would keep showing the old car forever.
          'vehicle_details': null,
        })
        .eq('id', bayId);
  }
}
