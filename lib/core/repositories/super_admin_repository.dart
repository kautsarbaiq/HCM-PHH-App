import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Super Admin (boss batch 08/08 point 1). One level above the per-company
// admins in the hierarchy diagram:
//
//     SUPER ADMIN -> COMPANY (admin account) -> Residents
//
// A "company" is a community row; its admin is a profile with role='admin'
// scoped to that community. See security/32_super_admin_merchant_foundation.sql
// ============================================================================

/// Every app module a super admin can switch on/off per company.
/// Key must match what the app checks; label is what the portal shows.
const Map<String, String> kAppModules = {
  'visitor': 'Visitor Access',
  'billing': 'Billing',
  'facility': 'Facility Booking',
  'events': 'Events',
  'polling': 'E-Polling',
  'document': 'E-Documents',
  'forms': 'E-Forms',
  'market': 'Market Square',
  'rewards': 'Rewards',
  'emergency': 'Emergency / Panic',
  'parking': 'Parking',
  'idscan': 'Resident ID Scan',
};

class Company {
  final String id;
  final String code;
  final String name;
  final int residentCount;
  final String? adminName;
  final String? adminEmail;
  final Map<String, dynamic> modules;

  Company({
    required this.id,
    required this.code,
    required this.name,
    this.residentCount = 0,
    this.adminName,
    this.adminEmail,
    this.modules = const {},
  });

  /// A module is on unless explicitly switched off.
  bool isModuleOn(String key) => modules[key] != false;
  int get enabledCount =>
      kAppModules.keys.where(isModuleOn).length;
}

class MerchantAccount {
  final String id;
  final String shopName;
  final String? category;
  final String? logoUrl;
  final String? contact;
  final String? ownerEmail;
  final String? communityName;
  final bool isActive;

  MerchantAccount({
    required this.id,
    required this.shopName,
    this.category,
    this.logoUrl,
    this.contact,
    this.ownerEmail,
    this.communityName,
    this.isActive = true,
  });

  factory MerchantAccount.fromJson(Map<String, dynamic> j) {
    final owner = j['profiles'] as Map<String, dynamic>?;
    final comm = j['communities'] as Map<String, dynamic>?;
    return MerchantAccount(
      id: j['id'].toString(),
      shopName: j['shop_name'] as String? ?? '',
      category: j['category'] as String?,
      logoUrl: j['logo_url'] as String?,
      contact: j['contact'] as String?,
      ownerEmail: owner?['email'] as String?,
      communityName: comm?['name'] as String?,
      isActive: j['is_active'] as bool? ?? true,
    );
  }
}

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository(Supabase.instance.client);
});

final companiesProvider = FutureProvider.autoDispose<List<Company>>((ref) {
  return ref.watch(superAdminRepositoryProvider).companies();
});

final merchantAccountsProvider =
    FutureProvider.autoDispose<List<MerchantAccount>>((ref) {
  return ref.watch(superAdminRepositoryProvider).merchants();
});

class SuperAdminRepository {
  final SupabaseClient _db;
  SuperAdminRepository(this._db);

  Future<List<Company>> companies() async {
    final rows = await _db
        .from('communities')
        .select('id, code, name')
        .order('code', ascending: true);

    // Counts, admins and module switches in one pass each (small tables).
    final profiles = await _db
        .from('profiles')
        .select('community_id, role, full_name, email');
    final modules = await _db.from('community_modules').select();

    final byCommunity = <String, List<Map<String, dynamic>>>{};
    for (final p in (profiles as List).cast<Map<String, dynamic>>()) {
      final cid = p['community_id']?.toString();
      if (cid == null) continue;
      byCommunity.putIfAbsent(cid, () => []).add(p);
    }
    final moduleByCommunity = {
      for (final m in (modules as List).cast<Map<String, dynamic>>())
        m['community_id'].toString():
            (m['modules'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
    };

    return (rows as List).map((j) {
      final id = j['id'].toString();
      final members = byCommunity[id] ?? const [];
      final admin = members.where((m) => m['role'] == 'admin').toList();
      return Company(
        id: id,
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        residentCount: members.where((m) => m['role'] == 'resident').length,
        adminName: admin.isEmpty ? null : admin.first['full_name'] as String?,
        adminEmail: admin.isEmpty ? null : admin.first['email'] as String?,
        modules: moduleByCommunity[id] ?? const {},
      );
    }).toList();
  }

  Future<void> createCompany(String code, String name) async {
    await _db.from('communities').insert({'code': code, 'name': name});
  }

  Future<void> renameCompany(String id, String name) async {
    await _db.from('communities').update({'name': name}).eq('id', id);
  }

  Future<void> deleteCompany(String id) async {
    await _db.from('communities').delete().eq('id', id);
  }

  /// Switch a module on/off for one company.
  Future<void> setModule(String communityId, String key, bool enabled) async {
    final existing = await _db
        .from('community_modules')
        .select('modules')
        .eq('community_id', communityId)
        .maybeSingle();
    final current = ((existing?['modules'] as Map?) ?? {})
        .cast<String, dynamic>();
    current[key] = enabled;
    await _db.from('community_modules').upsert({
      'community_id': communityId,
      'modules': current,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'community_id');
  }

  // ---- merchants ----
  Future<List<MerchantAccount>> merchants() async {
    final rows = await _db
        .from('merchants')
        .select('*, profiles!merchants_owner_id_fkey(email), communities(name)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((j) => MerchantAccount.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> setMerchantActive(String id, bool active) async {
    await _db.from('merchants').update({'is_active': active}).eq('id', id);
  }

  Future<void> deleteMerchant(String id) async {
    await _db.from('merchants').delete().eq('id', id);
  }
}
