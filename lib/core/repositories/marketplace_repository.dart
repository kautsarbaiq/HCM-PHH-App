import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketService {
  final String id;
  final String businessName;
  final String? category;
  final String? phone;
  final String? description;
  final double rating;

  MarketService({
    required this.id,
    required this.businessName,
    this.category,
    this.phone,
    this.description,
    required this.rating,
  });

  factory MarketService.fromJson(Map<String, dynamic> json) {
    final r = json['rating'];
    return MarketService(
      id: json['id'].toString(),
      businessName: json['business_name'] as String,
      category: json['category'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      rating: r is num ? r.toDouble() : double.tryParse('$r') ?? 0,
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
    return (response as List).map((json) => MarketService.fromJson(json)).toList();
  }
}
