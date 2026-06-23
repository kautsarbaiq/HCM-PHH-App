import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDocument {
  final String id;
  final String title;
  final String? category;
  final String? fileUrl;
  final String? fileSize;

  AppDocument({
    required this.id,
    required this.title,
    this.category,
    this.fileUrl,
    this.fileSize,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) {
    return AppDocument(
      id: json['id'].toString(),
      title: json['title'] as String,
      category: json['category'] as String?,
      fileUrl: json['file_url'] as String?,
      fileSize: json['file_size'] as String?,
    );
  }
}

class ResidentDocument {
  final String id;
  final String title;
  final String? referenceCode;
  final String? documentType;
  final String? fileUrl;

  ResidentDocument({
    required this.id,
    required this.title,
    this.referenceCode,
    this.documentType,
    this.fileUrl,
  });

  factory ResidentDocument.fromJson(Map<String, dynamic> json) {
    return ResidentDocument(
      id: json['id'].toString(),
      title: json['title'] as String,
      referenceCode: json['reference_code'] as String?,
      documentType: json['document_type'] as String?,
      fileUrl: json['file_url'] as String?,
    );
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(Supabase.instance.client);
});

class DocumentRepository {
  final SupabaseClient _supabase;

  DocumentRepository(this._supabase);

  Future<List<AppDocument>> getDocuments() async {
    final response = await _supabase
        .from('documents')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => AppDocument.fromJson(json))
        .toList();
  }

  /// The current resident's personal documents. Filtered by user_id explicitly
  /// (NOT relying on RLS — the admin read policy is OR'd in and would otherwise
  /// return every resident's documents when an admin hits this).
  Future<List<ResidentDocument>> getMyResidentDocuments() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];
    final response = await _supabase
        .from('resident_documents')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => ResidentDocument.fromJson(json))
        .toList();
  }

  /// Adds a personal document for the signed-in resident. [filePath] is the
  /// stored object path returned by StorageRepository.uploadResidentDocument.
  Future<void> addResidentDocument({
    required String title,
    String? documentType,
    String? referenceCode,
    required String filePath,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    await _supabase.from('resident_documents').insert({
      'user_id': uid,
      'title': title,
      'document_type': documentType,
      'reference_code': referenceCode,
      'file_url': filePath,
    });
  }

  /// All personal documents belonging to a specific resident — used by the
  /// admin panel (RLS must allow admins to SELECT every resident's documents).
  Future<List<ResidentDocument>> getResidentDocumentsForUser(
    String userId,
  ) async {
    final response = await _supabase
        .from('resident_documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => ResidentDocument.fromJson(json))
        .toList();
  }

  /// Edit a resident's own document metadata (RLS scopes the update to the
  /// owner). Pass only the fields you want to change.
  Future<void> updateResidentDocument(
    String id, {
    String? title,
    String? documentType,
    String? referenceCode,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (documentType != null) updates['document_type'] = documentType;
    if (referenceCode != null) updates['reference_code'] = referenceCode;
    if (updates.isEmpty) return;
    await _supabase.from('resident_documents').update(updates).eq('id', id);
  }

  /// Delete a resident's own document row (RLS scopes the delete to the owner).
  Future<void> deleteResidentDocument(String id) async {
    await _supabase.from('resident_documents').delete().eq('id', id);
  }
}
