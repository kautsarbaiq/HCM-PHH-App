import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../export/table_export.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';

/// One column of a report table.
class ReportColumn<T> {
  final String label;

  /// Cell text — also what search matches against and what gets exported.
  final String Function(T row) value;

  /// Optional custom cell; falls back to plain text from [value].
  final Widget Function(T row)? cell;

  /// Sort key; defaults to [value] (string compare).
  final Comparable Function(T row)? sortKey;
  final bool numeric;

  const ReportColumn({
    required this.label,
    required this.value,
    this.cell,
    this.sortKey,
    this.numeric = false,
  });
}

/// The standard list format for the whole web portal (boss voice note 18/08):
/// a table with search, column sorting, a start/end date filter and CSV + PDF
/// export. Every list screen uses this so all tabs look and behave the same.
class ReportTable<T> extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final List<ReportColumn<T>> columns;
  final List<T> rows;

  /// Extra filter controls (status chips…) shown beside the date range.
  final Widget? filters;

  /// When given, the toolbar grows a "From / To" date range filter that keeps
  /// only rows whose date falls inside the range.
  final DateTime? Function(T row)? dateOf;
  final String dateLabel;

  /// Optional per-row action (edit/open) rendered as a trailing column.
  final Widget Function(T row)? rowAction;

  final String exportBaseName;
  final String emptyMessage;

  const ReportTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.filters,
    this.dateOf,
    this.dateLabel = 'Date',
    this.rowAction,
    required this.exportBaseName,
    this.emptyMessage = 'Nothing to show.',
  });

  @override
  ConsumerState<ReportTable<T>> createState() => _ReportTableState<T>();
}

class _ReportTableState<T> extends ConsumerState<ReportTable<T>> {
  final _search = TextEditingController();
  int? _sortCol;
  bool _asc = true;
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<T> get _visible {
    final q = _search.text.trim().toLowerCase();
    var out = widget.rows.where((r) {
      // Date range first — cheapest filter.
      final dateOf = widget.dateOf;
      if (dateOf != null && (_from != null || _to != null)) {
        final d = dateOf(r);
        if (d == null) return false;
        final day = DateTime(d.year, d.month, d.day);
        if (_from != null && day.isBefore(_from!)) return false;
        if (_to != null && day.isAfter(_to!)) return false;
      }
      if (q.isEmpty) return true;
      // Search across every column so the admin doesn't have to pick a field.
      return widget.columns.any((c) => c.value(r).toLowerCase().contains(q));
    }).toList();

    final s = _sortCol;
    if (s != null && s < widget.columns.length) {
      final col = widget.columns[s];
      Comparable key(T r) => col.sortKey?.call(r) ?? col.value(r).toLowerCase();
      out.sort((a, b) =>
          _asc ? key(a).compareTo(key(b)) : key(b).compareTo(key(a)));
    }
    return out;
  }

  List<List<String>> _exportRows(List<T> rows) =>
      rows.map((r) => widget.columns.map((c) => c.value(r)).toList()).toList();

  Future<void> _export(bool asPdf) async {
    final rows = _visible;
    final headers = widget.columns.map((c) => c.label).toList();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (asPdf) {
        await TableExport.pdf(
          filename: widget.exportBaseName,
          title: widget.title,
          subtitle: widget.subtitle,
          headers: headers,
          rows: _exportRows(rows),
        );
      } else {
        await TableExport.csv(
          filename: widget.exportBaseName,
          headers: headers,
          rows: _exportRows(rows),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'Select date range',
    );
    if (picked == null) return;
    setState(() {
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  String get _rangeLabel {
    if (_from == null || _to == null) return 'All dates';
    final f = DateFormat('dd MMM yy');
    return '${f.format(_from!)} — ${f.format(_to!)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    final ms = ref.watch(localeProvider) == AppLang.ms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- toolbar -------------------------------------------------------
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '${ref.trs('Search')}…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3E9F4)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            ),
            if (widget.dateOf != null) ...[
              _ToolbarButton(
                icon: Icons.date_range_rounded,
                label: _rangeLabel,
                active: _from != null,
                onTap: _pickRange,
              ),
              if (_from != null)
                _ToolbarButton(
                  icon: Icons.close_rounded,
                  label: ms ? 'Kosongkan' : 'Clear',
                  onTap: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                ),
            ],
            if (widget.filters != null) widget.filters!,
            _ToolbarButton(
              icon: Icons.grid_on_rounded,
              label: 'CSV',
              onTap: rows.isEmpty ? null : () => _export(false),
            ),
            _ToolbarButton(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF',
              onTap: rows.isEmpty ? null : () => _export(true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ms
              ? '${rows.length} daripada ${widget.rows.length} rekod'
              : '${rows.length} of ${widget.rows.length} records',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // ---- table ---------------------------------------------------------
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        widget.emptyMessage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortColumnIndex: _sortCol,
                        sortAscending: _asc,
                        headingRowHeight: 46,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 58,
                        dividerThickness: 0.6,
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFFF4F7FC)),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                        columns: [
                          for (var i = 0; i < widget.columns.length; i++)
                            DataColumn(
                              label: Text(ref.trs(widget.columns[i].label)),
                              numeric: widget.columns[i].numeric,
                              onSort: (idx, asc) => setState(() {
                                _sortCol = idx;
                                _asc = asc;
                              }),
                            ),
                          if (widget.rowAction != null)
                            DataColumn(label: Text(ref.trs('Actions'))),
                        ],
                        rows: [
                          for (var i = 0; i < rows.length; i++)
                            DataRow(
                              // Zebra striping keeps long lists readable.
                              color: WidgetStateProperty.all(
                                i.isEven
                                    ? Colors.white
                                    : const Color(0xFFFAFCFF),
                              ),
                              cells: [
                                for (final c in widget.columns)
                                  DataCell(
                                    c.cell?.call(rows[i]) ??
                                        Text(
                                          c.value(rows[i]),
                                          style: const TextStyle(
                                            fontSize: 12.8,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                  ),
                                if (widget.rowAction != null)
                                  DataCell(widget.rowAction!(rows[i])),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Small pill button used across the report toolbar.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (active ? Colors.white : AppColors.brand);
    return Material(
      color: active ? AppColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.brand : const Color(0xFFE3E9F4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
