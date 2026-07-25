import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Rewards program (meeting 20/07 point 9). Owners unlock partner-brand discount
// offers by paying consecutive monthly bills on time; they claim an offer and
// an admin approves it with a voucher code. See security/25_rewards_program.sql.
// ============================================================================

class RewardPartner {
  final String id;
  final String name;
  final String? category;
  final bool isActive;

  RewardPartner({
    required this.id,
    required this.name,
    this.category,
    this.isActive = true,
  });

  factory RewardPartner.fromJson(Map<String, dynamic> j) => RewardPartner(
        id: j['id'].toString(),
        name: j['name'] as String? ?? '',
        category: j['category'] as String?,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class RewardOffer {
  final String id;
  final String partnerId;
  final String partnerName;
  final String title;
  final String? description;
  final int discountPercent;
  final int minStreak;
  final bool isActive;

  RewardOffer({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.title,
    this.description,
    required this.discountPercent,
    required this.minStreak,
    this.isActive = true,
  });

  factory RewardOffer.fromJson(Map<String, dynamic> j) => RewardOffer(
        id: j['id'].toString(),
        partnerId: (j['partner_id'] ?? '').toString(),
        partnerName: (j['reward_partners'] is Map)
            ? (j['reward_partners']['name'] as String? ?? '')
            : '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        discountPercent: (j['discount_percent'] as num?)?.toInt() ?? 0,
        minStreak: (j['min_streak'] as num?)?.toInt() ?? 0,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class RewardClaim {
  final String id;
  final String offerId;
  final String ownerId;
  final String status; // pending | approved | rejected
  final String? voucherCode;
  final String? adminRemarks;
  final String createdAt;
  // Joined
  final String? offerTitle;
  final int? discountPercent;
  final String? partnerName;
  final String? ownerName;

  RewardClaim({
    required this.id,
    required this.offerId,
    required this.ownerId,
    required this.status,
    this.voucherCode,
    this.adminRemarks,
    required this.createdAt,
    this.offerTitle,
    this.discountPercent,
    this.partnerName,
    this.ownerName,
  });

  factory RewardClaim.fromJson(Map<String, dynamic> j) {
    final offer = j['reward_offers'] as Map<String, dynamic>?;
    final partner = offer?['reward_partners'] as Map<String, dynamic>?;
    final owner = j['profiles'] as Map<String, dynamic>?;
    return RewardClaim(
      id: j['id'].toString(),
      offerId: (j['offer_id'] ?? '').toString(),
      ownerId: (j['owner_id'] ?? '').toString(),
      status: j['status'] as String? ?? 'pending',
      voucherCode: j['voucher_code'] as String?,
      adminRemarks: j['admin_remarks'] as String?,
      createdAt: (j['created_at'] ?? '').toString(),
      offerTitle: offer?['title'] as String?,
      discountPercent: (offer?['discount_percent'] as num?)?.toInt(),
      partnerName: partner?['name'] as String?,
      ownerName: owner?['full_name'] as String?,
    );
  }
}

/// A named owner, for the admin "grant to owner" picker.
class OwnerRef {
  final String id;
  final String name;
  OwnerRef(this.id, this.name);
}

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository(Supabase.instance.client);
});

// --- Owner-facing providers -------------------------------------------------
final myOntimeStreakProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(rewardsRepositoryProvider).myStreak();
});

final rewardOffersProvider =
    FutureProvider.autoDispose<List<RewardOffer>>((ref) {
  return ref.watch(rewardsRepositoryProvider).activeOffers();
});

final myRewardClaimsProvider =
    FutureProvider.autoDispose<List<RewardClaim>>((ref) {
  return ref.watch(rewardsRepositoryProvider).myClaims();
});

// --- Admin providers --------------------------------------------------------
final adminPartnersProvider =
    FutureProvider.autoDispose<List<RewardPartner>>((ref) {
  return ref.watch(rewardsRepositoryProvider).allPartners();
});

final adminOffersProvider = FutureProvider.autoDispose<List<RewardOffer>>((ref) {
  return ref.watch(rewardsRepositoryProvider).allOffers();
});

final adminClaimsProvider = FutureProvider.autoDispose<List<RewardClaim>>((ref) {
  return ref.watch(rewardsRepositoryProvider).allClaims();
});

