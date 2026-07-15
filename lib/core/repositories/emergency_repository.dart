import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/brand.dart';

class EmergencyAlert {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String triggeredBy;
  final String status;
  final String createdAt;
  // HCA extras (points 10-12): which house pressed the alert + how it was
  // cleared. Null on PHH / older rows.
  final String? houseId;
  final String? houseNumber;
  final String? triggeredByName;
  final String? clearedByName;
  final String? clearedAt;
  final String? clearRemarks;

  EmergencyAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.triggeredBy,
    required this.status,
    required this.createdAt,
    this.houseId,
    this.houseNumber,
    this.triggeredByName,
    this.clearedByName,
    this.clearedAt,
    this.clearRemarks,
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
      houseId: json['house_id'] as String?,
      houseNumber: (json['houses'] is Map)
          ? (json['houses']['house_number'] as String?)
          : null,
      triggeredByName: (json['trigger_profile'] is Map)
          ? (json['trigger_profile']['full_name'] as String?)
          : null,
      clearedByName: (json['clearer'] is Map)
          ? (json['clearer']['full_name'] as String?)
          : null,
      clearedAt: json['cleared_at'] as String?,
      clearRemarks: json['clear_remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'triggered_by': triggeredBy,
      'status': status,
      // HCA-only column; PHH's table doesn't have it.
      if (!Brand.isPhh && houseId != null) 'house_id': houseId,
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

/// Full alert history (active + cleared), newest first — the "alert history
/// report" (point 11). HCA admin portal.
final alertHistoryProvider = FutureProvider.autoDispose<List<EmergencyAlert>>((
  ref,
) {
  return ref.watch(emergencyRepositoryProvider).getAlertHistory();
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

  /// Resolve the resident's house number for alert labelling ("House 10").
  Future<String?> houseNumberOf(String? houseId) async {
    if (houseId == null) return null;
    try {
      final row = await _supabase
          .from('houses')
          .select('house_number')
          .eq('id', houseId)
          .maybeSingle();
      return row?['house_number'] as String?;
    } catch (_) {
      return null;
    }
  }

  Stream<List<EmergencyAlert>> listenToActiveEmergencies() {
    // NOTE: no `.eq('status', ...)` on the stream — a server-side stream
    // filter does not reliably DROP rows that get updated out of the filter,
    // which left cleared alerts stuck on screen until an app restart
    // (point 13). Filtering client-side means an update to 'Resolved'
    // removes the alert instantly.
    return _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (maps) => maps
              .map((map) => EmergencyAlert.fromJson(map))
              .where((a) => a.status == 'Active')
              .toList(),
        );
  }

  /// Mark an emergency as cleared. On HCA also records WHO cleared it, WHEN
  /// and their remarks (points 11-12).
  Future<void> resolveEmergency(String id, {String? remarks}) async {
    final updates = <String, dynamic>{'status': 'Resolved'};
    if (!Brand.isPhh) {
      updates['cleared_by'] = _supabase.auth.currentUser?.id;
      updates['cleared_at'] = DateTime.now().toUtc().toIso8601String();
      if (remarks != null && remarks.trim().isNotEmpty) {
        updates['clear_remarks'] = remarks.trim();
      }
    }
    await _supabase.from('emergencies').update(updates).eq('id', id);
  }

  /// Alert history report: every alert with house, triggerer and clearer.
  Future<List<EmergencyAlert>> getAlertHistory() async {
    final rows = await _supabase
        .from('emergencies')
        .select(
          '*, houses(house_number), '
          'trigger_profile:profiles!emergencies_triggered_by_fkey(full_name), '
          'clearer:profiles!emergencies_cleared_by_fkey(full_name)',
        )
        .order('created_at', ascending: false);
    return (rows as List).map((j) => EmergencyAlert.fromJson(j)).toList();
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
