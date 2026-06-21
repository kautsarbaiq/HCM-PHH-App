import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/visitor_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/evidence_image.dart';
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
              child: EvidenceImage(
                storedUrl: photo.url,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(12),
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

  List<Visitor> _filter(List<Visitor> visitors) {
    if (_searchQuery.isEmpty) return visitors;
    final q = _searchQuery.toLowerCase();
    return visitors.where((v) {
      return v.visitorName.toLowerCase().contains(q) ||
          (v.house?.houseNumber.toLowerCase().contains(q) ?? false) ||
          (v.creator?.fullName.toLowerCase().contains(q) ?? false);
    }).toList();
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
                    // Single column on phones; two responsive columns on
                    // laptop/wide screens so the view isn't sparse. No
                    // horizontal scrolling at any width.
                    if (constraints.maxWidth < 700) {
                      return ListView.separated(
                        itemCount: visitors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _VisitorLogCard(visitor: visitors[index]),
                      );
                    }
                    const gap = 16.0;
                    final cardWidth = (constraints.maxWidth - gap) / 2;
                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: visitors
                            .map(
                              (v) => SizedBox(
                                width: cardWidth,
                                child: _VisitorLogCard(visitor: v),
                              ),
                            )
                            .toList(),
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

// Read-only rich log card mirroring the guard's visitor card style:
// name + status pill, labelled detail rows, then evidence photo thumbnails.
class _VisitorLogCard extends StatelessWidget {
  final Visitor visitor;

  const _VisitorLogCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(visitor.status);
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.badge_rounded,
                gradient: AppColors.brandGradient,
                size: 44,
                iconSize: 22,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  visitor.visitorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: status.label, color: status.color, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Type',
            value: _regTypeLabel(visitor.registrationType),
          ),
          _InfoRow(label: 'House', value: visitor.house?.houseNumber ?? '-'),
          _InfoRow(
            label: 'Logged by',
            value: _nameOrDash(visitor.creator?.fullName),
          ),
          _InfoRow(
            label: 'Plate',
            value: (visitor.vehiclePlate?.isNotEmpty == true)
                ? visitor.vehiclePlate!
                : '-',
          ),
          _InfoRow(label: 'Check-in', value: _formatTime(visitor.checkedInAt)),
          _InfoRow(
            label: 'Check-out',
            value: _formatTime(visitor.checkedOutAt),
          ),
          _PhotoThumbs(visitor: visitor),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Thumbnails of the evidence photos the guard captured at registration.
// Tapping any thumbnail opens the full-screen pinch-to-zoom viewer.
class _PhotoThumbs extends StatelessWidget {
  final Visitor visitor;

  const _PhotoThumbs({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final photos = _visitorPhotos(visitor);
    if (photos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'No photos captured',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: photos.map((p) => _Thumb(photo: p)).toList(),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final _AdminPhoto photo;

  const _Thumb({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPhotoViewer(context, photo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EvidenceImage(
            storedUrl: photo.url,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 5),
          Text(
            photo.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
