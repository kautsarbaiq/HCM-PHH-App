import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final bool isUrgent;
  final String publishedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.isUrgent,
    required this.publishedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isUrgent: json['is_urgent'] as bool,
      publishedAt: json['published_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'is_urgent': isUrgent,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    };
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(Supabase.instance.client);
});

class AnnouncementRepository {
  final SupabaseClient _supabase;

  AnnouncementRepository(this._supabase);

  Future<List<Announcement>> getAllAnnouncements() async {
    final response = await _supabase
        .from('announcements')
        .select()
        .order('published_at', ascending: false);

    return (response as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }

  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final response = await _supabase
        .from('announcements')
        .insert(announcement.toJson())
        .select()
        .single();

    return Announcement.fromJson(response);
  }

  Future<void> updateAnnouncement(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('announcements').update(updates).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('announcements').delete().eq('id', id);
  }
}
