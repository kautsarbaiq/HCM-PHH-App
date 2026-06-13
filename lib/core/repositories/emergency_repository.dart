import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyAlert {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String triggeredBy;
  final String status;
  final String createdAt;

  EmergencyAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.triggeredBy,
    required this.status,
    required this.createdAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'].toString(),
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      triggeredBy: json['triggered_by'] as String,
      status: json['status'] as String? ?? 'Active',
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'triggered_by': triggeredBy,
      'status': status,
    };
  }
}

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(Supabase.instance.client);
});

class EmergencyRepository {
  final SupabaseClient _supabase;

  EmergencyRepository(this._supabase);

  Future<void> triggerAlert(EmergencyAlert alert) async {
    try {
      await _supabase.from('emergencies').insert(alert.toJson());
    } catch (e) {
      print('Error triggering emergency: $e');
      throw Exception('Failed to trigger emergency alert. Please call authorities directly!');
    }
  }

  Stream<List<EmergencyAlert>> listenToActiveEmergencies() {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('status', 'Active')
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => EmergencyAlert.fromJson(map)).toList());
  }
}
