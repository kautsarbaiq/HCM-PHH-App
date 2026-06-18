import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/billing_repository.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/bill_card.dart';
import '../widgets/transaction_history_item.dart';

// State Management
final billingTabIndexProvider = StateProvider<int>((ref) => 0);

/// The current resident's bills, fetched live from Supabase (RLS scopes the
/// rows to the logged-in resident).
final myBillingsProvider =
    AsyncNotifierProvider<MyBillingsNotifier, List<Billing>>(() => MyBillingsNotifier());

class MyBillingsNotifier extends AsyncNotifier<List<Billing>> {
  @override
  Future<List<Billing>> build() async {
    return ref.read(billingRepositoryProvider).getMyBillings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(billingRepositoryProvider).getMyBillings());
  }
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

String _formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

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
              child: _buildHeader(context),
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
                  _buildActiveBills(context, ref).animate(target: tabIndex == 0 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildTransactionHistory(ref).animate(target: tabIndex == 1 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Billing',
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
              color: AppColors.primaryWhite,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(PhosphorIconsRegular.user, color: AppColors.primaryBlue),
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
          Expanded(child: _buildSegmentButton(ref, 0, 'Active Bills', currentIndex)),
          Expanded(child: _buildSegmentButton(ref, 1, 'History', currentIndex)),
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

  Widget _buildActiveBills(BuildContext context, WidgetRef ref) {
    final billingsAsync = ref.watch(myBillingsProvider);

    return billingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(error),
      data: (all) {
        final active = all.where((b) => b.status != 'paid').toList();
        if (active.isEmpty) {
          return _buildEmpty(PhosphorIconsRegular.checkCircle, 'All cleared!', 'You have no outstanding bills.');
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myBillingsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            itemCount: active.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final bill = active[index];
              return BillCard(
                title: bill.title,
                period: bill.period?.isNotEmpty == true ? bill.period! : 'Invoice ${bill.invoiceNumber}',
                amount: bill.amount,
                status: bill.status == 'overdue' ? 'Overdue' : 'Unpaid',
                dueDate: _formatDate(bill.dueDate),
                onPay: () {
                  // Real payment requires an external payment gateway (e.g. Stripe/
                  // local provider) + a server webhook to mark the bill paid.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Online payment for "${bill.title}" is not yet connected to a payment provider.'),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistory(WidgetRef ref) {
    final billingsAsync = ref.watch(myBillingsProvider);

    return billingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(error),
      data: (all) {
        final paid = all.where((b) => b.status == 'paid').toList();
        if (paid.isEmpty) {
          return _buildEmpty(PhosphorIconsRegular.receipt, 'No history yet', 'Your paid bills will appear here.');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          itemCount: paid.length,
          itemBuilder: (context, index) {
            final tx = paid[index];
            return TransactionHistoryItem(
              title: tx.title,
              date: _formatDateTime(tx.paidAt ?? tx.dueDate),
              amount: tx.amount,
              isSuccess: true,
            );
          },
        );
      },
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Could not load bills: $error', style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.success.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
