import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int sortOrder;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  BannerItem copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? linkUrl,
    bool? isActive,
    int? sortOrder,
  }) {
    return BannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    };
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(Supabase.instance.client);
});

class BannerRepository {
  final SupabaseClient _supabase;

  BannerRepository(this._supabase);

  Future<List<BannerItem>> getAllBanners() async {
    final response = await _supabase
        .from('banners')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => BannerItem.fromJson(json)).toList();
  }

  Future<BannerItem> createBanner(BannerItem banner) async {
    final response = await _supabase
        .from('banners')
        .insert(banner.toJson())
        .select()
        .single();

    return BannerItem.fromJson(response);
  }

  Future<void> updateBanner(String id, Map<String, dynamic> updates) async {
    await _supabase.from('banners').update(updates).eq('id', id);
  }

  Future<void> deleteBanner(String id) async {
    await _supabase.from('banners').delete().eq('id', id);
  }
}
