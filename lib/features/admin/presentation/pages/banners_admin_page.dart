import 'package:flutter/material.dart';

class BannerItem {
  final String id;
  final String title;
  final String imageUrl;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  BannerItem copyWith({
    String? id,
    String? title,
    String? imageUrl,
  }) {
    return BannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class BannersAdminPage extends StatefulWidget {
  const BannersAdminPage({super.key});

  @override
  State<BannersAdminPage> createState() => _BannersAdminPageState();
}

class _BannersAdminPageState extends State<BannersAdminPage> {
  final List<BannerItem> _banners = List.generate(4, (index) {
    return BannerItem(
      id: '${index + 1}',
      title: 'Community Banner ${index + 1}',
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
    );
  });

  void _showForm({BannerItem? banner}) {
    final isEdit = banner != null;
    final titleController = TextEditingController(text: banner?.title ?? '');
    final urlController = TextEditingController(text: banner?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Banner' : 'Add New Banner',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleController, 'Banner Title', Icons.title),
                _buildTextField(urlController, 'Image URL (optional)', Icons.link),
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
                if (titleController.text.isEmpty) return;
                setState(() {
                  final finalUrl = urlController.text.isEmpty
                      ? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80'
                      : urlController.text;

                  if (isEdit) {
                    final idx = _banners.indexWhere((b) => b.id == banner.id);
                    if (idx != -1) {
                      _banners[idx] = banner.copyWith(
                        title: titleController.text,
                        imageUrl: finalUrl,
                      );
                    }
                  } else {
                    _banners.add(BannerItem(
                      id: '${_banners.length + 1}',
                      title: titleController.text,
                      imageUrl: finalUrl,
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
              child: Text(isEdit ? 'Save Changes' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFA3AED0)),
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

  void _deleteBanner(BannerItem banner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Banner', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete "${banner.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _banners.removeWhere((b) => b.id == banner.id);
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
                    'Banners Management',
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
                  label: const Text('Add Banner'),
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
              child: _banners.isEmpty
                  ? const Center(child: Text('No banners active', style: TextStyle(color: Color(0xFFA3AED0))))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 800) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 500) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 16 / 10,
                          ),
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            final b = _banners[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      b.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFF4F7FE),
                                          child: const Icon(Icons.broken_image, color: Color(0xFFA3AED0), size: 40),
                                        );
                                      },
                                    ),
                                  ),
                                  // Bottom Banner Title Overlay
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        b.title,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Top Right Action Buttons
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.orange, size: 16),
                                            onPressed: () => _showForm(banner: b),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            tooltip: 'Edit Banner',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                            onPressed: () => _deleteBanner(b),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            tooltip: 'Delete Banner',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
