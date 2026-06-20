import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/repositories/document_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

final eDocumentsProvider = FutureProvider<List<AppDocument>>((ref) {
  return ref.read(documentRepositoryProvider).getDocuments();
});

Future<void> _openDocument(BuildContext context, AppDocument doc) async {
  final messenger = ScaffoldMessenger.of(context);
  final hasFile = doc.fileUrl != null && doc.fileUrl!.isNotEmpty;
  if (!hasFile) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('No file uploaded for "${doc.title}" yet.'),
        backgroundColor: AppColors.brand,
      ),
    );
    return;
  }

  final uri = Uri.tryParse(doc.fileUrl!);
  if (uri == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Invalid file link for "${doc.title}".'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open "${doc.title}".'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open "${doc.title}".'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class EDocumentPage extends ConsumerWidget {
  const EDocumentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(eDocumentsProvider);

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
                'E-Document',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: docsAsync.when(
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
                      onRetry: () => ref.invalidate(eDocumentsProvider),
                    ),
                  ),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.description_rounded,
                          title: 'No documents available',
                          message:
                              'Community documents and files will appear here.',
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = docs[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                PhosphorIconsFill.filePdf,
                                color: AppColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (doc.category != null)
                                        StatusPill(
                                          label: doc.category!,
                                          color: AppColors.brand,
                                          dense: true,
                                        ),
                                      if (doc.fileSize != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          doc.fileSize!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _openDocument(context, doc),
                              child: Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brand.withOpacity(0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  PhosphorIconsRegular.downloadSimple,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: docs.length),
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
