import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/document_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import 'houses_admin_page.dart'; // to get adminHousesProvider

class ResidentsAdminPage extends ConsumerStatefulWidget {
  const ResidentsAdminPage({super.key});

  @override
  ConsumerState<ResidentsAdminPage> createState() => _ResidentsAdminPageState();
}

class _ResidentsAdminPageState extends ConsumerState<ResidentsAdminPage> {
  String _searchQuery = '';

  List<Profile> _filterResidents(List<Profile> residents) {
    if (_searchQuery.isEmpty) return residents;
    return residents.where((resident) {
      final matchesName = resident.fullName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesEmail =
          resident.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
          false;
      return matchesName || matchesEmail;
    }).toList();
  }

  // Resolves a resident's houseId to a human-readable house number.
  String _houseLabel(String? houseId) {
    if (houseId == null || houseId.isEmpty) return 'Not Assigned';
    final houses = ref.read(adminHousesProvider).valueOrNull;
    if (houses == null) return 'Assigned';
    for (final house in houses) {
      if (house.id == houseId) {
        return '${house.houseNumber} (${house.houseType})';
      }
    }
    return 'Assigned';
  }

  void _showDetails(Profile resident) {
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
              const Icon(Icons.person, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resident.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
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
                  _buildDetailItem(
                    'House / Unit',
                    _houseLabel(resident.houseId),
                  ),
                  _buildDetailItem('Email Address', resident.email ?? '-'),
                  _buildDetailItem('Phone Number', resident.phone ?? '-'),
                  _buildDetailItem(
                    'Account Status',
                    resident.status,
                    isStatus: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Documents',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildResidentDocuments(resident.id),
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
              label: value.toUpperCase(),
              color: value == 'active' ? AppColors.success : AppColors.warning,
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

  // Loads and lists the given resident's personal documents inside the detail
  // dialog. Admins can open/download each file via a short-lived signed URL.
  Widget _buildResidentDocuments(String userId) {
    return FutureBuilder<List<ResidentDocument>>(
      future: ref
          .read(documentRepositoryProvider)
          .getResidentDocumentsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Text(
            'Could not load documents',
            style: TextStyle(color: AppColors.warning, fontSize: 13),
          );
        }
        final docs = snapshot.data ?? const <ResidentDocument>[];
        if (docs.isEmpty) {
          return const Text(
            'No documents uploaded',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map(_buildDocumentRow).toList(),
        );
      },
    );
  }

  Widget _buildDocumentRow(ResidentDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if (doc.documentType != null &&
                    doc.documentType!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    doc.documentType!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.brand,
              size: 20,
            ),
            tooltip: 'Open document',
            onPressed: () => _openDocument(doc),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(ResidentDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final signed = await ref
        .read(storageRepositoryProvider)
        .signedResidentDocUrl(doc.fileUrl ?? '');
    if (!mounted) return;
    if (signed != null) {
      await launchUrl(Uri.parse(signed), mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('File unavailable')));
    }
  }

  void _showForm(Profile resident) {
    showDialog(
      context: context,
      builder: (context) {
        return _ResidentEditDialog(resident: resident);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final residentsAsync = ref.watch(adminResidentsProvider);
    // Warm the houses list so house labels resolve to readable numbers.
    ref.watch(adminHousesProvider);

    // Full-width content on web — stretch so the table/rows fill the area up to
    // the right edge (start-alignment let the list shrink to its row content).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const SectionHeader(
          title: 'Residents Management',
          subtitle: 'Manage residents, houses and account status',
        ),
        const SizedBox(height: 16),

        // Info banner: residents self-register, so there is no manual "add".
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brand.withOpacity(0.12)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.brand,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Residents register through the app directly. Use the edit action to assign a house or change status.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar — single full-width field, no nested icon box.
        TextField(
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search residents by name or email...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Residents Table
        Expanded(
          child: PremiumCard(
            padding: EdgeInsets.zero,
            radius: 22,
            child: residentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AppErrorState(
                message: '$err',
                onRetry: () => ref.invalidate(adminResidentsProvider),
              ),
              data: (residentsList) {
                final filtered = _filterResidents(residentsList);
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_alt_rounded,
                    title: 'No residents found',
                    message: 'Residents will appear here once they register.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // On narrow phones, render stacked vertical cards (no wide row).
                    if (constraints.maxWidth < 600) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildResidentMobileCard(filtered[index]),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppColors.surfaceTint,
                      ),
                      itemBuilder: (context, index) {
                        final resident = filtered[index];
                        return _buildResidentCard(resident);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentCard(Profile resident) {
    final isActive = resident.status == 'active';
    return InkWell(
      onTap: () => _showDetails(resident),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            const GradientIconBadge(
              icon: Icons.person_rounded,
              gradient: AppColors.brandGradient,
              size: 46,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resident.email ?? 'No email',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _houseLabel(resident.houseId),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                StatusPill(
                  label: resident.status.toUpperCase(),
                  color: isActive ? AppColors.success : AppColors.warning,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () => _showForm(resident),
            ),
          ],
        ),
      ),
    );
  }

  // Compact, stacked card used for the narrow-phone residents layout.
  Widget _buildResidentMobileCard(Profile resident) {
    final isActive = resident.status == 'active';
    final contact = (resident.email != null && resident.email!.isNotEmpty)
        ? resident.email!
        : (resident.phone != null && resident.phone!.isNotEmpty
              ? resident.phone!
              : 'No contact');
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      onTap: () => _showDetails(resident),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.person_rounded,
                gradient: AppColors.brandGradient,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resident.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              StatusPill(
                label: resident.status.toUpperCase(),
                color: isActive ? AppColors.success : AppColors.warning,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contact,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'House: ${_houseLabel(resident.houseId)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
                onPressed: () => _showDetails(resident),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _showForm(resident),
                tooltip: 'Edit',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResidentEditDialog extends ConsumerStatefulWidget {
  final Profile resident;
  const _ResidentEditDialog({required this.resident});

  @override
  ConsumerState<_ResidentEditDialog> createState() =>
      _ResidentEditDialogState();
}

class _ResidentEditDialogState extends ConsumerState<_ResidentEditDialog> {
  String? _selectedHouseId;
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedHouseId = widget.resident.houseId;
    _status = widget.resident.status;
  }

  @override
  Widget build(BuildContext context) {
    final housesAsync = ref.watch(adminHousesProvider);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: const Text(
        'Edit Resident',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign to House',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              housesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text('Error loading houses: $e'),
                data: (houses) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E5F2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        // Guard against a houseId that isn't in the loaded list
                        // (deleted/renamed house) — an unknown value asserts.
                        value: houses.any((h) => h.id == _selectedHouseId)
                            ? _selectedHouseId
                            : null,
                        hint: const Text('Select a house'),
                        items: houses.map((house) {
                          return DropdownMenuItem(
                            value: house.id,
                            child: Text(
                              '${house.houseNumber} (${house.houseType})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedHouseId = val;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Status: ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Active'),
                    selected: _status == 'active',
                    selectedColor: AppColors.success.withOpacity(0.2),
                    checkmarkColor: AppColors.success,
                    onSelected: (val) {
                      if (val) setState(() => _status = 'active');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Inactive'),
                    selected: _status == 'inactive',
                    selectedColor: AppColors.warning.withOpacity(0.2),
                    checkmarkColor: AppColors.warning,
                    onSelected: (val) {
                      if (val) setState(() => _status = 'inactive');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _isLoading = true);
                  try {
                    final repo = ref.read(adminRepositoryProvider);
                    if (_selectedHouseId != null &&
                        _selectedHouseId != widget.resident.houseId) {
                      await repo.assignHouseToResident(
                        widget.resident.id,
                        _selectedHouseId!,
                      );
                    }
                    if (_status != widget.resident.status) {
                      await repo.updateResidentStatus(
                        widget.resident.id,
                        _status,
                      );
                    }
                    ref.invalidate(adminResidentsProvider);
                    // houses.owner_id changed → refresh the houses cache so the
                    // billing form doesn't bill a stale (previous) owner.
                    ref.invalidate(adminHousesProvider);
                    navigator.pop();
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
