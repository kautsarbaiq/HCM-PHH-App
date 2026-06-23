import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/repositories/document_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminDocumentsProvider =
    AsyncNotifierProvider<AdminDocumentsNotifier, List<AppDocument>>(
      () => AdminDocumentsNotifier(),
    );

class AdminDocumentsNotifier extends AsyncNotifier<List<AppDocument>> {
  @override
  Future<List<AppDocument>> build() async {
    final repo = ref.read(documentRepositoryProvider);
    return repo.getDocuments();
  }

  Future<void> addDocument({
    required String title,
    String? category,
    required String fileUrl,
    String? fileSize,
  }) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.createDocument(
      title: title,
      category: category,
      fileUrl: fileUrl,
      fileSize: fileSize,
    );
    ref.invalidateSelf();
  }

  Future<void> updateDocument(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.updateDocument(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteDocument(String id) async {
    final repo = ref.read(documentRepositoryProvider);
    await repo.deleteDocument(id);
    ref.invalidateSelf();
  }
}

class DocumentsAdminPage extends ConsumerStatefulWidget {
  const DocumentsAdminPage({super.key});

  @override
  ConsumerState<DocumentsAdminPage> createState() => _DocumentsAdminPageState();
}

class _DocumentsAdminPageState extends ConsumerState<DocumentsAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  /// Human-readable size from a raw byte count (e.g. 1536 -> "1.5 KB").
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$value ${units[unit]}';
  }

  void _showForm({AppDocument? document}) {
    final isEdit = document != null;
    final titleController = TextEditingController(text: document?.title ?? '');
    final categoryController = TextEditingController(
      text: document?.category ?? '',
    );

    // Picked-file state (null until the admin chooses a new file).
    PlatformFile? pickedFile;
    String? pickedFileName;
    String? pickedFileSize;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              final messenger = ScaffoldMessenger.of(context);
              // On web we must request the file bytes (path is null there).
              final result = await FilePicker.platform.pickFiles(
                withData: kIsWeb,
              );
              if (result == null) return;
              final file = result.files.single;
              if (kIsWeb && file.bytes == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not read the selected file.'),
                  ),
                );
                return;
              }
              if (!kIsWeb && file.path == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not access the selected file.'),
                  ),
                );
                return;
              }
              setDialogState(() {
                pickedFile = file;
                pickedFileName = file.name;
                pickedFileSize = _formatBytes(file.size);
              });
            }

            final existingHasFile =
                document?.fileUrl != null && document!.fileUrl!.isNotEmpty;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                isEdit ? 'Edit Document' : 'Upload Document',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(titleController, 'Title', Icons.title),
                      const SizedBox(height: 4),
                      _buildTextField(
                        categoryController,
                        'Category (optional)',
                        Icons.folder_outlined,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'File',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose PDF/file'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          side: const BorderSide(color: Color(0xFFE0E5F2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (pickedFileName != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              size: 18,
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pickedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (pickedFileSize != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                pickedFileSize!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (existingHasFile)
                        const Text(
                          'A file is already attached. Choose a new one to replace it.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        )
                      else
                        const Text(
                          'No file selected.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (titleController.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a title.'),
                              ),
                            );
                            return;
                          }
                          // A file is required when creating; on edit it's
                          // optional (keep the existing one if none picked).
                          if (!isEdit && pickedFile == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please choose a file to upload.'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            final storage = ref.read(storageRepositoryProvider);
                            final title = titleController.text.trim();
                            final category =
                                categoryController.text.trim().isEmpty
                                ? null
                                : categoryController.text.trim();

                            // Upload the new file if one was picked.
                            String? uploadedUrl;
                            String? uploadedSize;
                            final file = pickedFile;
                            if (file != null) {
                              if (kIsWeb) {
                                final ext =
                                    (file.extension != null &&
                                        file.extension!.isNotEmpty)
                                    ? '.${file.extension}'
                                    : p.extension(file.name);
                                uploadedUrl = await storage
                                    .uploadCommunityDocumentBytes(
                                      file.bytes!,
                                      file.name,
                                      ext,
                                    );
                              } else {
                                uploadedUrl = await storage
                                    .uploadCommunityDocument(
                                      File(file.path!),
                                      file.name,
                                    );
                              }
                              uploadedSize = _formatBytes(file.size);
                            }

                            if (isEdit) {
                              final updates = <String, dynamic>{
                                'title': title,
                                'category': category,
                              };
                              if (uploadedUrl != null) {
                                updates['file_url'] = uploadedUrl;
                                updates['file_size'] = uploadedSize;
                              }
                              await ref
                                  .read(adminDocumentsProvider.notifier)
                                  .updateDocument(document.id, updates);
                            } else {
                              await ref
                                  .read(adminDocumentsProvider.notifier)
                                  .addDocument(
                                    title: title,
                                    category: category,
                                    fileUrl: uploadedUrl!,
                                    fileSize: uploadedSize,
                                  );
                            }
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showError(e);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Save' : 'Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.textSecondary)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brand),
          ),
        ),
      ),
    );
  }

  void _deleteDocument(AppDocument document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text(
            'Delete Document',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${document.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref
                      .read(adminDocumentsProvider.notifier)
                      .deleteDocument(document.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(adminDocumentsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Documents',
                  subtitle: 'Community rules, regulations and shared files',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: documentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminDocumentsProvider),
              ),
              data: (documents) {
                if (documents.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'No documents uploaded yet',
                    message:
                        'Upload community rules, regulations or shared files for residents.',
                    actionLabel: 'Upload Document',
                    onAction: () => _showForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminDocumentsProvider),
                  child: ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final d = documents[index];
                      final hasFile =
                          d.fileUrl != null && d.fileUrl!.isNotEmpty;
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const GradientIconBadge(
                            icon: Icons.picture_as_pdf_rounded,
                            gradient: AppColors.sunsetGradient,
                            size: 46,
                          ),
                          title: Text(
                            d.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                if (d.category != null &&
                                    d.category!.isNotEmpty) ...[
                                  StatusPill(
                                    label: d.category!,
                                    color: AppColors.brand,
                                    dense: true,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (d.fileSize != null &&
                                    d.fileSize!.isNotEmpty)
                                  Text(
                                    d.fileSize!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (!hasFile)
                                  const StatusPill(
                                    label: 'NO FILE',
                                    color: AppColors.error,
                                    dense: true,
                                  ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(document: d),
                                tooltip: 'Edit Document',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteDocument(d),
                                tooltip: 'Delete Document',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
