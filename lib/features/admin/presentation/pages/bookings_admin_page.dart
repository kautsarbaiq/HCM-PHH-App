import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/facility_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminBookingsProvider =
    AsyncNotifierProvider<AdminBookingsNotifier, List<Booking>>(
      () => AdminBookingsNotifier(),
    );

class AdminBookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final repo = ref.read(facilityRepositoryProvider);
    return repo.getAllBookings();
  }

  Future<void> updateBookingStatus(String id, String status) async {
    final repo = ref.read(facilityRepositoryProvider);
    await repo.updateBookingStatus(id, status);
    ref.invalidateSelf();
  }
}

class BookingsAdminPage extends ConsumerStatefulWidget {
  const BookingsAdminPage({super.key});

  @override
  ConsumerState<BookingsAdminPage> createState() => _BookingsAdminPageState();
}

class _BookingsAdminPageState extends ConsumerState<BookingsAdminPage> {
  static const List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Cancelled',
  ];
  String _selectedFilter = 'All';

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.accentAmber;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  /// Booking currently being updated (its buttons show a spinner meanwhile).
  String? _updatingId;

  Future<void> _setStatus(Booking booking, String status) async {
    if (_updatingId != null) return;
    setState(() => _updatingId = booking.id);
    try {
      await ref
          .read(adminBookingsProvider.notifier)
          .updateBookingStatus(booking.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Confirmed'
                ? '"${booking.facilityName}" booking confirmed ✓'
                : '"${booking.facilityName}" booking rejected',
          ),
          backgroundColor: status == 'Confirmed'
              ? AppColors.success
              : AppColors.error,
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(adminBookingsProvider);

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
                  title: 'Bookings',
                  subtitle: 'Review and manage facility reservations',
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.brand),
                onPressed: () => ref.invalidate(adminBookingsProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _filters.map((filter) {
              final selected = _selectedFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: selected,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                selectedColor: AppColors.brand,
                backgroundColor: AppColors.surfaceTint,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminBookingsProvider),
              ),
              data: (bookings) {
                final filtered = _selectedFilter == 'All'
                    ? bookings
                    : bookings
                          .where(
                            (b) =>
                                b.status.toLowerCase() ==
                                _selectedFilter.toLowerCase(),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.event_available_rounded,
                    title: _selectedFilter == 'All'
                        ? 'No bookings yet'
                        : 'No $_selectedFilter bookings',
                    message:
                        'Facility reservations from residents will appear here.',
                    gradient: AppColors.skyGradient,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminBookingsProvider),
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      final color = _statusColor(b.status);
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const GradientIconBadge(
                            icon: Icons.event_available_rounded,
                            gradient: AppColors.brandGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  b.facilityName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: b.status.toUpperCase(),
                                color: color,
                                dense: true,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(b.date),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  b.time,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: _updatingId == b.id
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (b.status.toLowerCase() != 'confirmed')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.success,
                                        ),
                                        onPressed: () =>
                                            _setStatus(b, 'Confirmed'),
                                        tooltip: 'Approve Booking',
                                      ),
                                    if (b.status.toLowerCase() != 'cancelled')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            _setStatus(b, 'Cancelled'),
                                        tooltip: 'Reject Booking',
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
