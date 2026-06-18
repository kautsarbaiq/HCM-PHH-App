import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/form_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final eFormsProvider = FutureProvider<List<AppForm>>((ref) {
  return ref.read(formRepositoryProvider).getForms();
});

final mySubmittedFormsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(formRepositoryProvider).getMySubmittedFormIds();
});

IconData _formIcon(String? category) {
  switch (category) {
    case 'renovation':
      return PhosphorIconsRegular.hammer;
    case 'moving':
      return PhosphorIconsRegular.truck;
    case 'vehicle':
      return PhosphorIconsRegular.car;
    case 'pet':
      return PhosphorIconsRegular.pawPrint;
    default:
      return PhosphorIconsRegular.fileText;
  }
}

class EFormPage extends ConsumerWidget {
  const EFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(eFormsProvider);
    final submitted = ref.watch(mySubmittedFormsProvider).valueOrNull ?? <String>{};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('E-Form', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: formsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (forms) {
                if (forms.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No forms available.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final form = forms[index];
                    final isSubmitted = submitted.contains(form.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(16)),
                            child: Icon(_formIcon(form.category), color: AppColors.deepSlate, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(form.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            if (form.description != null) ...[
                              const SizedBox(height: 4),
                              Text(form.description!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ])),
                          const SizedBox(width: 12),
                          if (isSubmitted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Submitted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                            )
                          else
                            ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await ref.read(formRepositoryProvider).submitForm(form.id);
                                  ref.invalidate(mySubmittedFormsProvider);
                                  messenger.showSnackBar(SnackBar(content: Text('"${form.title}" submitted.'), backgroundColor: AppColors.success));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Apply'),
                            ),
                        ]),
                      ),
                    );
                  }, childCount: forms.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
