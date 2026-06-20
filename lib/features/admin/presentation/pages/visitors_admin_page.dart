import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/visitor_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminVisitorsProvider =
    AsyncNotifierProvider<AdminVisitorsNotifier, List<Visitor>>(
      () => AdminVisitorsNotifier(),
    );

class AdminVisitorsNotifier extends AsyncNotifier<List<Visitor>> {
  @override
  Future<List<Visitor>> build() async {
    final repo = ref.read(visitorRepositoryProvider);
    return repo.getAllVisitors();
  }

  Future<void> updateStatus(String id, String status) async {
    final repo = ref.read(visitorRepositoryProvider);
    await repo.updateVisitorStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> deleteVisitor(String id) async {
    final repo = ref.read(visitorRepositoryProvider);
    await repo.deleteVisitor(id);
    ref.invalidateSelf();
  }
}

({String label, Color color}) _statusStyle(String status) {
  switch (status) {
    case 'checked_in':
      return (label: 'Checked In', color: AppColors.success);
    case 'checked_out':
      return (label: 'Checked Out', color: AppColors.textSecondary);
    case 'cancelled':
      return (label: 'Cancelled', color: AppColors.error);
    case 'expected':
    default:
      return (label: 'Expected', color: AppColors.warning);
  }
}

String _formatTime(String? iso) {
  if (iso == null) return '-';
  try {
    return DateFormat('MMM dd, HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

String _nameOrDash(String? name) =>
    (name != null && name.isNotEmpty) ? name : '-';

String _regTypeLabel(String t) {
  switch (t) {
    case 'walk-in':
      return 'Manual (Walk-in)';
    case 'pre-registered':
      return 'QR / Pre-registered';
    default:
      return t;
  }
}

class _AdminPhoto {
  final String label;
  final String url;
  const _AdminPhoto(this.label, this.url);
}

List<_AdminPhoto> _visitorPhotos(Visitor v) => [
  if ((v.visitorPhotoUrl ?? '').isNotEmpty)
    _AdminPhoto('Face', v.visitorPhotoUrl!),
  if ((v.vehiclePhotoUrl ?? '').isNotEmpty)
    _AdminPhoto('Vehicle', v.vehiclePhotoUrl!),
  if ((v.licensePhotoUrl ?? '').isNotEmpty)
    _AdminPhoto('ID', v.licensePhotoUrl!),
];

// Full-screen pinch-to-zoom viewer for a captured evidence photo.
void _showPhotoViewer(BuildContext context, _AdminPhoto photo) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Text(
              photo.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class VisitorsAdminPage extends ConsumerStatefulWidget {
  const VisitorsAdminPage({super.key});

  @override
  ConsumerState<VisitorsAdminPage> createState() => _VisitorsAdminPageState();
}

class _VisitorsAdminPageState extends ConsumerState<VisitorsAdminPage> {
  String _searchQuery = '';

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  List<Visitor> _filter(List<Visitor> visitors) {
    if (_searchQuery.isEmpty) return visitors;
    final q = _searchQuery.toLowerCase();
    return visitors.where((v) {
      return v.visitorName.toLowerCase().contains(q) ||
          (v.house?.houseNumber.toLowerCase().contains(q) ?? false) ||
          (v.creator?.fullName.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _showDetails(Visitor visitor) {
    final status = _statusStyle(visitor.status);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.badge, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visitor.visitorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Purpose', visitor.purpose),
                _buildDetailItem(
                  'Vehicle Plate',
                  visitor.vehiclePlate?.isNotEmpty == true
                      ? visitor.vehiclePlate!
                      : '-',
                ),
                _buildDetailItem('House', visitor.house?.houseNumber ?? '-'),
                _buildDetailItem(
                  'Registration',
                  _regTypeLabel(visitor.registrationType),
                ),
                _buildDetailItem(
                  'Logged By',
                  _nameOrDash(visitor.creator?.fullName),
                ),
                _buildDetailItem(
                  'Expected At',
                  _formatTime(visitor.expectedAt),
                ),
                _buildDetailItem(
                  'Checked In',
                  _formatTime(visitor.checkedInAt),
                ),
                _buildDetailItem(
                  'Checked Out',
                  _formatTime(visitor.checkedOutAt),
                ),
                _buildDetailItem(
                  'Status',
                  status.label,
                  statusColor: status.color,
                ),
                _buildPhotosSection(visitor),
              ],
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

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
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
          if (statusColor != null)
            StatusPill(label: value, color: statusColor)
          else
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  // Evidence photos captured by the guard at registration. Tap to enlarge.
  Widget _buildPhotosSection(Visitor v) {
    final photos = _visitorPhotos(v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (photos.isEmpty)
            const Text(
              'No photos captured',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            )
          else
            Row(
              children: photos
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showPhotoViewer(context, p),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: p.url,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.surfaceTint,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (c, u, e) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.surfaceTint,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // Compact card used for the narrow-phone visitors layout.
  Widget _buildVisitorCard(Visitor v) {
    final status = _statusStyle(v.status);
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if ((v.visitorPhotoUrl ?? '').isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showPhotoViewer(
                    context,
                    _AdminPhoto('Face', v.visitorPhotoUrl!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: v.visitorPhotoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 44,
                        height: 44,
                        color: AppColors.surfaceTint,
                        child: const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: AppColors.surfaceTint,
                        child: const Icon(
                          Icons.person,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const GradientIconBadge(
                  icon: Icons.badge_rounded,
                  gradient: AppColors.brandGradient,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  v.visitorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: status.label, color: status.color, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Type: ${_regTypeLabel(v.registrationType)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            'House: ${v.house?.houseNumber ?? '-'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            'Logged by: ${_nameOrDash(v.creator?.fullName)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            'Time: ${_formatTime(v.checkedInAt ?? v.expectedAt)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
                tooltip: 'Update Status',
                onSelected: (value) => _updateStatus(v, value),
                itemBuilder: (_) => _statusMenuItems(v),
              ),
              IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: AppColors.brand,
                  size: 20,
                ),
                onPressed: () => _showDetails(v),
                tooltip: 'View Details',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _deleteVisitor(v),
                tooltip: 'Delete Visitor',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(Visitor visitor, String status) async {
    try {
      await ref
          .read(adminVisitorsProvider.notifier)
          .updateStatus(visitor.id, status);
    } catch (e) {
      _showError(e);
    }
  }

  // Builds the status-change actions available for a visitor's current state.
  List<PopupMenuEntry<String>> _statusMenuItems(Visitor visitor) {
    final items = <PopupMenuEntry<String>>[];
    if (visitor.status == 'expected') {
      items.add(
        const PopupMenuItem(value: 'checked_in', child: Text('Check In')),
      );
      items.add(const PopupMenuItem(value: 'cancelled', child: Text('Cancel')));
    } else if (visitor.status == 'checked_in') {
      items.add(
        const PopupMenuItem(value: 'checked_out', child: Text('Check Out')),
      );
    } else {
      // checked_out / cancelled: allow re-opening as expected.
      items.add(
        const PopupMenuItem(value: 'expected', child: Text('Mark as Expected')),
      );
    }
    return items;
  }

  void _deleteVisitor(Visitor visitor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Visitor Log',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete visitor ${visitor.visitorName}? This action cannot be undone.',
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
                      .read(adminVisitorsProvider.notifier)
                      .deleteVisitor(visitor.id);
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
    final visitorsAsync = ref.watch(adminVisitorsProvider);

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
                  title: 'Visitors Log',
                  subtitle: 'Track check-ins, evidence photos and status',
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(adminVisitorsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by visitor, house, or who logged it...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
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
          const SizedBox(height: 16),
          Expanded(
            child: visitorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminVisitorsProvider),
              ),
              data: (allVisitors) {
                final visitors = _filter(allVisitors);
                if (visitors.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.badge_rounded,
                    title: 'No visitors logged',
                    message: _searchQuery.isEmpty
                        ? 'Visitor check-ins logged by guards will appear here.'
                        : 'No visitors match your search.',
                    gradient: AppColors.skyGradient,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // On narrow phones, render a vertical card list instead of a wide table.
                    if (constraints.maxWidth < 600) {
                      return ListView.separated(
                        itemCount: visitors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildVisitorCard(visitors[index]),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.surfaceTint,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: constraints.maxWidth > 760
                                ? constraints.maxWidth
                                : 760.0,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  color: AppColors.surfaceTint,
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Visitor Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'House',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Logged By',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Time',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Actions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: visitors.length,
                                    itemBuilder: (context, index) {
                                      final v = visitors[index];
                                      final status = _statusStyle(v.status);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFE0E5F2),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                v.visitorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                v.house?.houseNumber ?? '-',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.surfaceTint,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _nameOrDash(
                                                      v.creator?.fullName,
                                                    ),
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatTime(
                                                  v.checkedInAt ?? v.expectedAt,
                                                ),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: StatusPill(
                                                  label: status.label,
                                                  color: status.color,
                                                  dense: true,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(
                                                      Icons.fact_check_outlined,
                                                      color: AppColors.success,
                                                      size: 18,
                                                    ),
                                                    tooltip: 'Update Status',
                                                    onSelected: (value) =>
                                                        _updateStatus(v, value),
                                                    itemBuilder: (_) =>
                                                        _statusMenuItems(v),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.visibility,
                                                      color: AppColors.brand,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _showDetails(v),
                                                    tooltip: 'View Details',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: AppColors.error,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteVisitor(v),
                                                    tooltip: 'Delete Visitor',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
}
