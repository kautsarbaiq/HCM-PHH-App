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
    // Defensive casts — a single malformed/legacy row must never break the whole
    // realtime feed (which would make ALL active alerts vanish from dashboards).
    return EmergencyAlert(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'broadcast',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      triggeredBy: json['triggered_by'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      createdAt: json['created_at'] as String? ?? '',
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

/// Live feed of currently-active emergencies, shared by the resident, admin and
/// guard dashboards. autoDispose so the realtime channel is torn down when no
/// screen is watching it (e.g. after logout).
final activeEmergenciesProvider =
    StreamProvider.autoDispose<List<EmergencyAlert>>((ref) {
      return ref.watch(emergencyRepositoryProvider).listenToActiveEmergencies();
    });

class EmergencyRepository {
  final SupabaseClient _supabase;

  EmergencyRepository(this._supabase);

  Future<void> triggerAlert(EmergencyAlert alert) async {
    try {
      await _supabase.from('emergencies').insert(alert.toJson());
    } catch (e) {
      print('Error triggering emergency: $e');
      throw Exception(
        'Failed to trigger emergency alert. Please call authorities directly!',
      );
    }
  }

  Stream<List<EmergencyAlert>> listenToActiveEmergencies() {
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('status', 'Active')
        .order('created_at', ascending: false)
        .map(
          (maps) => maps.map((map) => EmergencyAlert.fromJson(map)).toList(),
        );
  }

  /// Mark an emergency as resolved so it disappears from the active feed. Used
  /// by admin & guard from the active-emergency banner.
  Future<void> resolveEmergency(String id) async {
    await _supabase
        .from('emergencies')
        .update({'status': 'Resolved'})
        .eq('id', id);
  }

  /// Admin/guard broadcast: raise an emergency that every user will see on
  /// their dashboard. Reuses the same `emergencies` table & realtime feed.
  Future<void> broadcastEmergency({
    required String title,
    required String message,
    required String triggeredBy,
  }) async {
    await triggerAlert(
      EmergencyAlert(
        id: '',
        type: 'broadcast',
        title: title,
        subtitle: message,
        triggeredBy: triggeredBy,
        status: 'Active',
        createdAt: '',
      ),
    );
  }
}
