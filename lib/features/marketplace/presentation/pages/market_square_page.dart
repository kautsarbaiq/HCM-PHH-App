import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/marketplace_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

final servicesProvider = FutureProvider<List<MarketService>>((ref) {
  return ref.read(marketplaceRepositoryProvider).getServices();
});

Future<void> _launch(BuildContext context, Uri uri, String failMessage) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(failMessage), backgroundColor: AppColors.error),
      );
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(failMessage), backgroundColor: AppColors.error),
      );
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
      final sanitized = hasPhone
          ? s.phone!.replaceAll(RegExp(r'[^\d+]'), '')
          : '';
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A7BA8).withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
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
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    GradientIconBadge(
                      icon: _serviceIcon(s.category),
                      gradient: AppColors.brandGradient,
                      size: 56,
                      iconSize: 28,
                      radius: 18,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.businessName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (s.category != null) ...[
                            const SizedBox(height: 6),
                            StatusPill(
                              label: s.category!,
                              color: AppColors.brand,
                              dense: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsFill.star,
                      size: 16,
                      color: AppColors.accentAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (s.description != null && s.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    s.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (hasPhone)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _launch(
                              context,
                              Uri(scheme: 'tel', path: sanitized),
                              'Could not open the dialer.',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            PhosphorIconsRegular.phone,
                            size: 18,
                          ),
                          label: const Text(
                            'Call',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            final waNumber = sanitized.replaceAll('+', '');
                            _launch(
                              context,
                              Uri.parse('https://wa.me/$waNumber'),
                              'Could not open WhatsApp.',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentMint,
                            side: const BorderSide(color: AppColors.accentMint),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            PhosphorIconsRegular.chatCircle,
                            size: 18,
                          ),
                          label: const Text(
                            'WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'No contact number provided.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
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

/// A small palette of vivid gradients cycled across service tiles so the grid
/// reads bright and lively rather than monotone.
const List<LinearGradient> _tileGradients = [
  AppColors.brandGradient,
  AppColors.skyGradient,
  AppColors.mintGradient,
  AppColors.sunsetGradient,
];

class MarketSquarePage extends ConsumerWidget {
  const MarketSquarePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Market Square',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: servicesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AppErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(servicesProvider),
                    ),
                  ),
                ),
                data: (services) {
                  if (services.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.storefront_rounded,
                          title: 'No services listed',
                          message:
                              'Neighbourhood services and businesses will show up here.',
                          gradient: AppColors.mintGradient,
                        ),
                      ),
                    );
                  }
                  final width = MediaQuery.of(context).size.width;
                  final crossAxisCount = width >= 900
                      ? 4
                      : (width >= 600 ? 3 : 2);
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      // Use a fixed extent so the cell grows with large text scale
                      // instead of overflowing a fixed aspect ratio.
                      mainAxisExtent: 210,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final s = services[index];
                      final gradient =
                          _tileGradients[index % _tileGradients.length];
                      return PremiumCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () => _showServiceSheet(context, s),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GradientIconBadge(
                              icon: _serviceIcon(s.category),
                              gradient: gradient,
                              size: 54,
                              iconSize: 26,
                              radius: 18,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.businessName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (s.category != null)
                              StatusPill(
                                label: s.category!,
                                color: AppColors.brand,
                                dense: true,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  PhosphorIconsFill.star,
                                  size: 14,
                                  color: AppColors.accentAmber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }, childCount: services.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
