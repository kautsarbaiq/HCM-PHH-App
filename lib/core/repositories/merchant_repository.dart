import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'rewards_repository.dart' show RewardOffer;

// ============================================================================
// Merchant portal (boss batch 08/08 point 2). A merchant signs in, sets up
// their shop profile, publishes offers, and scans resident voucher QRs to
// redeem them. Schema: security/32_super_admin_merchant_foundation.sql
// ============================================================================

class Merchant {
  final String id;
  final String shopName;
  final String? category;
  final String? logoUrl;
  final List<String> photos;
  final String? address;
  final String? location;
  final String? contact;
  final String? description;
  final bool isActive;

  Merchant({
    required this.id,
    required this.shopName,
    this.category,
    this.logoUrl,
    this.photos = const [],
    this.address,
    this.location,
    this.contact,
    this.description,
    this.isActive = true,
  });

  factory Merchant.fromJson(Map<String, dynamic> j) => Merchant(
        id: j['id'].toString(),
        shopName: j['shop_name'] as String? ?? '',
        category: j['category'] as String?,
        logoUrl: j['logo_url'] as String?,
        photos:
            ((j['photos'] as List?) ?? const []).map((e) => '$e').toList(),
        address: j['address'] as String?,
        location: j['location'] as String?,
        contact: j['contact'] as String?,
        description: j['description'] as String?,
        isActive: j['is_active'] as bool? ?? true,
      );
}

/// One redemption of this merchant's offer.
class MerchantRedemption {
  final String id;
  final String status;
  final String? voucherCode;
  final String? redeemedAt;
  final String? offerTitle;
  final int? discountPercent;
  final String? residentName;
  final String createdAt;

  MerchantRedemption({
    required this.id,
    required this.status,
    this.voucherCode,
    this.redeemedAt,
    this.offerTitle,
    this.discountPercent,
    this.residentName,
    required this.createdAt,
  });

  bool get isRedeemed => (redeemedAt ?? '').isNotEmpty;

  factory MerchantRedemption.fromJson(Map<String, dynamic> j) {
    final offer = j['reward_offers'] as Map<String, dynamic>?;
    final owner = j['profiles'] as Map<String, dynamic>?;
    return MerchantRedemption(
      id: j['id'].toString(),
      status: j['status'] as String? ?? 'pending',
      voucherCode: j['voucher_code'] as String?,
      redeemedAt: j['redeemed_at'] as String?,
      offerTitle: offer?['title'] as String?,
      discountPercent: (offer?['discount_percent'] as num?)?.toInt(),
      residentName: owner?['full_name'] as String?,
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }
}

final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  return MerchantRepository(Supabase.instance.client);
});

/// The shop belonging to the signed-in merchant (null until they create it).
final myShopProvider = FutureProvider.autoDispose<Merchant?>((ref) {
  return ref.watch(merchantRepositoryProvider).myShop();
});

final myOffersProvider = FutureProvider.autoDispose<List<RewardOffer>>((ref) {
  return ref.watch(merchantRepositoryProvider).myOffers();
});

final myRedemptionsProvider =
    FutureProvider.autoDispose<List<MerchantRedemption>>((ref) {
  return ref.watch(merchantRepositoryProvider).myRedemptions();
});

class MerchantRepository {
  final SupabaseClient _db;
  MerchantRepository(this._db);

  Future<Merchant?> myShop() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db
        .from('merchants')
        .select()
        .eq('owner_id', uid)
        .maybeSingle();
    return row == null ? null : Merchant.fromJson(row);
  }

  Future<void> saveShop({
    String? id,
    required String shopName,
    String? category,
    String? logoUrl,
    List<String>? photos,
    String? address,
    String? location,
    String? contact,
    String? description,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    final data = <String, dynamic>{
      'owner_id': uid,
      'shop_name': shopName,
      'category': category,
      'logo_url': logoUrl,
      if (photos != null) 'photos': photos,
      'address': address,
      'location': location,
      'contact': contact,
      'description': description,
    };
    if (id == null) {
      await _db.from('merchants').insert(data);
    } else {
      await _db.from('merchants').update(data).eq('id', id);
    }
  }

  /// Upload a shop image (logo or gallery photo) to the public avatars bucket.
  Future<String> uploadShopImage(Uint8List bytes, String ext) async {
    final path =
        'merchant/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${ext == 'png' ? 'png' : 'jpeg'}',
          ),
        );
    return _db.storage.from('avatars').getPublicUrl(path);
  }

  // ---- offers ----
  Future<List<RewardOffer>> myOffers() async {
    final shop = await myShop();
    if (shop == null) return [];
    final rows = await _db
        .from('reward_offers')
        .select('*, reward_partners(name, logo_url)')
        .eq('merchant_id', shop.id)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => RewardOffer.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> createOffer({
    required String title,
    String? description,
    required int discountPercent,
    required int minStreak,
    int? voucherCount,
    String? products,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final shop = await myShop();
    if (shop == null) throw Exception('Create your shop profile first');
    String? d(DateTime? x) => x == null
        ? null
        : '${x.year.toString().padLeft(4, '0')}-'
            '${x.month.toString().padLeft(2, '0')}-'
            '${x.day.toString().padLeft(2, '0')}';
    await _db.from('reward_offers').insert({
      'merchant_id': shop.id,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'discount_percent': discountPercent,
      'min_streak': minStreak,
      if (voucherCount != null) 'voucher_count': voucherCount,
      if (products != null && products.isNotEmpty) 'products': products,
      if (startsOn != null) 'starts_on': d(startsOn),
      if (endsOn != null) 'ends_on': d(endsOn),
    });
  }

  Future<void> setOfferActive(String id, bool active) async {
    await _db.from('reward_offers').update({'is_active': active}).eq('id', id);
  }

  Future<void> deleteOffer(String id) async {
    await _db.from('reward_offers').delete().eq('id', id);
  }

  // ---- redemptions ----
  Future<List<MerchantRedemption>> myRedemptions() async {
    final shop = await myShop();
    if (shop == null) return [];
    final offers = await _db
        .from('reward_offers')
        .select('id')
        .eq('merchant_id', shop.id);
    final ids =
        (offers as List).map((o) => o['id'].toString()).toList();
    if (ids.isEmpty) return [];
    final rows = await _db
        .from('reward_claims')
        .select('*, reward_offers(title, discount_percent), '
            'profiles!reward_claims_owner_id_fkey(full_name)')
        .inFilter('offer_id', ids)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => MerchantRedemption.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// A merchant scanned a resident's voucher QR. The QR carries the public
  /// redeem URL, so pull the token out of whatever the scanner returned.
  static String? tokenFromScan(String raw) {
    final s = raw.trim();
    final uuid = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(s);
    return uuid?.group(0);
  }
}
