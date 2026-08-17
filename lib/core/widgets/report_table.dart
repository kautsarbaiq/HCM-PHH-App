import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// A searchable, sortable table with CSV + PDF export — the shared basis for
/// the billing, alert and general reports (boss batch 08/08 points 4, 10, 13).
class ReportTable<T> extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final List<ReportColumn<T>> columns;
  final List<T> rows;
  /// Extra filter controls (status chips, date pickers…) shown above the table.
  final Widget? filters;
  final String exportBaseName;
  final String emptyMessage;

  const ReportTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.filters,
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<T> get _visible {
    final q = _search.text.trim().toLowerCase();
    var out = widget.rows.where((r) {
      if (q.isEmpty) return true;
      // Search across every column so the admin doesn't have to pick a field.
      return widget.columns
          .any((c) => c.value(r).toLowerCase().contains(q));
    }).toList();

    final s = _sortCol;
    if (s != null && s < widget.columns.length) {
      final col = widget.columns[s];
      Comparable key(T r) => col.sortKey?.call(r) ?? col.value(r).toLowerCase();
      out.sort((a, b) => _asc
          ? key(a).compareTo(key(b))
          : key(b).compareTo(key(a)));
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
        SnackBar(content: Text('Export failed: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '${ref.trs('Search')}…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _search.clear()),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: rows.isEmpty ? null : () => _export(false),
              icon: const Icon(Icons.table_view_rounded, size: 18),
              label: const Text('CSV'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: rows.isEmpty ? null : () => _export(true),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('PDF'),
            ),
          ],
        ),
        if (widget.filters != null) ...[
          const SizedBox(height: 12),
          widget.filters!,
        ],
        const SizedBox(height: 10),
        Text(
          ref.watch(localeProvider) == AppLang.ms
              ? '${rows.length} daripada ${widget.rows.length} rekod'
              : '${rows.length} of ${widget.rows.length} records',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(widget.emptyMessage,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                )
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: _sortCol,
                      sortAscending: _asc,
                      headingRowColor: WidgetStateProperty.all(
                          AppColors.surfaceTint),
                      columns: [
                        for (var i = 0; i < widget.columns.length; i++)
                          DataColumn(
                            label: Text(
                              ref.trs(widget.columns[i].label),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5),
                            ),
                            numeric: widget.columns[i].numeric,
                            onSort: (idx, asc) => setState(() {
                              _sortCol = idx;
                              _asc = asc;
                            }),
                          ),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(
                            cells: [
                              for (final c in widget.columns)
                                DataCell(
                                  c.cell?.call(r) ??
                                      Text(
                                        c.value(r),
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
