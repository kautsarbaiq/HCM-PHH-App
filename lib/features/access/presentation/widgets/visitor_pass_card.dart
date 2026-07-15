import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

class VisitorPassCard extends StatefulWidget {
  final String name;
  final String type;
  final String time;
  final String qrData;
  final String status;

  const VisitorPassCard({
    super.key,
    required this.name,
    required this.type,
    required this.time,
    required this.qrData,
    this.status = 'expected',
    this.passType,
  });

  /// HCA: human-readable pass validity, e.g. "Single entry" or
  /// "Multiple days: Jul 17, Jul 19 • 9:00 AM - 12:00 PM".
  final String? passType;

  @override
  State<VisitorPassCard> createState() => _VisitorPassCardState();
}

class _VisitorPassCardState extends State<VisitorPassCard> {
  // Captures just the QR tile as a shareable image (point 6).
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  ({String label, Color color}) get _statusBadge {
    switch (widget.status) {
      case 'checked_in':
        return (label: 'Checked-in', color: AppColors.success);
      case 'checked_out':
        return (label: 'Checked-out', color: AppColors.textSecondary);
      case 'expected':
        return (label: 'Expected', color: AppColors.primaryBlue);
      default:
        return (label: 'Active', color: AppColors.primaryBlue);
    }
  }

  /// Render the QR tile to a PNG and open the OS share sheet (WhatsApp, etc.).
  Future<void> _sharePass() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File(
        '${dir.path}/visitor_pass_${DateTime.now().millisecondsSinceEpoch}.png',
      ).writeAsBytes(bytes.buffer.asUint8List(0, bytes.lengthInBytes));

      final text =
          'Visitor pass for ${widget.name}\n${widget.type} • ${widget.time}\n'
          '${widget.passType != null ? '${widget.passType}\n' : ''}'
          'Show this QR code at the main gate.';
      await SharePlus.instance.share(
        ShareParams(text: text, files: [XFile(file.path)]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share the pass: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    color: badge.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth - 32).clamp(120.0, 200.0);
              return RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.qrData,
                    version: QrVersions.auto,
                    size: qrSize,
                    foregroundColor: AppColors.deepSlate,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.deepSlate,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.deepSlate,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            widget.time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          // HCA: the pass type (Single / Multiple days / Long term) with its
          // validity details.
          if (widget.passType != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.passType!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Scan this QR code at the main gate',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Point 6: share the QR pass via WhatsApp / any app.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sharing ? null : _sharePass,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _sharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(PhosphorIconsRegular.shareNetwork, size: 18),
              label: Text(_sharing ? 'Preparing…' : 'Share pass'),
            ),
          ),
        ],
      ),
    );
  }
}
