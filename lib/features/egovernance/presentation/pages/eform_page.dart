import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/form_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
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

LinearGradient _formGradient(String? category) {
  switch (category) {
    case 'renovation':
      return AppColors.sunsetGradient;
    case 'moving':
      return AppColors.skyGradient;
    case 'vehicle':
      return AppColors.brandGradient;
    case 'pet':
      return AppColors.mintGradient;
    default:
      return AppColors.brandGradient;
  }
}

class EFormPage extends ConsumerWidget {
  const EFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(eFormsProvider);
    final submitted =
        ref.watch(mySubmittedFormsProvider).valueOrNull ?? <String>{};

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
                'E-Form',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: formsAsync.when(
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
                      onRetry: () => ref.invalidate(eFormsProvider),
                    ),
                  ),
                ),
                data: (forms) {
                  if (forms.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.assignment_rounded,
                          title: 'No forms available',
                          message:
                              'Application and request forms will appear here.',
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final form = forms[index];
                      final isSubmitted = submitted.contains(form.id);
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            GradientIconBadge(
                              icon: _formIcon(form.category),
                              gradient: _formGradient(form.category),
                              size: 50,
                              iconSize: 24,
                              radius: 16,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    form.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (form.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      form.description!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isSubmitted)
                              const StatusPill(
                                label: 'Submitted',
                                color: AppColors.success,
                                dense: true,
                              )
                            else
                              _ApplyButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    await ref
                                        .read(formRepositoryProvider)
                                        .submitForm(form.id);
                                    ref.invalidate(mySubmittedFormsProvider);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '"${form.title}" submitted.',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    }, childCount: forms.length),
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

/// A vivid brand-gradient "Apply" pill used to start a form submission.
class _ApplyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ApplyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Text(
            'Apply',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
