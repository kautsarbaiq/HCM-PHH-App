import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final servicesProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {'name': 'CleanPro Services', 'category': 'Cleaning', 'rating': 4.8, 'icon': PhosphorIconsRegular.broom},
      {'name': 'PipeFix Plumbing', 'category': 'Plumbing', 'rating': 4.6, 'icon': PhosphorIconsRegular.wrench},
      {'name': 'SparkElec', 'category': 'Electrician', 'rating': 4.9, 'icon': PhosphorIconsRegular.lightning},
      {'name': 'CoolBreeze AC', 'category': 'Air-Cond', 'rating': 4.7, 'icon': PhosphorIconsRegular.fan},
      {'name': 'GreenThumb Gardens', 'category': 'Landscaping', 'rating': 4.5, 'icon': PhosphorIconsRegular.plant},
      {'name': 'SwiftMove Movers', 'category': 'Moving', 'rating': 4.4, 'icon': PhosphorIconsRegular.truck},
    ]);

class MarketSquarePage extends ConsumerWidget {
  const MarketSquarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey, pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Market Square', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85),
              delegate: SliverChildBuilderDelegate((context, index) {
                final s = services[index];
                return GlassCard(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.backgroundGrey, shape: BoxShape.circle),
                    child: Icon(s['icon'], size: 28, color: AppColors.deepSlate)),
                  const SizedBox(height: 14),
                  Text(s['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.sageGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(s['category'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sageGreen))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(PhosphorIconsFill.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('${s['rating']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ]),
                ]));
              }, childCount: services.length),
            ),
          ),
        ],
      ),
    );
  }
}
