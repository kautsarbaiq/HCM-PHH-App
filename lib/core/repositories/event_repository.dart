import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityEvent {
  final String id;
  final String title;
  final String date; // ISO timestamp (events.event_date)
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

  bool isAttending(String userId) => attendees.contains(userId);

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    final attendees = (json['attendees'] as List<dynamic>?) ?? [];
    return CommunityEvent(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      // Live column is `event_date`; fall back to `date` for older shapes.
      date: (json['event_date'] ?? json['date'] ?? '').toString(),
      location: json['location'] as String? ?? '',
      attending: attendees.length,
      capacity: json['capacity'] as int? ?? 50,
      attendees: attendees,
      createdAt: (json['created_at'] ?? '').toString(),
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
    final response = await _supabase
        .from('events')
        .select()
        .order('event_date', ascending: true);

    return (response as List)
        .map((json) => CommunityEvent.fromJson(json))
        .toList();
  }

  /// Toggle the current user's RSVP for an event. Backed by the
  /// `toggle_event_rsvp(p_event_id)` RPC which atomically mutates the
  /// `attendees` JSONB array (see supabase_realize.sql).
  Future<void> toggleRsvp(String eventId) async {
    await _supabase.rpc('toggle_event_rsvp', params: {'p_event_id': eventId});
  }
}
