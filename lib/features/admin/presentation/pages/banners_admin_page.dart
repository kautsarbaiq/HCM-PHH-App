import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/banner_repository.dart';

const _kDefaultBannerImage =
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80';

final adminBannersProvider =
    AsyncNotifierProvider<AdminBannersNotifier, List<BannerItem>>(
        () => AdminBannersNotifier());

class AdminBannersNotifier extends AsyncNotifier<List<BannerItem>> {
  @override
  Future<List<BannerItem>> build() async {
    final repo = ref.read(bannerRepositoryProvider);
    return repo.getAllBanners();
  }

  Future<void> addBanner(BannerItem banner) async {
    final repo = ref.read(bannerRepositoryProvider);
    await repo.createBanner(banner);
    ref.invalidateSelf();
  }

  Future<void> updateBanner(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(bannerRepositoryProvider);
    await repo.updateBanner(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteBanner(String id) async {
    final repo = ref.read(bannerRepositoryProvider);
    await repo.deleteBanner(id);
    ref.invalidateSelf();
  }
}

class BannersAdminPage extends ConsumerStatefulWidget {
  const BannersAdminPage({super.key});

  @override
  ConsumerState<BannersAdminPage> createState() => _BannersAdminPageState();
}

class _BannersAdminPageState extends ConsumerState<BannersAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showForm({BannerItem? banner, required int currentCount}) {
    final isEdit = banner != null;
    final titleController = TextEditingController(text: banner?.title ?? '');
    final urlController = TextEditingController(text: banner?.imageUrl ?? '');
    bool isActive = banner?.isActive ?? true;
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
                isEdit ? 'Edit Banner' : 'Add New Banner',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(titleController, 'Banner Title', Icons.title),
                    _buildTextField(urlController, 'Image URL (optional)', Icons.link),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF05CD99),
                      title: const Text('Active', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                      subtitle: const Text('Only active banners are shown to residents', style: TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
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
                          if (titleController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter a banner title.')),
                            );
                            return;
                          }
                          final finalUrl = urlController.text.isEmpty ? _kDefaultBannerImage : urlController.text;
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref.read(adminBannersProvider.notifier).updateBanner(banner.id, {
                                'title': titleController.text,
                                'image_url': finalUrl,
                                'is_active': isActive,
                              });
                            } else {
                              await ref.read(adminBannersProvider.notifier).addBanner(BannerItem(
                                    id: '',
                                    title: titleController.text,
                                    imageUrl: finalUrl,
                                    isActive: isActive,
                                    sortOrder: currentCount,
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
                      : Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref.read(adminBannersProvider.notifier).deleteBanner(banner.id);
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
    final bannersAsync = ref.watch(adminBannersProvider);

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
                  onPressed: () => _showForm(currentCount: bannersAsync.valueOrNull?.length ?? 0),
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
              child: bannersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Color(0xFFA3AED0)))),
                data: (banners) {
                  if (banners.isEmpty) {
                    return const Center(child: Text('No banners active', style: TextStyle(color: Color(0xFFA3AED0))));
                  }
                  return LayoutBuilder(
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
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final b = banners[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: b.isActive ? 1.0 : 0.45,
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
                                // Inactive badge
                                if (!b.isActive)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('INACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                          onPressed: () => _showForm(banner: b, currentCount: banners.length),
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
