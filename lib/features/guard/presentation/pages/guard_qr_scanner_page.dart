import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/visitor_repository.dart';
import 'guard_visitors_page.dart'; // For guardVisitorsProvider

class GuardQrScannerPage extends ConsumerStatefulWidget {
  const GuardQrScannerPage({super.key});

  @override
  ConsumerState<GuardQrScannerPage> createState() => _GuardQrScannerPageState();
}

class _GuardQrScannerPageState extends ConsumerState<GuardQrScannerPage> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  bool _isProcessing = false;
  bool _loadingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- Loading dialog helpers (tracked + scoped pop) ---------------------

  void _showLoadingDialog() {
    if (_loadingDialogOpen || !mounted) return;
    _loadingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _dismissLoadingDialog() {
    if (!_loadingDialogOpen || !mounted) return;
    _loadingDialogOpen = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        await _processQrCode(code);
      }
    }
  }

  // [showLoading] lets callers (e.g. gallery flow) reuse an already-open
  // dialog instead of stacking a second one.
  Future<void> _processQrCode(String qrToken, {bool showLoading = true}) async {
    if (_isProcessing && !_loadingDialogOpen) return;
    setState(() => _isProcessing = true);

    // Pause the live camera so noDuplicates can't re-fire behind a dialog.
    await _scannerController.stop();

    if (showLoading) _showLoadingDialog();

    try {
      final repo = ref.read(visitorRepositoryProvider);
      final visitor = await repo.getVisitorByQrToken(qrToken);

      if (!mounted) return;
      _dismissLoadingDialog();

      if (visitor != null) {
        await _showVisitorDetails(visitor);
      } else {
        await _showErrorDialog('Invalid QR Code. No visitor found with this token.');
      }
    } catch (e) {
      if (!mounted) return;
      _dismissLoadingDialog();
      await _showErrorDialog('An error occurred while verifying the QR code: $e');
    } finally {
      // Only re-enable scanning once any result dialog is dismissed.
      if (mounted) {
        await _scannerController.start();
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    _showLoadingDialog();

    try {
      final barcodeCapture = await _scannerController.analyzeImage(image.path);

      if (!mounted) return;

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final String? code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          // Reuse the loading dialog already on screen.
          await _processQrCode(code, showLoading: false);
          return;
        } else {
          _dismissLoadingDialog();
          await _showErrorDialog('Could not read QR code from the selected image.');
        }
      } else {
        _dismissLoadingDialog();
        await _showErrorDialog('No QR code found in the selected image.');
      }
    } catch (e) {
      if (!mounted) return;
      _dismissLoadingDialog();
      await _showErrorDialog('Failed to process image: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Scan Failed', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVisitorDetails(Visitor visitor) {
    final raw = visitor.checkedInAt ?? visitor.expectedAt;
    final dateStr = raw != null
        ? DateFormat('MMM d, yyyy HH:mm').format(DateTime.parse(raw).toLocal())
        : 'Walk-in';

    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 12),
            Flexible(child: Text('Scan Successful', style: TextStyle(color: Color(0xFF2B3674)))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Visitor Name', visitor.visitorName),
              _buildDetailRow('House No.', visitor.house?.houseNumber ?? '-'),
              _buildDetailRow('Purpose', visitor.purpose),
              _buildDetailRow('Date', dateStr),
              _buildDetailRow('Plate No.', visitor.vehiclePlate ?? '-'),
              _buildDetailRow('Status', visitor.status.toUpperCase()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (visitor.status == 'expected')
            _CheckInButton(
              visitorId: visitor.id,
              dialogContext: dialogContext,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size the reticle from the available area so it scales on small
              // phones and tablets alike.
              final reticleSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.65;
              return Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleBarcode,
                  ),
                  // Scanner Overlay
                  Center(
                    child: SizedBox(
                      width: reticleSize,
                      height: reticleSize,
                      child: Stack(
                        children: [
                          Container(
                            width: reticleSize,
                            height: reticleSize,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
                          Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
                          Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
                          Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),
                          // Scanning line animation
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Positioned(
                                top: _animationController.value * reticleSize,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Position the QR code within the frame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _scanFromGallery,
                          icon: const Icon(PhosphorIconsRegular.image),
                          label: const Text('Scan from Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2B3674),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Camera controls overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.highlight, color: Colors.white),
                          onPressed: () => _scannerController.toggleTorch(),
                          tooltip: 'Toggle torch',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white),
                          onPressed: () => _scannerController.switchCamera(),
                          tooltip: 'Switch camera',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF10B981), width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF10B981), width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF10B981), width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF10B981), width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(20) : Radius.zero,
          topRight: top && !left ? const Radius.circular(20) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(20) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(20) : Radius.zero,
        ),
      ),
    );
  }
}

// Self-contained check-in button so it can manage its own in-flight spinner
// and error handling without rebuilding the whole dialog.
class _CheckInButton extends ConsumerStatefulWidget {
  final String visitorId;
  final BuildContext dialogContext;

  const _CheckInButton({required this.visitorId, required this.dialogContext});

  @override
  ConsumerState<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends ConsumerState<_CheckInButton> {
  bool _busy = false;

  Future<void> _checkIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(guardVisitorsProvider.notifier).updateStatus(widget.visitorId, 'checked_in');
      if (widget.dialogContext.mounted) {
        Navigator.pop(widget.dialogContext);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Visitor checked in successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
      onPressed: _busy ? null : _checkIn,
      child: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Check In Visitor', style: TextStyle(color: Colors.white)),
    );
  }
}
