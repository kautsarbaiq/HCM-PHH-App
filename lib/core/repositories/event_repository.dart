import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityEvent {
  final String id;
  final String title;
  final String date;
  final String location;
  final int attending;
  final int capacity;
  final List<dynamic> attendees; // array of user IDs
  final String createdAt;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.attending,
    required this.capacity,
    required this.attendees,
    required this.createdAt,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'].toString(),
      title: json['title'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      attending: json['attending'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 50,
      attendees: json['attendees'] as List<dynamic>? ?? [],
      createdAt: json['created_at'] as String,
    );
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(Supabase.instance.client);
});

class EventRepository {
  final SupabaseClient _supabase;

  EventRepository(this._supabase);

  Future<List<CommunityEvent>> getAllEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => CommunityEvent.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<void> toggleRsvp(String eventId, String userId, bool isCurrentlyAttending) async {
    // In a real scenario we'd use a postgres function or a separate RSVP table. 
    // Since this is a demo, we will use a postgres RPC function or just ignore actual DB complex array mutations for now
    // We will just do a dummy update for presentation purposes or skip it.
    throw UnimplementedError('RSVP toggle requires an RPC function in Supabase');
  }
}
