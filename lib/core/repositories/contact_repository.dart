import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? hours;
  final String? category;
  final int sortOrder;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.hours,
    this.category,
    this.sortOrder = 0,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hours: json['hours'] as String?,
      category: json['category'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(Supabase.instance.client);
});

/// Admin-facing list of all emergency contacts (admin RLS allows full read).
final adminContactsProvider = FutureProvider<List<EmergencyContact>>((ref) {
  return ref.watch(contactRepositoryProvider).getContacts();
});

class ContactRepository {
  final SupabaseClient _supabase;

  ContactRepository(this._supabase);

  Future<List<EmergencyContact>> getContacts() async {
    final response = await _supabase
        .from('emergency_contacts')
        .select()
        .order('sort_order', ascending: true);
    return (response as List)
        .map((json) => EmergencyContact.fromJson(json))
        .toList();
  }

  Future<void> createContact({
    required String name,
    required String phone,
    String? hours,
    String? category,
    int sortOrder = 0,
  }) async {
    await _supabase.from('emergency_contacts').insert({
      'name': name,
      'phone': phone,
      'hours': hours,
      'category': category,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateContact(String id, Map<String, dynamic> updates) async {
    await _supabase.from('emergency_contacts').update(updates).eq('id', id);
  }

  Future<void> deleteContact(String id) async {
    await _supabase.from('emergency_contacts').delete().eq('id', id);
  }
}
