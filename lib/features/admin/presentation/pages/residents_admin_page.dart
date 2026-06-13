import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/house_repository.dart';
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
      final matchesName = resident.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesEmail = resident.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return matchesName || matchesEmail;
    }).toList();
  }

  void _showDetails(Profile resident) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF4318FF)),
              const SizedBox(width: 8),
              Text(
                resident.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', resident.id),
              _buildDetailItem('House/Unit ID', resident.houseId ?? 'Not Assigned'),
              _buildDetailItem('Email Address', resident.email ?? '-'),
              _buildDetailItem('Phone Number', resident.phone ?? '-'),
              _buildDetailItem('Account Status', resident.status, isStatus: true),
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

  Widget _buildDetailItem(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
          const SizedBox(height: 4),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (value == 'active' ? const Color(0xFF05CD99) : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value.toUpperCase(),
                style: TextStyle(
                  color: value == 'active' ? const Color(0xFF05CD99) : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674), fontSize: 16),
            ),
        ],
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Residents Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Residents should register through the app directly.'))
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Resident'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search residents by name or email...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFFA3AED0)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Residents Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: residentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (residentsList) {
                    final filtered = _filterResidents(residentsList);
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No residents found.',
                          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF4F7FE)),
                      itemBuilder: (context, index) {
                        final resident = filtered[index];
                        return _buildResidentCard(resident);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentCard(Profile resident) {
    return InkWell(
      onTap: () => _showDetails(resident),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF4318FF).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFF4318FF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2B3674)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resident.email ?? 'No email',
                    style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  resident.houseId != null ? 'Assigned' : 'Not Assigned',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (resident.status == 'active' ? const Color(0xFF05CD99) : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resident.status.toUpperCase(),
                    style: TextStyle(
                      color: resident.status == 'active' ? const Color(0xFF05CD99) : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFA3AED0)),
              onPressed: () => _showForm(resident),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentEditDialog extends ConsumerStatefulWidget {
  final Profile resident;
  const _ResidentEditDialog({required this.resident});

  @override
  ConsumerState<_ResidentEditDialog> createState() => _ResidentEditDialogState();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Edit Resident',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign to House', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                      value: _selectedHouseId,
                      hint: const Text('Select a house'),
                      items: houses.map((house) {
                        return DropdownMenuItem(
                          value: house.id,
                          child: Text('${house.houseNumber} (${house.houseType})'),
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
            const SizedBox(height: 16),
            const Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _status == 'active',
                  selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF05CD99),
                  onSelected: (val) {
                    if (val) setState(() => _status = 'active');
                  },
                ),
                ChoiceChip(
                  label: const Text('Inactive'),
                  selected: _status == 'inactive',
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                  onSelected: (val) {
                    if (val) setState(() => _status = 'inactive');
                  },
                ),
              ],
            ),
          ],
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
                  setState(() => _isLoading = true);
                  try {
                    final repo = ref.read(adminRepositoryProvider);
                    if (_selectedHouseId != null && _selectedHouseId != widget.resident.houseId) {
                      await repo.assignHouseToResident(widget.resident.id, _selectedHouseId!);
                    }
                    if (_status != widget.resident.status) {
                      await repo.updateResidentStatus(widget.resident.id, _status);
                    }
                    ref.invalidate(adminResidentsProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4318FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save Changes'),
        ),
      ],
    );
  }
}
