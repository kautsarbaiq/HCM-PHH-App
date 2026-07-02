import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/id_scan_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../theme/app_colors.dart';

/// Admin: view the ID documents residents have scanned (name, IC/passport, etc.)
/// with the captured image. Read-only — residents own their own scans.
class IdScansAdminPage extends ConsumerWidget {
  const IdScansAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminIdScansProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Resident IDs',
            subtitle: 'Scanned identity documents & extracted details',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(adminIdScansProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.badge_rounded,
                    title: 'No scanned IDs yet',
                    message:
                        'When residents scan their ID/license, it appears here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminIdScansProvider),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => _row(context, items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IdScan s) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 70,
              child: (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: s.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName.isEmpty ? '(no name)' : s.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.idNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (s.docType.isNotEmpty) s.docType,
                    if ((s.residentName ?? '').isNotEmpty)
                      'Resident: ${s.residentName}',
                  ].join('  ·  '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: AppColors.brand),
            tooltip: 'View details',
            onPressed: () => _details(context, s),
          ),
        ],
      ),
    );
  }

  void _details(BuildContext context, IdScan s) {
    Widget line(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            v.isEmpty ? '-' : v,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          s.fullName.isEmpty ? 'ID details' : s.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.imageUrl != null && s.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: s.imageUrl!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((s.residentName ?? '').isNotEmpty)
                  line('Resident', s.residentName!),
                line('Full name', s.fullName),
                line('IC / Passport / License No.', s.idNumber),
                line('Document type', s.docType),
                line('Nationality', s.nationality),
                line('Address', s.address),
                line('Validity', s.validity),
                line('Class', s.className),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.brand)),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: AppColors.surfaceTint,
    child: const Icon(Icons.badge_rounded, color: AppColors.brand),
  );
}
