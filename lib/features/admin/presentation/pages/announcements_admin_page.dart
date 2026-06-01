import 'package:flutter/material.dart';

class AnnouncementsAdminPage extends StatelessWidget {
  const AnnouncementsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
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
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
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
                    'Community Meeting $index',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'This is a mock announcement regarding the upcoming community meeting to discuss the neighborhood watch program.',
                      style: TextStyle(color: Color(0xFFA3AED0)),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Color(0xFF4318FF)), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
