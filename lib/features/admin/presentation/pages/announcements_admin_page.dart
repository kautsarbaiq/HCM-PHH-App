import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/announcement_repository.dart';

final adminAnnouncementsProvider =
    AsyncNotifierProvider<AdminAnnouncementsNotifier, List<Announcement>>(
        () => AdminAnnouncementsNotifier());

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

  Future<void> updateAnnouncement(String id, Map<String, dynamic> updates) async {
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
  ConsumerState<AnnouncementsAdminPage> createState() => _AnnouncementsAdminPageState();
}

class _AnnouncementsAdminPageState extends ConsumerState<AnnouncementsAdminPage> {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                announcement.isUrgent ? Icons.warning_amber_rounded : Icons.campaign,
                color: announcement.isUrgent ? const Color(0xFFEE5D50) : const Color(0xFF4318FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(announcement.publishedAt), style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                announcement.content,
                style: const TextStyle(color: Color(0xFF2B3674), fontSize: 15, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF4318FF))),
            ),
          ],
        );
      },
    );
  }

  void _showForm({Announcement? announcement}) {
    final isEdit = announcement != null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final contentController = TextEditingController(text: announcement?.content ?? '');
    bool isUrgent = announcement?.isUrgent ?? false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Announcement' : 'Create Announcement',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(titleController, 'Title', Icons.title),
                    _buildTextField(contentController, 'Content details', Icons.description, maxLines: 5),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFEE5D50),
                      title: const Text('Mark as urgent', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                      subtitle: const Text('Urgent notices are highlighted for residents', style: TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
                      value: isUrgent,
                      onChanged: (val) => setDialogState(() => isUrgent = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter both a title and content.')),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref.read(adminAnnouncementsProvider.notifier).updateAnnouncement(announcement.id, {
                                'title': titleController.text,
                                'content': contentController.text,
                                'is_urgent': isUrgent,
                              });
                            } else {
                              await ref.read(adminAnnouncementsProvider.notifier).addAnnouncement(Announcement(
                                    id: '',
                                    title: titleController.text,
                                    content: contentController.text,
                                    isUrgent: isUrgent,
                                    publishedAt: '',
                                  ));
                            }
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showError(e);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEdit ? 'Save' : 'Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFFA3AED0)) : null,
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
            borderSide: const BorderSide(color: Color(0xFF4318FF)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Announcement', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete "${announcement.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref.read(adminAnnouncementsProvider.notifier).deleteAnnouncement(announcement.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Announcement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: announcementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Color(0xFFA3AED0)))),
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const Center(child: Text('No announcements posted yet', style: TextStyle(color: Color(0xFFA3AED0))));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(adminAnnouncementsProvider),
                    child: ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final a = announcements[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE0E5F2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: a.isUrgent ? const Color(0xFFFDEAEA) : const Color(0xFFF4F7FE),
                              child: Icon(
                                a.isUrgent ? Icons.warning_amber_rounded : Icons.campaign_rounded,
                                color: a.isUrgent ? const Color(0xFFEE5D50) : const Color(0xFF4318FF),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                                  ),
                                ),
                                if (a.isUrgent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEE5D50).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('URGENT', style: TextStyle(color: Color(0xFFEE5D50), fontSize: 10, fontWeight: FontWeight.bold)),
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
                                    style: const TextStyle(color: Color(0xFFA3AED0)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(a.publishedAt),
                                    style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.visibility, color: Color(0xFF4318FF)), onPressed: () => _showDetails(a), tooltip: 'View Announcement'),
                                IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showForm(announcement: a), tooltip: 'Edit Announcement'),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAnnouncement(a), tooltip: 'Delete Announcement'),
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
      ),
    );
  }
}
