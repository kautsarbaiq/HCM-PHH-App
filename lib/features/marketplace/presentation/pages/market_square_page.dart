import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/marketplace_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final servicesProvider = FutureProvider<List<MarketService>>((ref) {
  return ref.read(marketplaceRepositoryProvider).getServices();
});

Future<void> _launch(BuildContext context, Uri uri, String failMessage) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failMessage), backgroundColor: AppColors.error));
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failMessage), backgroundColor: AppColors.error));
    }
  }
}

void _showServiceSheet(BuildContext context, MarketService s) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final hasPhone = s.phone != null && s.phone!.trim().isNotEmpty;
      final sanitized = hasPhone ? s.phone!.replaceAll(RegExp(r'[^\d+]'), '') : '';
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(color: AppColors.backgroundGrey, shape: BoxShape.circle),
                      child: Icon(_serviceIcon(s.category), size: 28, color: AppColors.deepSlate),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.businessName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          if (s.category != null) ...[
                            const SizedBox(height: 4),
                            Text(s.category!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.star, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(s.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                if (s.description != null && s.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(s.description!, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 24),
                if (hasPhone)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _launch(context, Uri(scheme: 'tel', path: sanitized), 'Could not open the dialer.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(PhosphorIconsRegular.phone, size: 18),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            final waNumber = sanitized.replaceAll('+', '');
                            _launch(context, Uri.parse('https://wa.me/$waNumber'), 'Could not open WhatsApp.');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(PhosphorIconsRegular.chatCircle, size: 18),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  )
                else
                  const Text('No contact number provided.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

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
                final width = MediaQuery.of(context).size.width;
                final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    // Use a fixed extent so the cell grows with large text scale
                    // instead of overflowing a fixed aspect ratio.
                    mainAxisExtent: 200,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final s = services[index];
                    return GlassCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => _showServiceSheet(context, s),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(color: AppColors.backgroundGrey, shape: BoxShape.circle),
                          child: Icon(_serviceIcon(s.category), size: 28, color: AppColors.deepSlate),
                        ),
                        const SizedBox(height: 14),
                        Text(s.businessName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        if (s.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(s.category!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
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
