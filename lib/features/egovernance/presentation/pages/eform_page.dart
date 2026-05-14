import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final eFormsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'title': 'Renovation Request',
        'description': 'Submit your renovation plans for committee approval.',
        'icon': PhosphorIconsRegular.hammer,
        'status': 'Available',
      },
      {
        'title': 'Move-In / Move-Out Notice',
        'description': 'Notify management of moving dates and logistics.',
        'icon': PhosphorIconsRegular.truck,
        'status': 'Available',
      },
      {
        'title': 'Visitor Vehicle Pass',
        'description': 'Apply for a temporary visitor parking pass.',
        'icon': PhosphorIconsRegular.car,
        'status': 'Available',
      },
      {
        'title': 'Pet Registration',
        'description': 'Register your pet with the management office.',
        'icon': PhosphorIconsRegular.pawPrint,
        'status': 'Submitted',
      },
    ]);

class EFormPage extends ConsumerWidget {
  const EFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forms = ref.watch(eFormsProvider);

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
            title: const Text('E-Form', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final form = forms[index];
                  final isSubmitted = form['status'] == 'Submitted';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(form['icon'], color: AppColors.deepSlate, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(form['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(form['description'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSubmitted ? AppColors.sageGreen.withOpacity(0.15) : AppColors.deepSlate.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              form['status'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSubmitted ? AppColors.sageGreen : AppColors.deepSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: forms.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
