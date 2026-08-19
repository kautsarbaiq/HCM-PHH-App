import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import 'premium_card.dart';
import 'report_table.dart';
import 'responsive.dart';
import 'section_header.dart';

/// The one standard shape every list screen in the web portal uses
/// (boss voice note 18/08: "make one standard format and keep all of them in
/// that standard format").
///
/// Table mode gives search, column sorting, a start/end date filter and CSV +
/// PDF export. Screens that already had a card layout keep it — the boss asked
/// to keep the cards and *add* the table — via the Cards / Table switch.
class StandardList<T> extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;

  /// Right-hand action, e.g. an "Add" button.
  final Widget? headerAction;

  final List<T> rows;
  final List<ReportColumn<T>> columns;
  final DateTime? Function(T row)? dateOf;
  final Widget Function(T row)? rowAction;
  final String exportBaseName;
  final String emptyMessage;

  /// Optional existing card/list layout. When null the screen is table-only.
  final Widget Function(BuildContext context)? cardView;

  /// Start on cards (true) or on the table (false).
  final bool cardsFirst;

  const StandardList({
    super.key,
    required this.title,
    this.subtitle,
    this.headerAction,
    required this.rows,
    required this.columns,
    this.dateOf,
    this.rowAction,
    required this.exportBaseName,
    this.emptyMessage = 'Nothing to show.',
    this.cardView,
    this.cardsFirst = true,
  });

  @override
  ConsumerState<StandardList<T>> createState() => _StandardListState<T>();
}

class _StandardListState<T> extends ConsumerState<StandardList<T>> {
  late bool _cards = widget.cardView != null && widget.cardsFirst;

  @override
  Widget build(BuildContext context) {
    final hasCards = widget.cardView != null;

    return PremiumCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeaderRow(
            header: SectionHeader(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            actions: [
              if (hasCards)
                _ViewSwitch(
                  cards: _cards,
                  onChanged: (v) => setState(() => _cards = v),
                ),
              if (widget.headerAction != null) widget.headerAction!,
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cards && hasCards
                ? widget.cardView!(context)
                : ReportTable<T>(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    rows: widget.rows,
                    columns: widget.columns,
                    dateOf: widget.dateOf,
                    rowAction: widget.rowAction,
                    exportBaseName: widget.exportBaseName,
                    emptyMessage: widget.emptyMessage,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Segmented Cards / Table switch.
class _ViewSwitch extends ConsumerWidget {
  final bool cards;
  final ValueChanged<bool> onChanged;
  const _ViewSwitch({required this.cards, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(localeProvider) == AppLang.ms;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E9F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(Icons.grid_view_rounded, ms ? 'Kad' : 'Cards', cards,
              () => onChanged(true)),
          _seg(Icons.table_rows_rounded, ms ? 'Jadual' : 'Table', !cards,
              () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF6A7BA8).withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? AppColors.brand : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.brand : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
