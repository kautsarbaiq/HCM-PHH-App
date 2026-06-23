import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../../core/repositories/announcement_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminAnnouncementsProvider =
    AsyncNotifierProvider<AdminAnnouncementsNotifier, List<Announcement>>(
      () => AdminAnnouncementsNotifier(),
    );

class AdminAnnouncementsNotifier extends AsyncNotifier<List<Announcement>> {
  @override
  Future<List<Announcement>> build() async {
    final repo = ref.read(announcementRepositoryProvider);
    return repo.getAllAnnouncements();
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    final repo = ref.read(announcementRepositoryProvider);
    await repo.createAnnouncement(announcement);
    ref.invalidateSelf();
  }

  Future<void> updateAnnouncement(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final repo = ref.read(announcementRepositoryProvider);
    await repo.updateAnnouncement(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteAnnouncement(String id) async {
    final repo = ref.read(announcementRepositoryProvider);
    await repo.deleteAnnouncement(id);
    ref.invalidateSelf();
  }
}

class AnnouncementsAdminPage extends ConsumerStatefulWidget {
  const AnnouncementsAdminPage({super.key});

  @override
  ConsumerState<AnnouncementsAdminPage> createState() =>
      _AnnouncementsAdminPageState();
}

class _AnnouncementsAdminPageState
    extends ConsumerState<AnnouncementsAdminPage> {
  String _formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showDetails(Announcement announcement) {
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
          title: Row(
            children: [
              Icon(
                announcement.isUrgent
                    ? Icons.warning_amber_rounded
                    : Icons.campaign,
                color: announcement.isUrgent
                    ? AppColors.error
                    : AppColors.brand,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(announcement.publishedAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.brand),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForm({Announcement? announcement}) {
    final isEdit = announcement != null;
    final titleController = TextEditingController(
      text: announcement?.title ?? '',
    );
    final contentController = TextEditingController(
      text: announcement?.content ?? '',
    );
    final imageController = TextEditingController(
      text: announcement?.imageUrl ?? '',
    );
    bool isUrgent = announcement?.isUrgent ?? false;
    bool isSaving = false;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                isEdit ? 'Edit Announcement' : 'Create Announcement',
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
                    children: [
                      _buildTextField(titleController, 'Title', Icons.title),
                      const SizedBox(height: 4),
                      _buildTextField(
                        contentController,
                        'Content details',
                        Icons.description,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        imageController,
                        'Banner image URL (optional)',
                        Icons.image_outlined,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.image,
                                          withData: kIsWeb,
                                        );
                                    if (result == null ||
                                        result.files.isEmpty) {
                                      return;
                                    }
                                    final file = result.files.first;
                                    setDialogState(() => isUploading = true);
                                    try {
                                      final storage = ref.read(
                                        storageRepositoryProvider,
                                      );
                                      String url;
                                      if (kIsWeb) {
                                        if (file.bytes == null) {
                                          throw Exception(
                                            'Could not read the file.',
                                          );
                                        }
                                        final ext =
                                            (file.extension != null &&
                                                file.extension!.isNotEmpty)
                                            ? '.${file.extension}'
                                            : p.extension(file.name);
                                        url = await storage
                                            .uploadCommunityDocumentBytes(
                                              file.bytes!,
                                              file.name,
                                              ext,
                                            );
                                      } else {
                                        if (file.path == null) {
                                          throw Exception(
                                            'Could not read the file.',
                                          );
                                        }
                                        url = await storage
                                            .uploadCommunityDocument(
                                              File(file.path!),
                                              file.name,
                                            );
                                      }
                                      setDialogState(() {
                                        imageController.text = url;
                                        isUploading = false;
                                      });
                                    } catch (e) {
                                      setDialogState(() => isUploading = false);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Upload failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            icon: isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              isUploading ? 'Uploading…' : 'Upload image',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brand,
                              side: const BorderSide(color: AppColors.brand),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (imageController.text.trim().isNotEmpty)
                            const Expanded(
                              child: Text(
                                'Image set ✓',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.error,
                        title: const Text(
                          'Mark as urgent',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Urgent notices are highlighted for residents',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: isUrgent,
                        onChanged: (val) =>
                            setDialogState(() => isUrgent = val),
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
                          if (titleController.text.isEmpty ||
                              contentController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter both a title and content.',
                                ),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminAnnouncementsProvider.notifier)
                                  .updateAnnouncement(announcement.id, {
                                    'title': titleController.text,
                                    'content': contentController.text,
                                    'is_urgent': isUrgent,
                                    'image_url': imageController.text.trim().isEmpty
                                        ? null
                                        : imageController.text.trim(),
                                  });
                            } else {
                              await ref
                                  .read(adminAnnouncementsProvider.notifier)
                                  .addAnnouncement(
                                    Announcement(
                                      id: '',
                                      title: titleController.text,
                                      content: contentController.text,
                                      isUrgent: isUrgent,
                                      publishedAt: '',
                                      imageUrl: imageController.text.trim(),
                                    ),
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
                      : Text(isEdit ? 'Save' : 'Post'),
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

  void _deleteAnnouncement(Announcement announcement) {
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
            'Delete Announcement',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${announcement.title}"?',
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
                      .read(adminAnnouncementsProvider.notifier)
                      .deleteAnnouncement(announcement.id);
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
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);

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
                  title: 'Announcements',
                  subtitle: 'Post and manage community notices',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Announcement'),
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
            child: announcementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminAnnouncementsProvider),
              ),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.campaign_rounded,
                    title: 'No announcements posted yet',
                    message:
                        'Share your first community notice with residents.',
                    actionLabel: 'Create Announcement',
                    onAction: () => _showForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminAnnouncementsProvider),
                  // Full-width list reaching the right edge on web.
                  child: ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final a = announcements[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: a.isUrgent
                                ? Icons.warning_amber_rounded
                                : Icons.campaign_rounded,
                            gradient: a.isUrgent
                                ? AppColors.sunsetGradient
                                : AppColors.brandGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  a.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (a.isUrgent) ...[
                                const SizedBox(width: 8),
                                const StatusPill(
                                  label: 'URGENT',
                                  color: AppColors.error,
                                  dense: true,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.content,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(a.publishedAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: AppColors.brand,
                                ),
                                onPressed: () => _showDetails(a),
                                tooltip: 'View Announcement',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(announcement: a),
                                tooltip: 'Edit Announcement',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteAnnouncement(a),
                                tooltip: 'Delete Announcement',
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
