import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityEvent {
  final String id;
  final String title;
  final String? description;
  final String date; // ISO timestamp (events.event_date)
  final String? endDate; // ISO timestamp (events.end_date), nullable
  final String location;
  final int attending;
  final int capacity;
  final List<dynamic> attendees; // array of user IDs
  final String? imageUrl;
  final String? createdBy;
  final String createdAt;

  CommunityEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.endDate,
    required this.location,
    required this.attending,
    required this.capacity,
    required this.attendees,
    this.imageUrl,
    this.createdBy,
    required this.createdAt,
  });

  bool isAttending(String userId) => attendees.contains(userId);

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    final attendees = (json['attendees'] as List<dynamic>?) ?? [];
    final endDate = json['end_date']?.toString();
    return CommunityEvent(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      // Live column is `event_date`; fall back to `date` for older shapes.
      date: (json['event_date'] ?? json['date'] ?? '').toString(),
      endDate: (endDate != null && endDate.isNotEmpty) ? endDate : null,
      location: json['location'] as String? ?? '',
      attending: attendees.length,
      capacity: json['capacity'] as int? ?? 50,
      attendees: attendees,
      imageUrl: json['image_url'] as String?,
      createdBy: json['created_by']?.toString(),
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

  /// Admin: create a new community event. `created_by` is set to the current
  /// admin user. Dates are stored as ISO 8601 timestamptz strings.
  Future<void> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime eventDate,
    DateTime? endDate,
    int capacity = 100,
    String? imageUrl,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('You must be signed in to create an event.');
    await _supabase.from('events').insert({
      'title': title,
      'description': description,
      'location': location,
      // Store in UTC so it round-trips correctly (read paths call .toLocal()).
      'event_date': eventDate.toUtc().toIso8601String(),
      'end_date': endDate?.toUtc().toIso8601String(),
      'capacity': capacity,
      'image_url': imageUrl,
      'created_by': uid,
    });
  }

  /// Admin: update an existing event with snake_case DB column keys.
  Future<void> updateEvent(String id, Map<String, dynamic> updates) async {
    await _supabase.from('events').update(updates).eq('id', id);
  }

  /// Admin: delete an event.
  Future<void> deleteEvent(String id) async {
    await _supabase.from('events').delete().eq('id', id);
  }

  /// Fetch profile rows (id + full_name) for the given attendee user IDs.
  /// Returns an empty list when [ids] is empty.
  Future<List<Map<String, dynamic>>> getAttendeeProfiles(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final response = await _supabase
        .from('profiles')
        .select('id,full_name')
        .inFilter('id', ids);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
