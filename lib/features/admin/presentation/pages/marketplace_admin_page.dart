import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/marketplace_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminMarketplaceProvider =
    AsyncNotifierProvider<AdminMarketplaceNotifier, List<MarketService>>(
      () => AdminMarketplaceNotifier(),
    );

class AdminMarketplaceNotifier extends AsyncNotifier<List<MarketService>> {
  @override
  Future<List<MarketService>> build() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    return repo.getAllServices();
  }

  Future<void> addService({
    required String businessName,
    String? category,
    String? phone,
    String? description,
    double rating = 5.0,
    bool isVerified = true,
  }) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    await repo.createService(
      businessName: businessName,
      category: category,
      phone: phone,
      description: description,
      rating: rating,
      isVerified: isVerified,
    );
    ref.invalidateSelf();
  }

  Future<void> updateService(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    await repo.updateService(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteService(String id) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    await repo.deleteService(id);
    ref.invalidateSelf();
  }
}

class MarketplaceAdminPage extends ConsumerStatefulWidget {
  const MarketplaceAdminPage({super.key});

  @override
  ConsumerState<MarketplaceAdminPage> createState() =>
      _MarketplaceAdminPageState();
}

class _MarketplaceAdminPageState extends ConsumerState<MarketplaceAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showDetails(MarketService service) {
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
              const Icon(Icons.storefront_rounded, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  service.businessName,
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
                  Row(
                    children: [
                      if (service.category != null &&
                          service.category!.isNotEmpty) ...[
                        StatusPill(
                          label: service.category!,
                          color: AppColors.brand,
                          dense: true,
                        ),
                        const SizedBox(width: 8),
                      ],
                      StatusPill(
                        label: service.isVerified ? 'VERIFIED' : 'UNVERIFIED',
                        color: service.isVerified
                            ? AppColors.success
                            : AppColors.textSecondary,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.accentAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (service.phone != null && service.phone!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service.phone!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      service.description!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
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

  void _showForm({MarketService? service}) {
    final isEdit = service != null;
    final nameController = TextEditingController(
      text: service?.businessName ?? '',
    );
    final categoryController = TextEditingController(
      text: service?.category ?? '',
    );
    final phoneController = TextEditingController(text: service?.phone ?? '');
    final descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    final ratingController = TextEditingController(
      text: (service?.rating ?? 5.0).toStringAsFixed(1),
    );
    bool isVerified = service?.isVerified ?? true;
    bool isSaving = false;

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
                isEdit ? 'Edit Service' : 'Add New Service',
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
                      _buildTextField(
                        nameController,
                        'Business Name',
                        Icons.storefront_rounded,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        categoryController,
                        'Category (e.g. Cleaning, Plumbing)',
                        Icons.category_rounded,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        phoneController,
                        'Phone',
                        Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        descriptionController,
                        'Description',
                        Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        ratingController,
                        'Rating (0 - 5)',
                        Icons.star_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.success,
                        title: const Text(
                          'Verified',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Verified services display a trust badge to residents',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: isVerified,
                        onChanged: (val) =>
                            setDialogState(() => isVerified = val),
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
                          if (nameController.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a business name.'),
                              ),
                            );
                            return;
                          }
                          double rating =
                              double.tryParse(ratingController.text.trim()) ??
                              5.0;
                          if (rating < 0) rating = 0;
                          if (rating > 5) rating = 5;
                          final category = categoryController.text.trim();
                          final phone = phoneController.text.trim();
                          final description =
                              descriptionController.text.trim();
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminMarketplaceProvider.notifier)
                                  .updateService(service.id, {
                                    'business_name': nameController.text.trim(),
                                    'category':
                                        category.isEmpty ? null : category,
                                    'phone': phone.isEmpty ? null : phone,
                                    'description': description.isEmpty
                                        ? null
                                        : description,
                                    'rating': rating,
                                    'is_verified': isVerified,
                                  });
                            } else {
                              await ref
                                  .read(adminMarketplaceProvider.notifier)
                                  .addService(
                                    businessName: nameController.text.trim(),
                                    category:
                                        category.isEmpty ? null : category,
                                    phone: phone.isEmpty ? null : phone,
                                    description: description.isEmpty
                                        ? null
                                        : description,
                                    rating: rating,
                                    isVerified: isVerified,
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
                      : Text(isEdit ? 'Save Changes' : 'Create'),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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

  void _deleteService(MarketService service) {
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
            'Delete Service',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${service.businessName}"?',
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
                      .read(adminMarketplaceProvider.notifier)
                      .deleteService(service.id);
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
    final servicesAsync = ref.watch(adminMarketplaceProvider);

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
                  title: 'Market Square',
                  subtitle: 'Manage neighbourhood home-service listings',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Service'),
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
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminMarketplaceProvider),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No services listed yet',
                    message:
                        'Add a neighbourhood business or home-service provider.',
                    actionLabel: 'Add Service',
                    onAction: () => _showForm(),
                    gradient: AppColors.mintGradient,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminMarketplaceProvider),
                  child: ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final s = services[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const GradientIconBadge(
                            icon: Icons.storefront_rounded,
                            gradient: AppColors.brandGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (s.isVerified) ...[
                                const SizedBox(width: 8),
                                const StatusPill(
                                  label: 'VERIFIED',
                                  color: AppColors.success,
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
                                Row(
                                  children: [
                                    if (s.category != null &&
                                        s.category!.isNotEmpty) ...[
                                      StatusPill(
                                        label: s.category!,
                                        color: AppColors.brand,
                                        dense: true,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.accentAmber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      s.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (s.phone != null &&
                                    s.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    s.phone!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                                onPressed: () => _showDetails(s),
                                tooltip: 'View Service',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(service: s),
                                tooltip: 'Edit Service',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteService(s),
                                tooltip: 'Delete Service',
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
