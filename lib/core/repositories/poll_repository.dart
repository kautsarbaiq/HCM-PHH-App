import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Poll {
  final String id;
  final String title;
  final String endDate;
  final List<dynamic> options; // [{'label': 'Yes', 'votes': 62, 'percent': 0.70}, ...]
  final List<dynamic> voters; // ['user_id_1', 'user_id_2']
  final String createdAt;

  Poll({
    required this.id,
    required this.title,
    required this.endDate,
    required this.options,
    required this.voters,
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'].toString(),
      title: json['title'] as String,
      endDate: json['end_date'] as String,
      options: json['options'] as List<dynamic>? ?? [],
      voters: json['voters'] as List<dynamic>? ?? [],
      createdAt: json['created_at'] as String,
    );
  }

  int get totalVotes {
    int total = 0;
    for (var opt in options) {
      total += (opt['votes'] as int? ?? 0);
    }
    return total;
  }
}

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepository(Supabase.instance.client);
});

class PollRepository {
  final SupabaseClient _supabase;

  PollRepository(this._supabase);

  Future<List<Poll>> getAllPolls() async {
    try {
      final response = await _supabase
          .from('polls')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Poll.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching polls: $e');
      return [];
    }
  }

  Future<void> submitVote(String pollId, String optionLabel, String userId) async {
    throw UnimplementedError('Submitting a vote requires an RPC function to atomically update the JSONB column in Supabase');
  }
}
