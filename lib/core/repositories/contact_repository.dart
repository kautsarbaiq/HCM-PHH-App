import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? hours;
  final String? category;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.hours,
    this.category,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'].toString(),
      name: json['name'] as String,
      phone: json['phone'] as String,
      hours: json['hours'] as String?,
      category: json['category'] as String?,
    );
  }
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(Supabase.instance.client);
});

class ContactRepository {
  final SupabaseClient _supabase;

  ContactRepository(this._supabase);

  Future<List<EmergencyContact>> getContacts() async {
    final response = await _supabase
        .from('emergency_contacts')
        .select()
        .order('sort_order', ascending: true);
    return (response as List).map((json) => EmergencyContact.fromJson(json)).toList();
  }
}
