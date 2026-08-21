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
                  // Boss batch 08/08 point 11: show the wallpaper with the
                  // details, and the redirect link it opens.
                  if ((announcement.imageUrl ?? '').trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        announcement.imageUrl!.trim(),
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 190,
                          color: AppColors.surfaceTint,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
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
                  if ((announcement.linkUrl ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 16, color: AppColors.brand),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            announcement.linkUrl!.trim(),
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
    final linkController = TextEditingController(
      text: announcement?.linkUrl ?? '',
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
                          // Boss batch 08/08 point 11: show the selected
                          // wallpaper itself, not just a "set ✓" label.
                          if (imageController.text.trim().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageController.text.trim(),
                                width: 108,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 108,
                                  height: 68,
                                  color: AppColors.surfaceTint,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Optional redirect: tapping the wallpaper in the app
                      // opens this link (boss batch 08/08 point 11).
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: 'Redirect link (optional)',
                          hintText: 'https://…',
                          helperText:
                              'If set, tapping the wallpaper opens this link',
                          prefixIcon: const Icon(Icons.link_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                                    'link_url': linkController.text.trim().isEmpty
                                        ? null
                                        : linkController.text.trim(),
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
                                      linkUrl: linkController.text.trim(),
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
                // Boss 19/08: announcements now show as full cards — the
                // wallpaper, the whole notice and Edit/Delete right on the
                // card — instead of a cramped one-line list.
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminAnnouncementsProvider),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const gap = 16.0;
                      final cols = (c.maxWidth / 420).floor().clamp(1, 3);
                      final cardWidth =
                          (c.maxWidth - gap * (cols - 1)) / cols;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final a in announcements)
                              SizedBox(
                                width: cardWidth,
                                child: _AnnouncementCard(
                                  announcement: a,
                                  dateLabel: _formatDate(a.publishedAt),
                                  onView: () => _showDetails(a),
                                  onEdit: () => _showForm(announcement: a),
                                  onDelete: () => _deleteAnnouncement(a),
                                ),
                              ),
                          ],
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

/// Full announcement card for the admin portal (boss 19/08): the wallpaper,
/// the complete notice, and Edit / Delete right on the card — the same shape
/// residents see, plus the management actions.
class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String dateLabel;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.dateLabel,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final hasImage = (a.imageUrl ?? '').isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a.isUrgent
              ? AppColors.error.withValues(alpha: 0.35)
              : const Color(0xFFE8EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A7BA8).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- wallpaper -----------------------------------------------
          if (hasImage)
            SizedBox(
              height: 148,
              width: double.infinity,
              child: Image.network(
                a.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceTint,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_rounded,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- badges + date ---------------------------------------
                Row(
                  children: [
                    StatusPill(
                      label: a.isUrgent ? 'URGENT' : 'NOTICE',
                      color: a.isUrgent ? AppColors.error : AppColors.info,
                      dense: true,
                    ),
                    const Spacer(),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                // The whole notice, not a one-line preview.
                Text(
                  a.content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                if ((a.linkUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 15, color: AppColors.brand),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          a.linkUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // ---- actions ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentAmber,
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
