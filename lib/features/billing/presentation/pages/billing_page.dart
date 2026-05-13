import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../widgets/bill_card.dart';
import '../widgets/transaction_history_item.dart';

// State Management
final billingTabIndexProvider = StateProvider<int>((ref) => 0);

final activeBillsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
      {
        'id': '1',
        'title': 'Monthly Maintenance Fee',
        'period': 'October 2026',
        'amount': 500000.0,
        'status': 'Unpaid',
        'dueDate': 'Oct 31, 2026',
      },
      {
        'id': '2',
        'title': 'Water Bill',
        'period': 'September 2026',
        'amount': 145000.0,
        'status': 'Unpaid',
        'dueDate': 'Oct 15, 2026',
      },
    ]);

final transactionHistoryProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
      {
        'id': 't1',
        'title': 'Monthly Maintenance Fee',
        'date': 'Sep 25, 2026 - 14:30',
        'amount': 500000.0,
        'isSuccess': true,
      },
      {
        'id': 't2',
        'title': 'Water Bill',
        'date': 'Aug 16, 2026 - 09:15',
        'amount': 132000.0,
        'isSuccess': true,
      },
      {
        'id': 't3',
        'title': 'Gym Access Fee',
        'date': 'Aug 05, 2026 - 11:00',
        'amount': 150000.0,
        'isSuccess': false,
      },
      {
        'id': 't4',
        'title': 'Monthly Maintenance Fee',
        'date': 'Aug 01, 2026 - 10:00',
        'amount': 500000.0,
        'isSuccess': true,
      },
    ]);

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(billingTabIndexProvider);

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
                  _buildActiveBills(ref).animate(target: tabIndex == 0 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildTransactionHistory(ref).animate(target: tabIndex == 1 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
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
          'Billing',
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
            child: _buildSegmentButton(ref, 0, 'Active Bills', currentIndex),
          ),
          Expanded(
            child: _buildSegmentButton(ref, 1, 'History', currentIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(WidgetRef ref, int index, String label, int currentIndex) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(billingTabIndexProvider.notifier).state = index,
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

  Widget _buildActiveBills(WidgetRef ref) {
    final bills = ref.watch(activeBillsProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return BillCard(
          title: bill['title'],
          period: bill['period'],
          amount: bill['amount'],
          status: bill['status'],
          dueDate: bill['dueDate'],
          onPay: () {
            // Mock payment action
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Processing payment for ${bill['title']}...'),
                backgroundColor: AppColors.sageGreen,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionHistory(WidgetRef ref) {
    final transactions = ref.watch(transactionHistoryProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return TransactionHistoryItem(
          title: tx['title'],
          date: tx['date'],
          amount: tx['amount'],
          isSuccess: tx['isSuccess'],
        );
      },
    );
  }
}
