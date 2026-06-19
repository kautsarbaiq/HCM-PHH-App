import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/repositories/document_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final eDocumentsProvider = FutureProvider<List<AppDocument>>((ref) {
  return ref.read(documentRepositoryProvider).getDocuments();
});

Future<void> _openDocument(BuildContext context, AppDocument doc) async {
  final messenger = ScaffoldMessenger.of(context);
  final hasFile = doc.fileUrl != null && doc.fileUrl!.isNotEmpty;
  if (!hasFile) {
    messenger.showSnackBar(
      SnackBar(content: Text('No file uploaded for "${doc.title}" yet.'), backgroundColor: AppColors.primaryBlue),
    );
    return;
  }

  final uri = Uri.tryParse(doc.fileUrl!);
  if (uri == null) {
    messenger.showSnackBar(
      SnackBar(content: Text('Invalid file link for "${doc.title}".'), backgroundColor: AppColors.error),
    );
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open "${doc.title}".'), backgroundColor: AppColors.error),
      );
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open "${doc.title}".'), backgroundColor: AppColors.error),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('E-Document', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: docsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (docs) {
                if (docs.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No documents available.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = docs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(PhosphorIconsFill.filePdf, color: Color(0xFFEF4444), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Row(children: [
                              if (doc.category != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(doc.category!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                                ),
                              if (doc.fileSize != null) ...[
                                const SizedBox(width: 8),
                                Text(doc.fileSize!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ]),
                          ])),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openDocument(context, doc),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.deepSlate.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(PhosphorIconsRegular.downloadSimple, color: AppColors.deepSlate, size: 20),
                            ),
                          ),
                        ]),
                      ),
                    );
                  }, childCount: docs.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
