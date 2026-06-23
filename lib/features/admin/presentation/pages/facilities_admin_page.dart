import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/facility_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

const List<String> _kFacilityIcons = [
  'swimming',
  'gym',
  'bbq',
  'tennis',
  'hall',
  'playground',
];

final adminFacilitiesProvider =
    AsyncNotifierProvider<AdminFacilitiesNotifier, List<Facility>>(
      () => AdminFacilitiesNotifier(),
    );

class AdminFacilitiesNotifier extends AsyncNotifier<List<Facility>> {
  @override
  Future<List<Facility>> build() async {
    final repo = ref.read(facilityRepositoryProvider);
    return repo.getAllFacilitiesIncludingInactive();
  }

  Future<void> addFacility({
    required String name,
    String? description,
    String? iconName,
    int? maxCapacity,
    bool isActive = true,
  }) async {
    final repo = ref.read(facilityRepositoryProvider);
    await repo.createFacility(
      name: name,
      description: description,
      iconName: iconName,
      maxCapacity: maxCapacity,
      isActive: isActive,
    );
    ref.invalidateSelf();
  }

  Future<void> updateFacility(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(facilityRepositoryProvider);
    await repo.updateFacility(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteFacility(String id) async {
    final repo = ref.read(facilityRepositoryProvider);
    await repo.deleteFacility(id);
    ref.invalidateSelf();
  }
}

class FacilitiesAdminPage extends ConsumerStatefulWidget {
  const FacilitiesAdminPage({super.key});

  @override
  ConsumerState<FacilitiesAdminPage> createState() =>
      _FacilitiesAdminPageState();
}

class _FacilitiesAdminPageState extends ConsumerState<FacilitiesAdminPage> {
  IconData _iconFor(String? iconName) {
    switch (iconName) {
      case 'swimming':
        return Icons.pool_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'bbq':
        return Icons.outdoor_grill_rounded;
      case 'tennis':
        return Icons.sports_tennis_rounded;
      case 'hall':
        return Icons.meeting_room_rounded;
      case 'playground':
        return Icons.child_friendly_rounded;
      default:
        return Icons.apartment_rounded;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showForm({Facility? facility}) {
    final isEdit = facility != null;
    final nameController = TextEditingController(text: facility?.name ?? '');
    final descriptionController = TextEditingController(
      text: facility?.description ?? '',
    );
    final capacityController = TextEditingController(
      text: facility?.maxCapacity?.toString() ?? '',
    );
    String iconName =
        (facility?.iconName != null &&
            _kFacilityIcons.contains(facility!.iconName))
        ? facility.iconName!
        : _kFacilityIcons.first;
    bool isActive = facility?.isActive ?? true;
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
                isEdit ? 'Edit Facility' : 'Create Facility',
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
                        'Facility Name',
                        Icons.apartment_rounded,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        descriptionController,
                        'Description',
                        Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: iconName,
                        decoration: InputDecoration(
                          labelText: 'Icon',
                          prefixIcon: Icon(
                            _iconFor(iconName),
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E5F2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E5F2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.brand),
                          ),
                        ),
                        items: _kFacilityIcons
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconFor(name),
                                      size: 18,
                                      color: AppColors.brand,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      name[0].toUpperCase() + name.substring(1),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => iconName = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        capacityController,
                        'Max Capacity',
                        Icons.group_rounded,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.success,
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Only active facilities are bookable by residents',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: isActive,
                        onChanged: (val) =>
                            setDialogState(() => isActive = val),
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
                                content: Text('Please enter a facility name.'),
                              ),
                            );
                            return;
                          }
                          final capacity = capacityController.text.trim().isEmpty
                              ? null
                              : int.tryParse(capacityController.text.trim());
                          final description =
                              descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim();
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminFacilitiesProvider.notifier)
                                  .updateFacility(facility.id, {
                                    'name': nameController.text.trim(),
                                    'description': description,
                                    'icon_name': iconName,
                                    'max_capacity': capacity,
                                    'is_active': isActive,
                                  });
                            } else {
                              await ref
                                  .read(adminFacilitiesProvider.notifier)
                                  .addFacility(
                                    name: nameController.text.trim(),
                                    description: description,
                                    iconName: iconName,
                                    maxCapacity: capacity,
                                    isActive: isActive,
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
    bool digitsOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
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

  void _deleteFacility(Facility facility) {
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
            'Delete Facility',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${facility.name}"?',
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
                      .read(adminFacilitiesProvider.notifier)
                      .deleteFacility(facility.id);
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
    final facilitiesAsync = ref.watch(adminFacilitiesProvider);

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
                  title: 'Facilities',
                  subtitle: 'Manage bookable community amenities',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Facility'),
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
            child: facilitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminFacilitiesProvider),
              ),
              data: (facilities) {
                if (facilities.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.pool_rounded,
                    title: 'No facilities yet',
                    message:
                        'Add a bookable amenity for residents to reserve.',
                    actionLabel: 'Create Facility',
                    onAction: () => _showForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminFacilitiesProvider),
                  child: ListView.builder(
                    itemCount: facilities.length,
                    itemBuilder: (context, index) {
                      final f = facilities[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: _iconFor(f.iconName),
                            gradient: f.isActive
                                ? AppColors.brandGradient
                                : AppColors.skyGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  f.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: f.isActive ? 'ACTIVE' : 'INACTIVE',
                                color: f.isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                dense: true,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (f.description != null &&
                                    f.description!.isNotEmpty)
                                  Text(
                                    f.description!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  f.maxCapacity != null
                                      ? 'Capacity: ${f.maxCapacity}'
                                      : 'Capacity: not set',
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
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(facility: f),
                                tooltip: 'Edit Facility',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteFacility(f),
                                tooltip: 'Delete Facility',
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
