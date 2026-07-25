import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../theme/app_colors.dart';
import '../data/wms_store.dart';
import '../models/purchase_order.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/primary_button.dart';

/// Boss flow 20/07 step 4: after goods are received, the system generates one
/// QR label PER UNIT ("one type of sheet, ten quantity → ten QR codes"), which
/// the warehouse guy prints and sticks on each piece before put-away.
///
/// Each label encodes the item's barcode (so the existing Placement/Picking
/// scan endpoints match it) and is captioned `PO#-SKU-sequence` so every
/// physical piece is individually identifiable.
class QrLabelsPage extends ConsumerWidget {
  final String poId;
  const QrLabelsPage({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(wmsStoreProvider);
    final order = store.orderById(poId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Labels'),
        actions: [
          if (order != null && order.totalReceived > 0)
            IconButton(
              tooltip: 'Print / save PDF',
              icon: const Icon(Icons.print_rounded),
              onPressed: () => _printPdf(order),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: order == null
              ? const AppEmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Order not found',
                  message: 'Go back and open the order again.',
                )
              : order.totalReceived == 0
                  ? const AppEmptyState(
                      icon: Icons.qr_code_2_rounded,
                      title: 'Nothing received yet',
                      message:
                          'Receive items first — labels are generated for '
                          'every received unit.',
                    )
                  : _labelList(context, order),
        ),
      ),
    );
  }

  /// One label per received unit, grouped per line item.
  List<_Label> _labels(PurchaseOrder order) => [
        for (final item in order.items)
          for (var seq = 1; seq <= item.receivedQty; seq++)
            _Label(
              caption: '${order.poNumber}-${item.sku}-$seq',
              payload: item.barcode,
              name: item.name,
              seq: seq,
              total: item.receivedQty,
            ),
      ];

  Widget _labelList(BuildContext context, PurchaseOrder order) {
    final labels = _labels(order);
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: labels.length,
            itemBuilder: (context, i) {
              final l = labels[i];
              return GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: l.payload,
                          version: QrVersions.auto,
                          foregroundColor: AppColors.deepSlate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${l.name} • ${l.seq}/${l.total}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: PrimaryButton(
            label: 'Print / save PDF (${labels.length} labels)',
            icon: Icons.print_rounded,
            onPressed: () => _printPdf(order),
          ),
        ),
      ],
    );
  }

  /// A5 sheet, 2×4 labels per page — opens the OS print dialog, which also
  /// offers "Save as PDF" (the boss asked for both print and download).
  Future<void> _printPdf(PurchaseOrder order) async {
    final labels = _labels(order);
    final doc = pw.Document();
    const perPage = 8;
    for (var start = 0; start < labels.length; start += perPage) {
      final page = labels.skip(start).take(perPage).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) => pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 1.05,
            children: [
              for (final l in page)
                pw.Container(
                  margin: const pw.EdgeInsets.all(4),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: l.payload,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        l.caption,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${l.name} (${l.seq}/${l.total})',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    await Printing.layoutPdf(
      name: 'labels-${order.poNumber}.pdf',
      onLayout: (_) => doc.save(),
    );
  }
}

class _Label {
  final String caption;
  final String payload;
  final String name;
  final int seq;
  final int total;
  _Label({
    required this.caption,
    required this.payload,
    required this.name,
    required this.seq,
    required this.total,
  });
}
