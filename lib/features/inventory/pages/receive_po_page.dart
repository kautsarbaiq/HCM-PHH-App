import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/wms_store.dart';
import '../models/purchase_order.dart';
import '../widgets/scanner_page.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Receiving · PO detail. Scan each material's barcode to confirm receipt.
class ReceivePoPage extends ConsumerStatefulWidget {
  final String poId;
  const ReceivePoPage({super.key, required this.poId});

  @override
  ConsumerState<ReceivePoPage> createState() => _ReceivePoPageState();
}

class _ReceivePoPageState extends ConsumerState<ReceivePoPage> {
  bool _busy = false;

  Future<void> _scanToReceive(PurchaseOrder order) async {
    final code = await ScannerPage.open(
      context,
      title: 'Scan Goods Tag',
      subtitle: 'Scan the material barcode to confirm receiving',
    );
    if (code == null || !mounted) return;
    setState(() => _busy = true);
    final result =
        await ref.read(wmsStoreProvider).receiveByBarcode(order.id, code);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(result.message, ok: result.ok);
  }

  void _toast(String message, {required bool ok}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(wmsStoreProvider);
    final order = store.orderById(widget.poId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receive Purchase Order')),
        body: const AppEmptyState(
          icon: Icons.error_outline,
          title: 'Purchase order not found',
        ),
      );
    }

    final done = order.status == ReceiveStatus.received;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.poNumber),
        actions: [
          // Boss flow step 4: per-unit QR labels for everything received on
          // this PO — print them and stick one on each piece.
          if (order.totalReceived > 0)
            IconButton(
              tooltip: 'QR labels',
              icon: const Icon(Icons.qr_code_2_rounded),
              onPressed: () =>
                  context.push('/inventory/receiving/${order.id}/labels'),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _HeaderCard(order: order),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Materials to receive',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ItemCard(
                            item: item,
                            onReceiveAll: () => ref
                                .read(wmsStoreProvider)
                                .receiveLineFully(order.id, item.id),
                          ),
                        )),
                  ],
                ),
              ),
              // Sticky scan CTA
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  label: done ? 'Fully received' : 'Scan Goods Tag',
                  icon: done ? Icons.check_circle : Icons.qr_code_scanner,
                  loading: _busy,
                  gradient:
                      done ? AppColors.mintGradient : AppColors.brandGradient,
                  onPressed: done ? null : () => _scanToReceive(order),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseOrder order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.supplier,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.lineCount} line items',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: order.status.label, color: order.status.color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ProgressBar(value: order.progress, color: order.status.color)),
              const SizedBox(width: 10),
              Text(
                '${(order.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.totalReceived} of ${order.totalExpected} units received',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final PoItem item;
  final VoidCallback onReceiveAll;

  const _ItemCard({required this.item, required this.onReceiveAll});

  @override
  Widget build(BuildContext context) {
    final complete = item.isComplete;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.sku}  ·  ${item.barcode}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (complete)
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${item.receivedQty}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: complete ? AppColors.success : AppColors.brand,
                ),
              ),
              Text(
                ' / ${item.expectedQty} ${item.unit}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: complete ? null : onReceiveAll,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 38),
                ),
                child: Text(complete ? 'Done' : 'Receive all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(
            value: item.expectedQty == 0 ? 0 : item.receivedQty / item.expectedQty,
            color: complete ? AppColors.success : AppColors.brand,
            height: 6,
          ),
        ],
      ),
    );
  }
}
