import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String createdBy;
  final String createdAt;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'created_by': createdBy,
    };
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(Supabase.instance.client);
});

class TicketRepository {
  final SupabaseClient _supabase;

  TicketRepository(this._supabase);

  Future<List<Ticket>> getMyTickets(String userId) async {
    try {
      final response = await _supabase
          .from('tickets')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching tickets: $e');
      // If table doesn't exist, we return empty list for now
      return [];
    }
  }

  Future<Ticket> createTicket(Ticket ticket) async {
    final response = await _supabase
        .from('tickets')
        .insert(ticket.toJson())
        .select()
        .single();
        
    return Ticket.fromJson(response);
  }
}
