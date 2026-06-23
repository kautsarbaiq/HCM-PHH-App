import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketService {
  final String id;
  final String businessName;
  final String? category;
  final String? phone;
  final String? description;
  final double rating;
  final bool isVerified;
  final DateTime? createdAt;

  MarketService({
    required this.id,
    required this.businessName,
    this.category,
    this.phone,
    this.description,
    required this.rating,
    this.isVerified = true,
    this.createdAt,
  });

  factory MarketService.fromJson(Map<String, dynamic> json) {
    final r = json['rating'];
    final created = json['created_at'];
    return MarketService(
      id: json['id'].toString(),
      businessName: json['business_name'] as String,
      category: json['category'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      rating: r is num ? r.toDouble() : double.tryParse('$r') ?? 0,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: created == null ? null : DateTime.tryParse('$created'),
    );
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(Supabase.instance.client);
});

class MarketplaceRepository {
  final SupabaseClient _supabase;

  MarketplaceRepository(this._supabase);

  Future<List<MarketService>> getServices() async {
    final response = await _supabase
        .from('marketplace_services')
        .select()
        .order('rating', ascending: false);
    return (response as List)
        .map((json) => MarketService.fromJson(json))
        .toList();
  }

  Future<List<MarketService>> getAllServices() async {
    final response = await _supabase
        .from('marketplace_services')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((json) => MarketService.fromJson(json))
        .toList();
  }

  Future<void> createService({
    required String businessName,
    String? category,
    String? phone,
    String? description,
    double rating = 5.0,
    bool isVerified = true,
  }) async {
    await _supabase.from('marketplace_services').insert({
      'business_name': businessName,
      'category': category,
      'phone': phone,
      'description': description,
      'rating': rating,
      'is_verified': isVerified,
    });
  }

  Future<void> updateService(String id, Map<String, dynamic> updates) async {
    await _supabase.from('marketplace_services').update(updates).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('marketplace_services').delete().eq('id', id);
  }
}
