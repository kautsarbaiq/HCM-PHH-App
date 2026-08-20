import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/repositories/rewards_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../theme/app_colors.dart';

/// Admin management for the rewards program (meeting 20/07 point 9): partner
/// brands, discount offers keyed to on-time bill streaks, and owner claims to
/// approve (or grant manually).
class RewardsAdminPage extends ConsumerStatefulWidget {
  const RewardsAdminPage({super.key});

  @override
  ConsumerState<RewardsAdminPage> createState() => _RewardsAdminPageState();
}

class _RewardsAdminPageState extends ConsumerState<RewardsAdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Rewards',
            subtitle: 'Partner brands, discount offers & owner claims',
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.brand,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.brand,
            tabs: const [
              Tab(text: 'Partners'),
              Tab(text: 'Offers'),
              Tab(text: 'Claims'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _PartnersTab(),
                _OffersTab(),
                _ClaimsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partners
// ---------------------------------------------------------------------------
class _PartnersTab extends ConsumerWidget {
  const _PartnersTab();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final category = TextEditingController();
    Uint8List? logoBytes;
    String logoExt = 'jpg';

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setLocal) => AlertDialog(
          title: const Text('Add partner'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Boss 27/07: a partner (company) can carry a logo/picture.
                  GestureDetector(
                    onTap: () async {
                      final x = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 400,
                        imageQuality: 85,
                      );
                      if (x != null) {
                        logoBytes = await x.readAsBytes();
                        logoExt = x.name.split('.').last.toLowerCase();
                        setLocal(() {});
                      }
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceTint,
                      backgroundImage:
                          logoBytes != null ? MemoryImage(logoBytes!) : null,
                      child: logoBytes == null
                          ? const Icon(Icons.add_a_photo_outlined,
                              color: AppColors.brand)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Tap to add logo (optional)',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Brand name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(
                      labelText: 'Category (e.g. Café, Restaurant)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(d, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final repo = ref.read(rewardsRepositoryProvider);
      String? logoUrl;
      if (logoBytes != null) {
        try {
          logoUrl = await repo.uploadPartnerLogo(logoBytes!, logoExt);
        } catch (_) {/* logo optional — save the partner regardless */}
      }
      await repo.createPartner(name.text.trim(), category.text.trim(),
          logoUrl: logoUrl);
      ref.invalidate(adminPartnersProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(adminPartnersProvider);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Add partner'),
          ),
        ),
        Expanded(
          child: partnersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(adminPartnersProvider)),
            data: (partners) {
              if (partners.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No partners yet',
                  message: 'Add café / restaurant brands to offer discounts.',
                );
              }
              return ListView.separated(
                itemCount: partners.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = partners[i];
                  return ResponsiveListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceTint,
                      backgroundImage: (p.logoUrl ?? '').isNotEmpty
                          ? NetworkImage(p.logoUrl!)
                          : null,
                      child: (p.logoUrl ?? '').isEmpty
                          ? const Icon(Icons.storefront_rounded,
                              color: AppColors.brand)
                          : null,
                    ),
                    title: Text(p.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.category ?? '—'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: p.isActive,
                          onChanged: (v) async {
                            await ref
                                .read(rewardsRepositoryProvider)
                                .setPartnerActive(p.id, v);
                            ref.invalidate(adminPartnersProvider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () async {
                            await ref
                                .read(rewardsRepositoryProvider)
                                .deletePartner(p.id);
                            ref.invalidate(adminPartnersProvider);
                            ref.invalidate(adminOffersProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Offers
// ---------------------------------------------------------------------------
class _OffersTab extends ConsumerWidget {
  const _OffersTab();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final partners = await ref.read(rewardsRepositoryProvider).allPartners();
    if (partners.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Add a partner brand first.')));
      }
      return;
    }
    if (!context.mounted) return;
    String partnerId = partners.first.id;
    final title = TextEditingController();
    final desc = TextEditingController();
    final discount = TextEditingController(text: '5');
    final streak = TextEditingController(text: '3');

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add offer'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: partnerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Partner',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final p in partners)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => partnerId = v ?? partnerId,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Offer title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Discount %',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: streak,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Unlock at (consecutive on-time bills)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              Navigator.pop(d, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(rewardsRepositoryProvider).createOffer(
            partnerId: partnerId,
            title: title.text.trim(),
            description: desc.text.trim(),
            discountPercent: int.tryParse(discount.text.trim()) ?? 0,
            minStreak: int.tryParse(streak.text.trim()) ?? 0,
          );
      ref.invalidate(adminOffersProvider);
      ref.invalidate(rewardOffersProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersProvider);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.local_offer_rounded),
            label: const Text('Add offer'),
          ),
        ),
        Expanded(
          child: offersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(adminOffersProvider)),
            data: (offers) {
              if (offers.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No offers yet',
                  message: 'Create discount tiers tied to on-time bills.',
                );
              }
              return ListView.separated(
                itemCount: offers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final o = offers[i];
                  return ResponsiveListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.brand,
                      child: Text('${o.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    title: Text(o.title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${o.partnerName} • unlock at ${o.minStreak} on-time bills'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: o.isActive,
                          onChanged: (v) async {
                            await ref
                                .read(rewardsRepositoryProvider)
                                .setOfferActive(o.id, v);
                            ref.invalidate(adminOffersProvider);
                            ref.invalidate(rewardOffersProvider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () async {
                            await ref
                                .read(rewardsRepositoryProvider)
                                .deleteOffer(o.id);
                            ref.invalidate(adminOffersProvider);
                            ref.invalidate(rewardOffersProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Claims
// ---------------------------------------------------------------------------
class _ClaimsTab extends ConsumerWidget {
  const _ClaimsTab();

  Future<void> _decide(
      BuildContext context, WidgetRef ref, RewardClaim c, bool approve) async {
    String? voucher;
    if (approve) {
      final ctrl = TextEditingController(
          text: 'RW-${DateTime.now().millisecondsSinceEpoch % 100000}');
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Approve & issue voucher'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Voucher code',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Approve')),
          ],
        ),
      );
      if (ok != true) return;
      voucher = ctrl.text.trim();
    }
    await ref
        .read(rewardsRepositoryProvider)
        .decideClaim(c.id, approve: approve, voucherCode: voucher);
    ref.invalidate(adminClaimsProvider);
  }

  Future<void> _grant(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(rewardsRepositoryProvider);
    final offers = await repo.allOffers();
    final owners = await repo.owners();
    if (offers.isEmpty || owners.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Need at least one offer and one owner.')));
      }
      return;
    }
    if (!context.mounted) return;
    String offerId = offers.first.id;
    String ownerId = owners.first.id;
    final voucher = TextEditingController(
        text: 'RW-${DateTime.now().millisecondsSinceEpoch % 100000}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Grant reward to owner'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: offerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Offer',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final o in offers)
                      DropdownMenuItem(
                          value: o.id,
                          child: Text('${o.title} (${o.discountPercent}%)')),
                  ],
                  onChanged: (v) => offerId = v ?? offerId,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: ownerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final o in owners)
                      DropdownMenuItem(value: o.id, child: Text(o.name)),
                  ],
                  onChanged: (v) => ownerId = v ?? ownerId,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: voucher,
                  decoration: const InputDecoration(
                    labelText: 'Voucher code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Grant')),
        ],
      ),
    );
    if (ok == true) {
      await repo.grantToOwner(offerId, ownerId, voucher.text.trim());
      ref.invalidate(adminClaimsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(adminClaimsProvider);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _grant(context, ref),
            icon: const Icon(Icons.card_giftcard_rounded),
            label: const Text('Grant to owner'),
          ),
        ),
        Expanded(
          child: claimsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(adminClaimsProvider)),
            data: (claims) {
              if (claims.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No claims yet',
                  message: 'Owner claims will appear here to approve.',
                );
              }
              return ListView.separated(
                itemCount: claims.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = claims[i];
                  final pending = c.status == 'pending';
                  return ListTile(
                    title: Text(
                      '${c.ownerName ?? 'Owner'} — ${c.offerTitle ?? 'Reward'}'
                      '${c.discountPercent != null ? ' (${c.discountPercent}%)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if ((c.partnerName ?? '').isNotEmpty) c.partnerName!,
                        if ((c.voucherCode ?? '').isNotEmpty)
                          'Voucher: ${c.voucherCode}',
                      ].join(' • '),
                    ),
                    trailing: pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: AppColors.success),
                                tooltip: 'Approve',
                                onPressed: () =>
                                    _decide(context, ref, c, true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: AppColors.error),
                                tooltip: 'Reject',
                                onPressed: () =>
                                    _decide(context, ref, c, false),
                              ),
                            ],
                          )
                        : StatusPill(
                            label: c.status.toUpperCase(),
                            color: c.status == 'approved'
                                ? AppColors.success
                                : AppColors.error,
                            dense: true,
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
