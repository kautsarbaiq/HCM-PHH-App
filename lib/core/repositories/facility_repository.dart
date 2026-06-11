import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Booking {
  final String id;
  final String facilityName;
  final String date;
  final String time;
  final String status;
  final String bookedBy;
  final String createdAt;

  Booking({
    required this.id,
    required this.facilityName,
    required this.date,
    required this.time,
    required this.status,
    required this.bookedBy,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      facilityName: json['facility_name'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String? ?? 'Pending',
      bookedBy: json['booked_by'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility_name': facilityName,
      'date': date,
      'time': time,
      'status': status,
      'booked_by': bookedBy,
    };
  }
}

final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  return FacilityRepository(Supabase.instance.client);
});

class FacilityRepository {
  final SupabaseClient _supabase;

  FacilityRepository(this._supabase);

  Future<List<Booking>> getMyBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('booked_by', userId)
          .order('date', ascending: true);
      
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await _supabase
        .from('bookings')
        .insert(booking.toJson())
        .select()
        .single();
        
    return Booking.fromJson(response);
  }
}
