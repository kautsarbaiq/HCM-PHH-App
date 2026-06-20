import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Poll {
  final String id;
  final String title; // live column is `question`
  final String endDate; // live column is `expires_at`
  final List<dynamic> options; // [{'label': 'Yes', 'votes': 62}, ...]
  final List<dynamic> voters; // ['user_id_1', ...]
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
      title: (json['question'] ?? json['title'] ?? '').toString(),
      endDate: (json['expires_at'] ?? json['end_date'] ?? '').toString(),
      options: json['options'] as List<dynamic>? ?? [],
      voters: json['voters'] as List<dynamic>? ?? [],
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  int get totalVotes {
    int total = 0;
    for (var opt in options) {
      total += (opt['votes'] as int? ?? 0);
    }
    return total;
  }

  bool hasVoted(String userId) => voters.contains(userId);
}

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepository(Supabase.instance.client);
});

class PollRepository {
  final SupabaseClient _supabase;

  PollRepository(this._supabase);

  Future<List<Poll>> getAllPolls() async {
    final response = await _supabase
        .from('polls')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Poll.fromJson(json)).toList();
  }

  /// Cast the current user's vote for an option (by index). Backed by the
  /// `submit_poll_vote(p_poll_id, p_option_index)` RPC which atomically appends
  /// the voter and increments the option's vote count (see supabase_realize.sql).
  Future<void> submitVote(String pollId, int optionIndex) async {
    await _supabase.rpc(
      'submit_poll_vote',
      params: {'p_poll_id': pollId, 'p_option_index': optionIndex},
    );
  }
}
