import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/action_button.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/notice_card.dart';
import '../widgets/ticket_card.dart';
import 'package:hcm_app/features/dashboard/presentation/widgets/notice_slider.dart';
import '../../../../core/repositories/announcement_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/ticket_repository.dart';
import '../widgets/create_ticket_modal.dart';

// State Management
final communityTabIndexProvider = StateProvider<int>((ref) => 0);

final noticesProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = ref.read(announcementRepositoryProvider);
  return repo.getAllAnnouncements();
});

final myTicketsProvider = AsyncNotifierProvider<MyTicketsNotifier, List<Ticket>>(() => MyTicketsNotifier());

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: _buildHeader(context, ref),
            ),
            // Category Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(context, icon: PhosphorIconsRegular.calendarCheck, label: 'Events', route: '/events'),
                  const SizedBox(width: 10),
                  _buildFilterChip(context, icon: PhosphorIconsRegular.chartBar, label: 'E-Polling', route: '/epolling'),
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
                  _buildNoticeBoard(ref).animate(target: tabIndex == 0 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildFeedbackTickets(ref, context).animate(target: tabIndex == 1 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Community',
          style: TextStyle(
            fontSize: 28,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipOval(
              child: profileAsync.when(
                data: (profile) => profile?.avatarUrl != null 
                    ? Image.network(profile!.avatarUrl!, fit: BoxFit.cover)
                    : const Icon(PhosphorIconsRegular.user, color: AppColors.primaryBlue),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Icon(PhosphorIconsRegular.user, color: AppColors.primaryBlue),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(WidgetRef ref, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
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

  Widget _buildSegmentButton(WidgetRef ref, int index, String label, int currentIndex) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(communityTabIndexProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (notices) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          children: [
            const NoticeSlider().animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const Text(
              'All Announcements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (notices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No announcements yet.', style: TextStyle(color: AppColors.textSecondary))),
              ),
            ...notices.map((notice) {
              final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(notice.publishedAt).toLocal());
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
            backgroundColor: AppColors.primaryBlue,
            height: 48,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ticketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (tickets) {
              if (tickets.isEmpty) {
                return const Center(child: Text('No feedback tickets found.', style: TextStyle(color: AppColors.textSecondary)));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                itemCount: tickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(ticket.createdAt).toLocal());
                  return TicketCard(
                    ticketId: 'T-${ticket.id.substring(0, 4).toUpperCase()}',
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

  Widget _buildFilterChip(BuildContext context, {required IconData icon, required String label, required String route}) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryWhite.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            Icon(PhosphorIconsRegular.caretRight, size: 14, color: AppColors.textSecondary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
