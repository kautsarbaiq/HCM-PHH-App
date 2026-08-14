import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/repositories/merchant_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../theme/app_colors.dart';

/// Merchant portal → Shop profile (boss batch 08/08 point 2).
/// Logo, photos, location, address, contact — everything residents see.
class ShopProfilePage extends ConsumerStatefulWidget {
  const ShopProfilePage({super.key});

  @override
  ConsumerState<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends ConsumerState<ShopProfilePage> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _address = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  final _description = TextEditingController();

  String? _logoUrl;
  List<String> _photos = [];
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _category,
      _address,
      _location,
      _contact,
      _description
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Merchant? m) {
    if (_loaded || m == null) return;
    _loaded = true;
    _name.text = m.shopName;
    _category.text = m.category ?? '';
    _address.text = m.address ?? '';
    _location.text = m.location ?? '';
    _contact.text = m.contact ?? '';
    _description.text = m.description ?? '';
    _logoUrl = m.logoUrl;
    _photos = [...m.photos];
  }

  Future<Uint8List?> _pick() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    return x == null ? null : await x.readAsBytes();
  }

  Future<void> _pickLogo() async {
    final bytes = await _pick();
    if (bytes == null) return;
    final url =
        await ref.read(merchantRepositoryProvider).uploadShopImage(bytes, 'jpg');
    setState(() => _logoUrl = url);
  }

  Future<void> _addPhoto() async {
    final bytes = await _pick();
    if (bytes == null) return;
    final url =
        await ref.read(merchantRepositoryProvider).uploadShopImage(bytes, 'jpg');
    setState(() => _photos = [..._photos, url]);
  }

  Future<void> _save(String? id) async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(merchantRepositoryProvider).saveShop(
            id: id,
            shopName: _name.text.trim(),
            category: _category.text.trim(),
            logoUrl: _logoUrl,
            photos: _photos,
            address: _address.text.trim(),
            location: _location.text.trim(),
            contact: _contact.text.trim(),
            description: _description.text.trim(),
          );
      ref.invalidate(myShopProvider);
      messenger.showSnackBar(const SnackBar(
        content: Text('Shop profile saved'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _deco(String label, {String? helper}) => InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    return shopAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppErrorState(
        message: 'Could not load your shop: $e',
        onRetry: () => ref.invalidate(myShopProvider),
      ),
      data: (shop) {
        _fill(shop);
        return PremiumCard(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              SectionHeader(
                title: shop == null ? 'Create your shop' : 'Shop profile',
                subtitle:
                    'This is what residents see when they browse rewards',
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceTint,
                            borderRadius: BorderRadius.circular(20),
                            image: (_logoUrl ?? '').isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_logoUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: (_logoUrl ?? '').isEmpty
                              ? const Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.brand)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Logo',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                            controller: _name,
                            decoration: _deco('Shop name')),
                        const SizedBox(height: 14),
                        TextField(
                            controller: _category,
                            decoration: _deco('Category',
                                helper: 'e.g. Café, Restaurant, Grocery')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(controller: _contact, decoration: _deco('Contact number')),
              const SizedBox(height: 14),
              TextField(
                  controller: _address, maxLines: 2, decoration: _deco('Address')),
              const SizedBox(height: 14),
              TextField(
                controller: _location,
                decoration: _deco('Location',
                    helper: 'Google Maps link or coordinates'),
              ),
              const SizedBox(height: 14),
              TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: _deco('About the shop')),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Text('Photos',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add photo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_photos.isEmpty)
                const Text('No photos yet.',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary))
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final url in _photos)
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                  image: NetworkImage(url), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _photos = [..._photos]..remove(url)),
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 26),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : () => _save(shop?.id),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(shop == null ? 'Create shop' : 'Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
