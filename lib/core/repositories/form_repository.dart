import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppForm {
  final String id;
  final String title;
  final String? description;
  final String? category;

  AppForm({
    required this.id,
    required this.title,
    this.description,
    this.category,
  });

  factory AppForm.fromJson(Map<String, dynamic> json) {
    return AppForm(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
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
}
