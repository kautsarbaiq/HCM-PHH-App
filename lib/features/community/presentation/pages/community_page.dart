import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/notice_card.dart';
import '../widgets/ticket_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hcm_app/features/dashboard/presentation/widgets/notice_slider.dart';
import '../../../../core/repositories/announcement_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/ticket_repository.dart';
import '../widgets/create_ticket_modal.dart';

/// Safely format an ISO date string; falls back to the raw value if the
/// string is empty or unparseable instead of throwing.
String _formatNoticeDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('MMM d, yyyy').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

/// Short ticket reference, guarded against ids shorter than 4 chars.
String _ticketRef(String id) {
  final slice = id.length >= 4 ? id.substring(0, 4) : id;
  return 'T-${slice.toUpperCase()}';
}

// State Management
final communityTabIndexProvider = StateProvider<int>((ref) => 0);

final noticesProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = ref.read(announcementRepositoryProvider);
  return repo.getAllAnnouncements();
});

final myTicketsProvider =
    AsyncNotifierProvider<MyTicketsNotifier, List<Ticket>>(
      () => MyTicketsNotifier(),
    );

class MyTicketsNotifier extends AsyncNotifier<List<Ticket>> {
  @override
  Future<List<Ticket>> build() async {
    final profile = await ref.watch(currentProfileProvider.future);
    if (profile == null) return [];

    final repo = ref.read(ticketRepositoryProvider);
    return repo.getMyTickets(profile.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(communityTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: _buildHeader(context, ref),
              ),
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      icon: PhosphorIconsRegular.calendarCheck,
                      label: 'Events',
                      route: '/events',
                      gradient: AppColors.sunsetGradient,
                    ),
                    const SizedBox(width: 10),
                    _buildFilterChip(
                      context,
                      icon: PhosphorIconsRegular.chartBar,
                      label: 'E-Polling',
                      route: '/epolling',
                      gradient: AppColors.skyGradient,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSegmentedControl(ref, tabIndex),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: IndexedStack(
                  index: tabIndex,
                  children: [
                    _buildNoticeBoard(ref)
                        .animate(target: tabIndex == 0 ? 1 : 0)
                        .fade(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    _buildFeedbackTickets(ref, context)
                        .animate(target: tabIndex == 1 ? 1 : 0)
                        .fade(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Community',
              style: TextStyle(
                fontSize: 28,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'News, events & your feedback',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.primaryWhite,
                child: profileAsync.when(
                  data: (profile) => profile?.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profile!.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            PhosphorIconsRegular.user,
                            color: AppColors.brand,
                          ),
                        )
                      : const Icon(
                          PhosphorIconsRegular.user,
                          color: AppColors.brand,
                        ),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const Icon(
                    PhosphorIconsRegular.user,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(WidgetRef ref, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A7BA8).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(ref, 0, 'Notice Board', currentIndex),
          ),
          Expanded(
            child: _buildSegmentButton(ref, 1, 'Feedback', currentIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    WidgetRef ref,
    int index,
    String label,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(communityTabIndexProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBoard(WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return noticesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => AppErrorState(
        message: 'Error: $err',
        onRetry: () => ref.invalidate(noticesProvider),
      ),
      data: (notices) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          children: [
            const NoticeSlider()
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const SectionHeader(title: 'All Announcements'),
            const SizedBox(height: 16),
            if (notices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: AppEmptyState(
                  icon: PhosphorIconsRegular.megaphone,
                  title: 'No announcements yet',
                  message: 'Community updates will appear here.',
                  gradient: AppColors.sunsetGradient,
                ),
              ),
            ...notices.map((notice) {
              final dateStr = _formatNoticeDate(notice.publishedAt);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NoticeCard(
                  title: notice.title,
                  description: notice.content,
                  date: dateStr,
                  isUrgent: notice.isUrgent,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackTickets(WidgetRef ref, BuildContext context) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ActionButton(
            label: 'Create New Ticket',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CreateTicketModal(),
              );
            },
            backgroundColor: AppColors.brand,
            height: 50,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ticketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => AppErrorState(
              message: 'Error: $err',
              onRetry: () => ref.read(myTicketsProvider.notifier).refresh(),
            ),
            data: (tickets) {
              if (tickets.isEmpty) {
                return const AppEmptyState(
                  icon: PhosphorIconsRegular.chatCircleText,
                  title: 'No tickets yet',
                  message:
                      'Raise a request or report an issue and track it here.',
                  gradient: AppColors.brandGradient,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                itemCount: tickets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final dateStr = _formatNoticeDate(ticket.createdAt);
                  return TicketCard(
                    ticketId: _ticketRef(ticket.id),
                    title: ticket.title,
                    date: dateStr,
                    status: ticket.status,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
        decoration: BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradientIconBadge(
              icon: icon,
              gradient: gradient,
              size: 32,
              iconSize: 16,
              radius: 10,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
