import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_repository.dart'; // For House
import 'profile_repository.dart'; // For Profile

class Visitor {
  final String id;
  final String visitorName;
  final String purpose;
  final String? vehiclePlate;
  final String houseId;
  final String? qrToken;
  final String status;
  final String? expectedAt;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String createdBy;
  final String? checkedInBy;
  final String registrationType;
  // Evidence photos captured by the guard at walk-in registration.
  final String? visitorPhotoUrl;
  final String? vehiclePhotoUrl;
  final String? licensePhotoUrl;

  // Joined fields
  final House? house;
  final Profile? creator;

  Visitor({
    required this.id,
    required this.visitorName,
    required this.purpose,
    this.vehiclePlate,
    required this.houseId,
    this.qrToken,
    required this.status,
    this.expectedAt,
    this.checkedInAt,
    this.checkedOutAt,
    required this.createdBy,
    this.checkedInBy,
    required this.registrationType,
    this.visitorPhotoUrl,
    this.vehiclePhotoUrl,
    this.licensePhotoUrl,
    this.house,
    this.creator,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String,
      visitorName: json['visitor_name'] as String,
      purpose: json['purpose'] as String? ?? 'Guest',
      vehiclePlate: json['vehicle_plate'] as String?,
      houseId: json['house_id'] as String,
      qrToken: json['qr_token'] as String?,
      status: json['status'] as String,
      expectedAt: json['expected_at'] as String?,
      checkedInAt: json['checked_in_at'] as String?,
      checkedOutAt: json['checked_out_at'] as String?,
      createdBy: json['created_by'] as String,
      checkedInBy: json['checked_in_by'] as String?,
      registrationType: json['registration_type'] as String,
      visitorPhotoUrl: json['visitor_photo_url'] as String?,
      vehiclePhotoUrl: json['vehicle_photo_url'] as String?,
      licensePhotoUrl: json['license_photo_url'] as String?,
      house: json['houses'] != null ? House.fromJson(json['houses'] as Map<String, dynamic>) : null,
      creator: json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'visitor_name': visitorName,
      'purpose': purpose,
      'vehicle_plate': vehiclePlate,
      'house_id': houseId,
      'registration_type': registrationType,
      'created_by': createdBy,
      'status': status,
    };
    if (qrToken != null) {
      data['qr_token'] = qrToken;
    }
    if (expectedAt != null) {
      data['expected_at'] = expectedAt;
    }
    return data;
  }
}

final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  return VisitorRepository(Supabase.instance.client);
});

class VisitorRepository {
  final SupabaseClient _supabase;

  VisitorRepository(this._supabase);

  Future<List<Visitor>> getAllVisitors() async {
    final response = await _supabase
        .from('visitors')
        .select('*, houses(*), profiles!visitors_created_by_fkey(*)')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Visitor.fromJson(json)).toList();
  }

  Future<List<Visitor>> getVisitorsForHouse(String houseId) async {
    final response = await _supabase
        .from('visitors')
        .select('*, houses(*), profiles!visitors_created_by_fkey(*)')
        .eq('house_id', houseId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Visitor.fromJson(json)).toList();
  }

  Future<Visitor> createVisitor(Visitor visitor) async {
    final response = await _supabase
        .from('visitors')
        .insert(visitor.toJson())
        .select('*, houses(*), profiles!visitors_created_by_fkey(*)')
        .single();
        
    return Visitor.fromJson(response);
  }

  Future<Visitor> updateVisitorStatus(String id, String status) async {
    // Stamp the moment of the transition so the logs can show real
    // check-in / check-out times (not just the status label).
    final now = DateTime.now().toUtc().toIso8601String();
    final update = <String, dynamic>{'status': status};
    if (status == 'checked_in') {
      update['checked_in_at'] = now;
      update['checked_in_by'] = _supabase.auth.currentUser?.id;
    } else if (status == 'checked_out') {
      update['checked_out_at'] = now;
    }

    final response = await _supabase
        .from('visitors')
        .update(update)
        .eq('id', id)
        .select('*, houses(*), profiles!visitors_created_by_fkey(*)')
        .single();

    return Visitor.fromJson(response);
  }

  Future<void> deleteVisitor(String id) async {
    await _supabase.from('visitors').delete().eq('id', id);
  }

  Future<Visitor?> getVisitorByQrToken(String token) async {
    try {
      final response = await _supabase
          .from('visitors')
          .select('*, houses(*), profiles!visitors_created_by_fkey(*)')
          .eq('qr_token', token)
          .single();
          
      return Visitor.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
