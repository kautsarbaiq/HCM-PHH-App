import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/merchant_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Merchant portal → Offers (boss batch 08/08 point 2): number of vouchers,
/// discount %, product names, and a validity window.
class MerchantOffersPage extends ConsumerWidget {
  const MerchantOffersPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final products = TextEditingController();
    final discount = TextEditingController(text: '5');
    final vouchers = TextEditingController(text: '50');
    final streak = TextEditingController(text: '3');
    DateTime? start;
    DateTime? end;

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setLocal) {
          Future<void> pick(bool isStart) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: d,
              initialDate: isStart ? (start ?? now) : (end ?? now),
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now.add(const Duration(days: 730)),
            );
            if (picked != null) {
              setLocal(() => isStart ? start = picked : end = picked);
            }
          }

          String label(DateTime? d0) =>
              d0 == null ? 'Not set' : DateFormat('d MMM yyyy').format(d0);

          return AlertDialog(
            title: const Text('New offer'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                          labelText: 'Offer title',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: products,
                      decoration: const InputDecoration(
                        labelText: 'Product names',
                        helperText: 'Which items the discount applies to',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: discount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Discount %',
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: vouchers,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'No. of vouchers',
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: streak,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Unlock at (on-time bills in a row)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pick(true),
                            child: Text('Start: ${label(start)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pick(false),
                            child: Text('End: ${label(end)}'),
                          ),
                        ),
                      ],
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
                child: const Text('Publish'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(merchantRepositoryProvider).createOffer(
            title: title.text.trim(),
            products: products.text.trim(),
            discountPercent: int.tryParse(discount.text.trim()) ?? 0,
            voucherCount: int.tryParse(vouchers.text.trim()),
            minStreak: int.tryParse(streak.text.trim()) ?? 0,
            startsOn: start,
            endsOn: end,
          );
      ref.invalidate(myOffersProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(myOffersProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'My offers',
                  subtitle: 'Discounts residents can claim at your shop',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.local_offer_rounded),
                label: const Text('New offer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: offersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(myOffersProvider),
              ),
              data: (offers) {
                if (offers.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'No offers yet',
                    message:
                        'Create your shop profile first, then publish an offer.',
                  );
                }
                return ListView.separated(
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final o = offers[i];
                    return ListTile(
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
                        'Unlocks at ${o.minStreak} on-time bills',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(
                            label: o.isActive ? 'LIVE' : 'PAUSED',
                            color: o.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                            dense: true,
                          ),
                          Switch(
                            value: o.isActive,
                            onChanged: (v) async {
                              await ref
                                  .read(merchantRepositoryProvider)
                                  .setOfferActive(o.id, v);
                              ref.invalidate(myOffersProvider);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              await ref
                                  .read(merchantRepositoryProvider)
                                  .deleteOffer(o.id);
                              ref.invalidate(myOffersProvider);
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
      ),
    );
  }
}
