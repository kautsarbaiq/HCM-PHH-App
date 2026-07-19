import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/house_repository.dart';
import '../../../../core/repositories/parking_repository.dart';
import '../../../parking/parking_ui.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminHousesProvider =
    AsyncNotifierProvider<AdminHousesNotifier, List<House>>(
      () => AdminHousesNotifier(),
    );

class AdminHousesNotifier extends AsyncNotifier<List<House>> {
  @override
  Future<List<House>> build() async {
    final repo = ref.read(houseRepositoryProvider);
    return repo.getAllHouses();
  }

  Future<void> addHouse(House house) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.createHouse(house);
    ref.invalidateSelf();
  }

  Future<void> updateHouse(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.updateHouse(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteHouse(String id) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.deleteHouse(id);
    ref.invalidateSelf();
  }
}

class HousesAdminPage extends ConsumerStatefulWidget {
  const HousesAdminPage({super.key});

  @override
  ConsumerState<HousesAdminPage> createState() => _HousesAdminPageState();
}

class _HousesAdminPageState extends ConsumerState<HousesAdminPage> {
  String _searchQuery = '';

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  // Derives the occupant name for a house from the residents list, since
  // residents are linked via profiles.house_id rather than houses.owner_id.
  String _occupantName(House house) {
    final residents = ref.read(adminResidentsProvider).valueOrNull;
    if (residents != null) {
      for (final r in residents) {
        if (r.houseId == house.id) return r.fullName;
      }
    }
    // No resident assigned. Don't fall back to a possibly-stale owner_id join —
    // that caused every house to show the same person ("Demo").
    return '-';
  }

  // HCA: the house's bay numbers for the Parking column (realtime-refreshed
  // via allParkingBaysProvider).
  String _bayNumbers(House house) {
    final byHouse = ref.watch(allParkingBaysProvider).valueOrNull;
    final bays = byHouse?[house.id];
    if (bays == null || bays.isEmpty) return '-';
    return bays.map((b) => b.bayNumber).join(', ');
  }

  List<House> _filterHouses(List<House> houses) {
    if (_searchQuery.isEmpty) return houses;
    final q = _searchQuery.toLowerCase();
    return houses.where((house) {
      final matchesNo = house.houseNumber.toLowerCase().contains(q);
      final matchesOwner = _occupantName(house).toLowerCase().contains(q);
      return matchesNo || matchesOwner;
    }).toList();
  }

