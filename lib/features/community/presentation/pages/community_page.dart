import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/action_button.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/notice_card.dart';
import '../widgets/ticket_card.dart';

// State Management
final communityTabIndexProvider = StateProvider<int>((ref) => 0);

final noticesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
      {
        'id': 'n1',
        'title': 'Scheduled Water Maintenance',
        'description': 'Water supply will be temporarily shut off tomorrow from 10:00 AM to 2:00 PM for scheduled pump maintenance.',
        'date': 'Oct 24, 2026',
        'isUrgent': true,
      },
      {
        'id': 'n2',
        'title': 'Community Townhall Meeting',
        'description': 'Join us this Saturday at the Multipurpose Hall to discuss the new parking regulations and security upgrades.',
        'date': 'Oct 20, 2026',
        'isUrgent': false,
      },
      {
        'id': 'n3',
        'title': 'Pest Control Schedule',
        'description': 'Quarterly fogging will be conducted around the perimeter and basement areas this Friday.',
        'date': 'Oct 18, 2026',
        'isUrgent': false,
      },
    ]);

final ticketsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
      {
        'id': 'T-8091',
        'title': 'Broken lightbulb in Hallway B',
        'date': 'Oct 22, 2026',
        'status': 'Pending',
      },
      {
        'id': 'T-8042',
        'title': 'Air Conditioner leakage in Gym',
        'date': 'Oct 15, 2026',
        'status': 'Resolved',
      },
    ]);

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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: _buildHeader(),
            ),
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

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Community',
          style: TextStyle(
            fontSize: 28,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
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
    final notices = ref.watch(noticesProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: notices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notice = notices[index];
        return NoticeCard(
          title: notice['title'],
          description: notice['description'],
          date: notice['date'],
          isUrgent: notice['isUrgent'],
        );
      },
    );
  }

  Widget _buildFeedbackTickets(WidgetRef ref, BuildContext context) {
    final tickets = ref.watch(ticketsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ActionButton(
            label: 'Create New Ticket',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Opening ticket creation form...'),
                  backgroundColor: AppColors.sageGreen,
                ),
              );
            },
            backgroundColor: AppColors.deepSlate,
            height: 48,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                ticketId: ticket['id'],
                title: ticket['title'],
                date: ticket['date'],
                status: ticket['status'],
              );
            },
          ),
        ),
      ],
    );
  }
}
