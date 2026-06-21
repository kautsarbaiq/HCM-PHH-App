import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/visitor_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/evidence_image.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

final guardVisitorsProvider =
    AsyncNotifierProvider<GuardVisitorsNotifier, List<Visitor>>(
      () => GuardVisitorsNotifier(),
    );

class GuardVisitorsNotifier extends AsyncNotifier<List<Visitor>> {
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
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'expected':
      return AppColors.warning;
    case 'checked_in':
      return AppColors.success;
    case 'checked_out':
      return AppColors.textSecondary;
    default:
      return AppColors.info;
  }
}

String _fmtDateTime(String? raw) {
  if (raw == null) return '-';
  return DateFormat('MMM d, yyyy HH:mm').format(DateTime.parse(raw).toLocal());
}

String _checkInDisplay(Visitor v) {
  if (v.checkedInAt != null) return _fmtDateTime(v.checkedInAt);
  if (v.expectedAt != null) return 'Expected ${_fmtDateTime(v.expectedAt)}';
  return '-';
}

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

class GuardVisitorsPage extends ConsumerWidget {
  const GuardVisitorsPage({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(guardVisitorsProvider.notifier).updateStatus(id, status);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update visitor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitorsAsync = ref.watch(guardVisitorsProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.canvasGradient),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: PhosphorIconsFill.users,
                gradient: AppColors.brandGradient,
                size: 50,
                iconSize: 25,
                radius: 16,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visitor Logs',
                      style: TextStyle(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Today's active and completed registrations",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Quick actions in the header: QR check-in scan + manual walk-in.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/guard/scan'),
                  icon: const Icon(PhosphorIconsRegular.qrCode, size: 18),
                  label: const Text(
                    'Scan QR',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    backgroundColor: AppColors.primaryWhite,
                    side: const BorderSide(color: AppColors.brand, width: 1.4),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentMint.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/guard/register'),
                    icon: const Icon(PhosphorIconsFill.userPlus, size: 18),
                    label: const Text(
                      'Register',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryWhite,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A7BA8).withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: visitorsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => AppErrorState(
                    message: 'Error: $error',
                    onRetry: () => ref.invalidate(guardVisitorsProvider),
                  ),
                  data: (visitors) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(guardVisitorsProvider),
                      child: visitors.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 60.h),
                                const AppEmptyState(
                                  icon: PhosphorIconsRegular.users,
                                  title: 'No visitors yet',
                                  message:
                                      'Registered and pre-booked visitors will show up here.',
                                ),
                              ],
                            )
                          // Always a vertical card list (never a horizontal-scrolling
                          // table) so every detail — including the evidence photos —
                          // is visible at any width.
                          : _VisitorCardList(
                              visitors: visitors,
                              onUpdate: _updateStatus,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StatusUpdater =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      String id,
      String status,
    );

class _VisitorCardList extends StatelessWidget {
  final List<Visitor> visitors;
  final _StatusUpdater onUpdate;

