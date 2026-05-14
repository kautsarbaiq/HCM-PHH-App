import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final eDocumentsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'title': 'House Rules & Regulations',
        'category': 'Legal',
        'size': '2.4 MB',
        'icon': PhosphorIconsRegular.scales,
      },
      {
        'title': 'Fire Safety Guidelines',
        'category': 'Safety',
        'size': '1.1 MB',
        'icon': PhosphorIconsRegular.fire,
      },
      {
        'title': 'Parking Policy 2026',
        'category': 'Policy',
        'size': '890 KB',
        'icon': PhosphorIconsRegular.car,
      },
      {
        'title': 'Annual Financial Report',
        'category': 'Finance',
        'size': '4.7 MB',
        'icon': PhosphorIconsRegular.chartLine,
      },
      {
        'title': 'Pet Ownership Policy',
        'category': 'Policy',
        'size': '560 KB',
        'icon': PhosphorIconsRegular.pawPrint,
      },
    ]);

class EDocumentPage extends ConsumerWidget {
  const EDocumentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(eDocumentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft),
              onPressed: () => context.pop(),
            ),
            title: const Text('E-Document', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final doc = docs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(PhosphorIconsFill.filePdf, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.sageGreen.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(doc['category'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.sageGreen)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(doc['size'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Downloading ${doc['title']}...'), backgroundColor: AppColors.sageGreen),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.deepSlate.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(PhosphorIconsRegular.downloadSimple, color: AppColors.deepSlate, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: docs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
