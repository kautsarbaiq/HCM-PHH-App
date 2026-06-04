import 'package:flutter/material.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String date;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }
}

class AnnouncementsAdminPage extends StatefulWidget {
  const AnnouncementsAdminPage({super.key});

  @override
  State<AnnouncementsAdminPage> createState() => _AnnouncementsAdminPageState();
}

class _AnnouncementsAdminPageState extends State<AnnouncementsAdminPage> {
  final List<Announcement> _announcements = List.generate(5, (index) {
    return Announcement(
      id: '${index + 1}',
      title: 'Community Meeting ${index + 1}',
      content: 'This is a mock announcement regarding the upcoming community meeting to discuss the neighborhood watch program, cleanliness, and parking rules.',
      date: 'June ${10 + index}, 2026',
    );
  });

  void _showDetails(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.campaign, color: Color(0xFF4318FF)),
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
              Text(announcement.date, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12, fontWeight: FontWeight.bold)),
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

    showDialog(
      context: context,
      builder: (context) {
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                setState(() {
                  if (isEdit) {
                    final idx = _announcements.indexWhere((a) => a.id == announcement.id);
                    if (idx != -1) {
                      _announcements[idx] = announcement.copyWith(
                        title: titleController.text,
                        content: contentController.text,
                      );
                    }
                  } else {
                    _announcements.insert(0, Announcement(
                      id: '${_announcements.length + 1}',
                      title: titleController.text,
                      content: contentController.text,
                      date: 'June 05, 2026',
                    ));
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEdit ? 'Save' : 'Post'),
            ),
          ],
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
              onPressed: () {
                setState(() {
                  _announcements.removeWhere((a) => a.id == announcement.id);
                });
                Navigator.pop(context);
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
              child: _announcements.isEmpty
                  ? const Center(child: Text('No announcements posted yet', style: TextStyle(color: Color(0xFFA3AED0))))
                  : ListView.builder(
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final a = _announcements[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE0E5F2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF4F7FE),
                              child: Icon(Icons.campaign_rounded, color: Color(0xFF4318FF)),
                            ),
                            title: Text(
                              a.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
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
                                    a.date,
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
            ),
          ],
        ),
      ),
    );
  }
}
