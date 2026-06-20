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

  /// The current resident's personal documents (RLS scopes to user_id = auth.uid()).
  Future<List<ResidentDocument>> getMyResidentDocuments() async {
    final response = await _supabase
        .from('resident_documents')
        .select()
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => ResidentDocument.fromJson(json))
        .toList();
  }
}