class RewardsRepository {
  final SupabaseClient _db;
  RewardsRepository(this._db);

  Future<int> myStreak() async {
    final v = await _db.rpc('my_ontime_streak');
    return (v as num?)?.toInt() ?? 0;
  }

  Future<int> ownerStreak(String uid) async {
    final v = await _db.rpc('owner_ontime_streak', params: {'p_uid': uid});
    return (v as num?)?.toInt() ?? 0;
  }

  // ---- offers / partners (read) ----
  Future<List<RewardOffer>> activeOffers() async {
    final rows = await _db
        .from('reward_offers')
        .select('*, reward_partners(name)')
        .eq('is_active', true)
        .order('min_streak', ascending: true);
    return (rows as List)
        .map((j) => RewardOffer.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RewardOffer>> allOffers() async {
    final rows = await _db
        .from('reward_offers')
        .select('*, reward_partners(name)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => RewardOffer.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RewardPartner>> allPartners() async {
    final rows = await _db
        .from('reward_partners')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => RewardPartner.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---- claims ----
  Future<List<RewardClaim>> myClaims() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('reward_claims')
        .select(
            '*, reward_offers(title, discount_percent, reward_partners(name))')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => RewardClaim.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RewardClaim>> allClaims() async {
    final rows = await _db
        .from('reward_claims')
        .select(
            '*, reward_offers(title, discount_percent, reward_partners(name)), '
            'profiles!reward_claims_owner_id_fkey(full_name)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => RewardClaim.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> claimOffer(String offerId) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    await _db.from('reward_claims').insert({
      'offer_id': offerId,
      'owner_id': uid,
      'status': 'pending',
    });
  }

  // ---- admin mutations ----
  Future<void> createPartner(String name, String? category) async {
    await _db.from('reward_partners').insert({
      'name': name,
      if (category != null && category.isNotEmpty) 'category': category,
    });
  }

  Future<void> setPartnerActive(String id, bool active) async {
    await _db.from('reward_partners').update({'is_active': active}).eq('id', id);
  }

  Future<void> deletePartner(String id) async {
    await _db.from('reward_partners').delete().eq('id', id);
  }

  Future<void> createOffer({
    required String partnerId,
    required String title,
    String? description,
    required int discountPercent,
    required int minStreak,
  }) async {
    await _db.from('reward_offers').insert({
      'partner_id': partnerId,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'discount_percent': discountPercent,
      'min_streak': minStreak,
    });
  }

  Future<void> setOfferActive(String id, bool active) async {
    await _db.from('reward_offers').update({'is_active': active}).eq('id', id);
  }

  Future<void> deleteOffer(String id) async {
    await _db.from('reward_offers').delete().eq('id', id);
  }

  Future<void> decideClaim(
    String id, {
    required bool approve,
    String? voucherCode,
    String? remarks,
  }) async {
    await _db.from('reward_claims').update({
      'status': approve ? 'approved' : 'rejected',
      'decided_at': DateTime.now().toUtc().toIso8601String(),
      'decided_by': _db.auth.currentUser?.id,
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucher_code': voucherCode,
      if (remarks != null && remarks.isNotEmpty) 'admin_remarks': remarks,
    }).eq('id', id);
  }

  /// Admin grants an offer straight to an owner (manual assignment) — created
  /// already approved with a voucher.
  Future<void> grantToOwner(
    String offerId,
    String ownerId,
    String voucherCode,
  ) async {
    await _db.from('reward_claims').insert({
      'offer_id': offerId,
      'owner_id': ownerId,
      'status': 'approved',
      'voucher_code': voucherCode,
      'decided_at': DateTime.now().toUtc().toIso8601String(),
      'decided_by': _db.auth.currentUser?.id,
    });
  }

  /// Owners (house owners) in the caller's community, for the grant picker.
  Future<List<OwnerRef>> owners() async {
    final rows = await _db
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'resident')
        .eq('resident_type', 'owner')
        .order('full_name', ascending: true);
    return (rows as List)
        .map((j) => OwnerRef(
              j['id'].toString(),
              (j['full_name'] as String?)?.trim().isNotEmpty == true
                  ? j['full_name'] as String
                  : 'Owner',
            ))
        .toList();
  }
}
