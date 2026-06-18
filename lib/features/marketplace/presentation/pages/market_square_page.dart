import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/marketplace_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final servicesProvider = FutureProvider<List<MarketService>>((ref) {
  return ref.read(marketplaceRepositoryProvider).getServices();
});

IconData _serviceIcon(String? category) {
  switch (category) {
    case 'Cleaning':
      return PhosphorIconsRegular.broom;
    case 'Plumbing':
      return PhosphorIconsRegular.wrench;
    case 'Electrician':
      return PhosphorIconsRegular.lightning;
    case 'Air-Cond':
      return PhosphorIconsRegular.fan;
    case 'Landscaping':
      return PhosphorIconsRegular.plant;
    case 'Moving':
      return PhosphorIconsRegular.truck;
    default:
      return PhosphorIconsRegular.storefront;
  }
}

class MarketSquarePage extends ConsumerWidget {
  const MarketSquarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Market Square', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: servicesAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (services) {
                if (services.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No services listed.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final s = services[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${s.businessName}${s.phone != null ? ' — ${s.phone}' : ''}'), backgroundColor: AppColors.primaryBlue),
                        );
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(color: AppColors.backgroundGrey, shape: BoxShape.circle),
                          child: Icon(_serviceIcon(s.category), size: 28, color: AppColors.deepSlate),
                        ),
                        const SizedBox(height: 14),
                        Text(s.businessName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        if (s.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(s.category!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                          ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(PhosphorIconsFill.star, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(s.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ]),
                      ]),
                    );
                  }, childCount: services.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
