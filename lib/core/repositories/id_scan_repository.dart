import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A resident's scanned ID document with the fields extracted by the AI.
class IdScan {
  final String id;
  final String? userId;
  final String? residentName; // joined from profiles for the admin view
  final String docType;
  final String fullName;
  final String idNumber;
  final String nationality;
  final String address;
  final String validity;
  final String className;
  final String? imageUrl;
  final String createdAt;

  IdScan({
    required this.id,
    this.userId,
    this.residentName,
    required this.docType,
    required this.fullName,
    required this.idNumber,
    required this.nationality,
    required this.address,
    required this.validity,
    required this.className,
    this.imageUrl,
    required this.createdAt,
  });

  factory IdScan.fromJson(Map<String, dynamic> j) {
    final profiles = j['profiles'];
    return IdScan(
      id: j['id'].toString(),
      userId: j['user_id'] as String?,
      residentName: profiles is Map ? profiles['full_name'] as String? : null,
      docType: j['doc_type'] as String? ?? '',
      fullName: j['full_name'] as String? ?? '',
      idNumber: j['id_number'] as String? ?? '',
      nationality: j['nationality'] as String? ?? '',
      address: j['address'] as String? ?? '',
      validity: j['validity'] as String? ?? '',
      className: j['class'] as String? ?? '',
      imageUrl: j['image_url'] as String?,
      createdAt: j['created_at'] as String? ?? '',
    );
  }
}

final idScanRepositoryProvider = Provider<IdScanRepository>((ref) {
  return IdScanRepository(Supabase.instance.client);
});

/// The signed-in resident's own scans.
final myIdScansProvider = FutureProvider.autoDispose<List<IdScan>>((ref) {
  return ref.read(idScanRepositoryProvider).getMyScans();
});

/// All scans (admin only, via admin_read RLS).
final adminIdScansProvider = FutureProvider<List<IdScan>>((ref) {
  return ref.read(idScanRepositoryProvider).getAllScans();
});

class IdScanRepository {
  final SupabaseClient _supabase;
  IdScanRepository(this._supabase);

  /// Sends the image to the `scan-id` Edge Function and returns the extracted
  /// fields (doc_type, full_name, id_number, nationality, address, validity,
  /// class). Throws with the real reason on failure.
  Future<Map<String, String>> extract(Uint8List bytes, String mediaType) async {
    final res = await _supabase.functions.invoke(
      'scan-id',
      body: {'imageBase64': base64Encode(bytes), 'mediaType': mediaType},
    );
    final data = res.data;
    if (data is Map && data['fields'] is Map) {
      final f = Map<String, dynamic>.from(data['fields'] as Map);
      return f.map((k, v) => MapEntry(k, (v ?? '').toString()));
    }
    final err = (data is Map && data['error'] != null)
        ? data['error']
        : 'unknown';
    throw Exception('Scan failed: $err');
  }

  /// Persist the (possibly edited) extracted fields + the stored image URL.
  Future<IdScan> create(Map<String, String> fields, String? imageUrl) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('You must be signed in.');
    final row = await _supabase
        .from('resident_id_scans')
        .insert({
          'user_id': uid,
          'doc_type': fields['doc_type'],
          'full_name': fields['full_name'],
          'id_number': fields['id_number'],
          'nationality': fields['nationality'],
          'address': fields['address'],
          'validity': fields['validity'],
          'class': fields['class'],
          'image_url': imageUrl,
        })
        .select()
        .single();
    return IdScan.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _supabase.from('resident_id_scans').delete().eq('id', id);
  }

  Future<List<IdScan>> getMyScans() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _supabase
        .from('resident_id_scans')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => IdScan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IdScan>> getAllScans() async {
    // Single FK user_id -> profiles(id), so the embed is unambiguous.
    final res = await _supabase
        .from('resident_id_scans')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => IdScan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
