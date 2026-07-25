import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wms_store.dart';
import '../models/pick_list.dart';
import '../widgets/scanner_page.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Picking · task detail. Scan each material's goods tag to confirm the pick.
class PickTaskPage extends ConsumerStatefulWidget {
  final String listId;
  const PickTaskPage({super.key, required this.listId});

  @override
  ConsumerState<PickTaskPage> createState() => _PickTaskPageState();
}

class _PickTaskPageState extends ConsumerState<PickTaskPage> {
  bool _busy = false;

  Future<void> _scanToPick(PickList list) async {
    final code = await ScannerPage.open(
      context,
      title: 'Scan Goods Tag',
      subtitle: 'Scan the material barcode to confirm the pick',
    );
    if (code == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(wmsStoreProvider).pickByBarcode(list.id, code);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? AppColors.success : AppColors.error,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(wmsStoreProvider).pickListById(widget.listId);
    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pick Task')),
        body: const AppEmptyState(icon: Icons.error_outline, title: 'Pick task not found'),
      );
    }

    final done = list.status == PickStatus.picked;

    return Scaffold(
      appBar: AppBar(title: Text(list.reference)),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(list.customer,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${list.lineCount} lines · ${list.totalPicked}/${list.totalToPick} units',
                                    style: const TextStyle(
                                        fontSize: 12.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          StatusPill(label: list.status.label, color: list.status.color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...list.lines.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LineCard(
                            line: line,
                            onPickAll: () =>
                                ref.read(wmsStoreProvider).pickLineFully(list.id, line.id),
                          ),
                        )),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 18,
                        offset: const Offset(0, -6)),
                  ],
                ),
                child: PrimaryButton(
                  label: done ? 'Picking complete' : 'Scan Goods Tag',
                  icon: done ? Icons.check_circle : Icons.qr_code_scanner,
                  loading: _busy,
                  gradient: done ? AppColors.mintGradient : AppColors.skyGradient,
                  onPressed: done ? null : () => _scanToPick(list),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final PickLine line;
  final VoidCallback onPickAll;
  const _LineCard({required this.line, required this.onPickAll});

  @override
  Widget build(BuildContext context) {
    final complete = line.isComplete;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${line.sku}  ·  ${line.barcode}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (complete)
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSky,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.accentSky),
                    const SizedBox(width: 4),
                    Text(line.binCode,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const Spacer(),
              Text('${line.qtyPicked}',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: complete ? AppColors.success : AppColors.accentSky)),
              Text(' / ${line.qtyToPick}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              TextButton(
                onPressed: complete ? null : onPickAll,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36)),
                child: const Text('All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            value: line.qtyToPick == 0 ? 0 : line.qtyPicked / line.qtyToPick,
            color: complete ? AppColors.success : AppColors.accentSky,
            height: 6,
          ),
        ],
      ),
    );
  }
}