  const _VisitorCardList({required this.visitors, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    // Centered + width-capped so the single-column card list stays readable on
    // wide tablet/desktop screens instead of stretching edge to edge.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
          itemCount: visitors.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final visitor = visitors[index];
            final statusColor = _statusColor(visitor.status);
            return PremiumCard(
              padding: EdgeInsets.all(16.w),
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const GradientIconBadge(
                        icon: PhosphorIconsFill.user,
                        gradient: AppColors.brandGradient,
                        size: 44,
                        iconSize: 22,
                        radius: 14,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          visitor.visitorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 15.sp,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: visitor.status.toUpperCase().replaceAll(
                          '_',
                          ' ',
                        ),
                        color: statusColor,
                        dense: true,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _CardInfoRow(label: 'Purpose', value: visitor.purpose),
                  _CardInfoRow(
                    label: 'Type',
                    value: _regTypeLabel(visitor.registrationType),
                  ),
                  _CardInfoRow(
                    label: 'House No.',
                    value: visitor.house?.houseNumber ?? '-',
                  ),
                  _CardInfoRow(
                    label: 'Plate',
                    value: visitor.vehiclePlate ?? '-',
                  ),
                  _CardInfoRow(
                    label: 'Check-in',
                    value: _checkInDisplay(visitor),
                  ),
                  _CardInfoRow(
                    label: 'Check-out',
                    value: _fmtDateTime(visitor.checkedOutAt),
                  ),
                  _PhotoThumbs(visitor: visitor),
                  if (visitor.status == 'expected' ||
                      visitor.status == 'checked_in') ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _VisitorActions(
                        visitor: visitor,
                        onUpdate: onUpdate,
                        showLabels: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72.w,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful so we can disable the button and show a spinner while the
// network call is in flight.
class _VisitorActions extends ConsumerStatefulWidget {
  final Visitor visitor;
  final _StatusUpdater onUpdate;
  final bool showLabels;

  const _VisitorActions({
    required this.visitor,
    required this.onUpdate,
    this.showLabels = false,
  });

  @override
  ConsumerState<_VisitorActions> createState() => _VisitorActionsState();
}

class _VisitorActionsState extends ConsumerState<_VisitorActions> {
  bool _busy = false;

  Future<void> _run(String status) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onUpdate(context, ref, widget.visitor.id, status);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final status = widget.visitor.status;
    if (status == 'expected') {
      return widget.showLabels
          ? _gradientActionButton(
              gradient: AppColors.mintGradient,
              glow: AppColors.accentMint,
              icon: PhosphorIconsBold.signIn,
              label: 'Check In',
              onPressed: () => _run('checked_in'),
            )
          : IconButton(
              icon: const Icon(
                PhosphorIconsBold.signIn,
                color: AppColors.success,
              ),
              onPressed: () => _run('checked_in'),
              tooltip: 'Check In',
            );
    }
    if (status == 'checked_in') {
      return widget.showLabels
          ? _gradientActionButton(
              gradient: AppColors.sunsetGradient,
              glow: AppColors.accentAmber,
              icon: PhosphorIconsBold.signOut,
              label: 'Check Out',
              onPressed: () => _run('checked_out'),
            )
          : IconButton(
              icon: const Icon(
                PhosphorIconsBold.signOut,
                color: AppColors.warning,
              ),
              onPressed: () => _run('checked_out'),
              tooltip: 'Check Out',
            );
    }
    return const SizedBox.shrink();
  }

  Widget _gradientActionButton({
    required Gradient gradient,
    required Color glow,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

class _LabeledPhoto {
  final String label;
  final String url;
  const _LabeledPhoto(this.label, this.url);
}

// Thumbnails of the evidence photos a guard captured at registration.
// Tapping any thumbnail opens a full-screen, pinch-to-zoom viewer.
class _PhotoThumbs extends StatelessWidget {
  final Visitor visitor;

  const _PhotoThumbs({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final photos = <_LabeledPhoto>[
      if ((visitor.visitorPhotoUrl ?? '').isNotEmpty)
        _LabeledPhoto('Face', visitor.visitorPhotoUrl!),
      if ((visitor.vehiclePhotoUrl ?? '').isNotEmpty)
        _LabeledPhoto('Vehicle', visitor.vehiclePhotoUrl!),
      if ((visitor.licensePhotoUrl ?? '').isNotEmpty)
        _LabeledPhoto('ID', visitor.licensePhotoUrl!),
    ];
    if (photos.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.imageBroken,
              size: 14.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              'No photos captured',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: photos
            .map(
              (p) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _Thumb(photo: p, size: 64.w),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final _LabeledPhoto photo;
  final double size;

  const _Thumb({required this.photo, required this.size});

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
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          SizedBox(height: 5.h),
          Text(
            photo.label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void _showPhotoViewer(BuildContext context, _LabeledPhoto photo) {
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
