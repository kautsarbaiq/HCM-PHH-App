import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppForm {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final bool isActive;

  AppForm({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.isActive = true,
  });

  factory AppForm.fromJson(Map<String, dynamic> json) {
    return AppForm(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class FormSubmission {
  final String id;
  final String formId;
  final String formTitle;
  final String userId;
  final String residentName;
  final String status;
  final String createdAt;

  FormSubmission({
    required this.id,
    required this.formId,
    required this.formTitle,
    required this.userId,
    required this.residentName,
    required this.status,
    required this.createdAt,
  });

  factory FormSubmission.fromJson(Map<String, dynamic> json) {
    final form = json['forms'] as Map<String, dynamic>?;
    final profile = json['profiles'] as Map<String, dynamic>?;
    return FormSubmission(
      id: json['id'].toString(),
      formId: json['form_id']?.toString() ?? '',
      formTitle: form?['title'] as String? ?? 'Unknown form',
      userId: json['user_id']?.toString() ?? '',
      residentName: profile?['full_name'] as String? ?? 'Unknown resident',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

final formRepositoryProvider = Provider<FormRepository>((ref) {
  return FormRepository(Supabase.instance.client);
});

class FormRepository {
  final SupabaseClient _supabase;

  FormRepository(this._supabase);

  Future<List<AppForm>> getForms() async {
    final response = await _supabase
        .from('forms')
        .select()
        .eq('is_active', true)
        .order('title', ascending: true);
    return (response as List).map((json) => AppForm.fromJson(json)).toList();
  }

  /// Form IDs the current resident has already submitted.
  Future<Set<String>> getMySubmittedFormIds() async {
    final response = await _supabase.from('form_submissions').select('form_id');
    return (response as List).map((e) => e['form_id'].toString()).toSet();
  }

  Future<void> submitForm(String formId) async {
    await _supabase.from('form_submissions').insert({
      'form_id': formId,
      'user_id': _supabase.auth.currentUser?.id,
      'status': 'pending',
    });
  }

  // --- Admin: form catalog ---

  /// All forms (including inactive), newest first.
  Future<List<AppForm>> getAllForms() async {
    final response = await _supabase
        .from('forms')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => AppForm.fromJson(json)).toList();
  }

  Future<void> createForm({
    required String title,
    String? description,
    String? category,
    bool isActive = true,
  }) async {
    await _supabase.from('forms').insert({
      'title': title,
      'description': description,
      'category': category,
      'is_active': isActive,
    });
  }

  Future<void> updateForm(String id, Map<String, dynamic> updates) async {
    await _supabase.from('forms').update(updates).eq('id', id);
  }

  Future<void> deleteForm(String id) async {
    await _supabase.from('forms').delete().eq('id', id);
  }

  // --- Admin: submissions inbox ---

  Future<List<FormSubmission>> getAllSubmissions() async {
    final response = await _supabase
        .from('form_submissions')
        .select('*, forms(title), profiles(full_name)')
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => FormSubmission.fromJson(json))
        .toList();
  }

  Future<void> updateSubmissionStatus(String id, String status) async {
    await _supabase
        .from('form_submissions')
        .update({'status': status})
        .eq('id', id);
  }
}