  void _showDetails(House house) {
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
              const Icon(Icons.house_rounded, color: AppColors.brand),
              const SizedBox(width: 8),
              Text(
                house.houseNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('ID', house.id),
                  _buildDetailItem('House No / Address', house.houseNumber),
                  _buildDetailItem(
                    'Address',
                    house.address?.isNotEmpty == true ? house.address! : '-',
                  ),
                  _buildDetailItem('Owner / Occupant', _occupantName(house)),
                  _buildDetailItem('Unit Type', house.houseType),
                  _buildDetailItem(
                    'Occupancy Status',
                    house.status == 'occupied' ? 'Occupied' : 'Vacant',
                    isStatus: true,
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

  Widget _buildDetailItem(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (isStatus)
            StatusPill(
              label: value,
              color: value == 'Occupied'
                  ? AppColors.success
                  : AppColors.warning,
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _showForm({House? house}) {
    final isEdit = house != null;
    final houseNoController = TextEditingController(
      text: house?.houseNumber ?? '',
    );
    final typeController = TextEditingController(
      text: house?.houseType ?? 'Type A',
    );
    final addressController = TextEditingController(text: house?.address ?? '');
    String status = house?.status ?? 'vacant';
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
                isEdit ? 'Edit House' : 'Add New House',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        houseNoController,
                        'House Number / Block',
                        Icons.house,
                      ),
                      _buildTextField(
                        typeController,
                        'Unit Type (e.g. Type A)',
                        Icons.layers,
                      ),
                      _buildTextField(
                        addressController,
                        'Address (optional)',
                        Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Status: ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                ChoiceChip(
                                  label: const Text('Occupied'),
                                  selected: status == 'occupied',
                                  selectedColor: AppColors.success.withOpacity(
                                    0.2,
                                  ),
                                  checkmarkColor: AppColors.success,
                                  onSelected: (val) {
                                    if (val)
                                      setDialogState(() => status = 'occupied');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Vacant'),
                                  selected: status == 'vacant',
                                  selectedColor: AppColors.warning.withOpacity(
                                    0.2,
                                  ),
                                  checkmarkColor: AppColors.warning,
                                  onSelected: (val) {
                                    if (val)
                                      setDialogState(() => status = 'vacant');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          if (houseNoController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a house number.'),
                              ),
                            );
                            return;
                          }
                          final navigator = Navigator.of(context);
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminHousesProvider.notifier)
                                  .updateHouse(house.id, {
                                    'house_number': houseNoController.text,
                                    'house_type': typeController.text,
                                    'status': status,
                                    'address':
                                        addressController.text.trim().isEmpty
                                        ? null
                                        : addressController.text.trim(),
                                  });
                            } else {
                              await ref
                                  .read(adminHousesProvider.notifier)
                                  .addHouse(
                                    House(
                                      id: '',
                                      houseNumber: houseNoController.text,
                                      houseType: typeController.text,
                                      status: status,
                                      address:
                                          addressController.text.trim().isEmpty
                                          ? null
                                          : addressController.text.trim(),
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
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
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

  // HCA point 16: admin creates a login account for the owner of this house.
  void _showCreateOwnerForm(House house) {
    final nameController = TextEditingController();
    final icController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            InputDecoration deco(String label) => InputDecoration(
              labelText: label,
              filled: true,
              fillColor: const Color(0xFFF4F6FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            );

            Future<void> submit() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final pass = passwordController.text;
              if (name.isEmpty || email.isEmpty || pass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Name, email and a 6+ character password are required',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setDialogState(() => isSaving = true);
              try {
                await ref
                    .read(houseRepositoryProvider)
                    .createOwnerAccount(
                      houseId: house.id,
                      fullName: name,
                      email: email,
                      password: pass,
                      phone: phoneController.text.trim(),
                      icNumber: icController.text.trim(),
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
                ref.invalidate(adminHousesProvider);
                ref.invalidate(adminResidentsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Owner login created for ${house.houseNumber}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                setDialogState(() => isSaving = false);
                if (context.mounted) _showError(e);
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                'Create owner login — ${house.houseNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: deco('Full name'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: icController,
                        decoration: deco('IC / passport number'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: deco('Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: deco('Login email'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: deco('Password (min 6 chars)').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () =>
                                setDialogState(() => obscure = !obscure),
                          ),
                        ),
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
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                  ),
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create login'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteHouse(House house) {
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
            'Delete House',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${house.houseNumber}? This action cannot be undone.',
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
                      .read(adminHousesProvider.notifier)
                      .deleteHouse(house.id);
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
    final housesAsync = ref.watch(adminHousesProvider);
    // Warm the residents list so occupant names resolve in the Owner column.
    ref.watch(adminResidentsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Houses & Units',
                  subtitle: 'Manage units and occupancy',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add House'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by house number or owner...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceTint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: housesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminHousesProvider),
              ),
              data: (houses) {
                final filteredHouses = _filterHouses(houses);

                if (filteredHouses.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.house_rounded,
                    title: 'No houses found',
                    message: 'Add a house to get started.',
                    actionLabel: 'Add House',
                    onAction: () => _showForm(),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // On narrow phones, render a vertical card list instead of a wide table.
                    if (constraints.maxWidth < 600) {
                      return ListView.separated(
                        itemCount: filteredHouses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildHouseCard(filteredHouses[index]),
                      );
                    }
                    // Distribute the table across the full viewport width so it
                    // reaches the right edge instead of clustering on the left.
                    // The horizontal margin/spacing/action column are fixed; the
                    // three text columns share the remaining width evenly.
                    const horizontalMargin = 20.0;
                    const columnSpacing = 24.0;
                    // HCA has two extra action buttons (parking + owner login)
                    // and an extra Parking column.
                    const actionsColWidth = 268.0;
                    const statusColWidth = 120.0;
                    const flexCols = 4;
                    final fullWidth = constraints.maxWidth;
                    // Width consumed by fixed chrome: outer margins, the spacing
                    // between the columns, and the fixed status/actions columns.
                    final fixed =
                        horizontalMargin * 2 +
                        columnSpacing * (flexCols + 1) +
                        statusColWidth +
                        actionsColWidth;
                    final flexColWidth = ((fullWidth - fixed) / flexCols).clamp(
                      120.0,
                      double.infinity,
                    );
                    return Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E5F2)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          // Let the table fill the available width on laptops so
                          // it doesn't leave an empty gap, while still scrolling
                          // horizontally when the viewport is too narrow.
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: columnSpacing,
                              horizontalMargin: horizontalMargin,
                              headingRowColor: MaterialStateProperty.all(
                                AppColors.surfaceTint,
                              ),
                              columns: [
                                const DataColumn(
                                  label: Text(
                                    'House No.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Type',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Owner',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Parking',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              rows: filteredHouses.map((house) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: flexColWidth,
                                        child: Text(
                                          house.houseNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: flexColWidth,
                                        child: Text(
                                          house.houseType,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: flexColWidth,
                                        child: Text(
                                          _occupantName(house),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: flexColWidth,
                                        child: Text(
                                          _bayNumbers(house),
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: statusColWidth,
                                        child: StatusPill(
                                          label: house.status == 'occupied'
                                              ? 'Occupied'
                                              : 'Vacant',
                                          color: house.status == 'occupied'
                                              ? AppColors.success
                                              : AppColors.warning,
                                          dense: true,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: actionsColWidth,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.visibility_rounded,
                                                color: AppColors.textSecondary,
                                              ),
                                              onPressed: () =>
                                                  _showDetails(house),
                                              tooltip: 'View Details',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.local_parking_rounded,
                                                color: AppColors.accentSky,
                                              ),
                                              onPressed: () =>
                                                  showAdminParkingSheet(
                                                    context,
                                                    house.id,
                                                    house.houseNumber,
                                                  ),
                                              tooltip: 'Parking bays',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.person_add_alt_1_rounded,
                                                color: AppColors.success,
                                              ),
                                              onPressed: () =>
                                                  _showCreateOwnerForm(house),
                                              tooltip: 'Create owner login',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_rounded,
                                                color: AppColors.brand,
                                              ),
                                              onPressed: () =>
                                                  _showForm(house: house),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_rounded,
                                                color: AppColors.error,
                                              ),
                                              onPressed: () =>
                                                  _deleteHouse(house),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Compact card used for the narrow-phone houses layout.
  Widget _buildHouseCard(House house) {
    final isOccupied = house.status == 'occupied';
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      onTap: () => _showDetails(house),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.house_rounded,
                gradient: AppColors.skyGradient,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  house.houseNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusPill(
                label: isOccupied ? 'Occupied' : 'Vacant',
                color: isOccupied ? AppColors.success : AppColors.warning,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Type: ${house.houseType}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Owner: ${_occupantName(house)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          ...[
            const SizedBox(height: 2),
            Text(
              'Parking: ${_bayNumbers(house)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _showDetails(house),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(
                  Icons.local_parking_rounded,
                  color: AppColors.accentSky,
                  size: 20,
                ),
                onPressed: () => showAdminParkingSheet(
                  context,
                  house.id,
                  house.houseNumber,
                ),
                tooltip: 'Parking bays',
              ),
              IconButton(
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                onPressed: () => _showCreateOwnerForm(house),
                tooltip: 'Create owner login',
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
                onPressed: () => _showForm(house: house),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _deleteHouse(house),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
