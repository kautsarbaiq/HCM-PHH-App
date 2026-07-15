import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../main/presentation/pages/main_navigation_page.dart' show hideBillsForTenant;

import '../../../../core/repositories/billing_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/bill_card.dart';
import '../widgets/transaction_history_item.dart';

// State Management
final billingTabIndexProvider = StateProvider<int>((ref) => 0);

/// The current resident's bills, fetched live from Supabase (RLS scopes the
/// rows to the logged-in resident). autoDispose: refetches fresh every time
/// the page is opened, so a bill created while this page was closed always
/// shows even if a realtime event was missed.
final myBillingsProvider =
    AsyncNotifierProvider.autoDispose<MyBillingsNotifier, List<Billing>>(
      () => MyBillingsNotifier(),
    );

class MyBillingsNotifier extends AutoDisposeAsyncNotifier<List<Billing>> {
  @override
  Future<List<Billing>> build() async {
    return ref.read(billingRepositoryProvider).getMyBillings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).getMyBillings(),
    );
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
    return DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(billingTabIndexProvider);

    // Point 17: a tenant who reaches /bills directly still sees no billing.
    if (hideBillsForTenant(ref)) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: GradientBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      PhosphorIconsRegular.receipt,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Billing is managed by the unit owner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'As a tenant you don\'t have access to bills and payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: SafeArea(
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
                    _buildActiveBills(context, ref)
                        .animate(target: tabIndex == 0 ? 1 : 0)
                        .fade(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    _buildTransactionHistory(ref)
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Billing',
              style: TextStyle(
                fontSize: 28,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Bills, dues & payment history',
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
          child: const GradientIconBadge(
            icon: PhosphorIconsRegular.user,
            gradient: AppColors.brandGradient,
            size: 44,
            iconSize: 22,
            radius: 14,
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
            child: _buildSegmentButton(ref, 0, 'Active Bills', currentIndex),
          ),
          Expanded(child: _buildSegmentButton(ref, 1, 'History', currentIndex)),
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
      onTap: () => ref.read(billingTabIndexProvider.notifier).state = index,
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

  Widget _buildActiveBills(BuildContext context, WidgetRef ref) {
    final billingsAsync = ref.watch(myBillingsProvider);

    return billingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(ref, error),
      data: (all) {
        final active = all.where((b) => b.status != 'paid').toList();
        if (active.isEmpty) {
          return _buildEmpty(
            PhosphorIconsRegular.checkCircle,
            'All cleared!',
            'You have no outstanding bills.',
            AppColors.mintGradient,
          );
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
                period: bill.period?.isNotEmpty == true
                    ? bill.period!
                    : 'Invoice ${bill.invoiceNumber}',
                amount: bill.amount,
                status: bill.status == 'overdue' ? 'Overdue' : 'Unpaid',
                dueDate: _formatDate(bill.dueDate),
                onPay: () {
                  // Real payment requires an external payment gateway (e.g. Stripe/
                  // local provider) + a server webhook to mark the bill paid.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Online payment for "${bill.title}" is not yet connected to a payment provider.',
                      ),
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
      error: (error, _) => _buildError(ref, error),
      data: (all) {
        final paid = all.where((b) => b.status == 'paid').toList();
        if (paid.isEmpty) {
          return _buildEmpty(
            PhosphorIconsRegular.receipt,
            'No history yet',
            'Your paid bills will appear here.',
            AppColors.skyGradient,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(myBillingsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            itemCount: paid.length,
            itemBuilder: (context, index) {
              final tx = paid[index];
              return TransactionHistoryItem(
                title: tx.title,
                date: _formatDateTime(tx.paidAt ?? tx.dueDate),
                amount: tx.amount,
                isSuccess: tx.status == 'paid',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildError(WidgetRef ref, Object error) {
    return AppErrorState(
      message: 'Could not load bills: $error',
      onRetry: () => ref.read(myBillingsProvider.notifier).refresh(),
    );
  }

  Widget _buildEmpty(
    IconData icon,
    String title,
    String subtitle,
    Gradient gradient,
  ) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: subtitle,
      gradient: gradient,
    );
  }
}
