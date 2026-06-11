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

  Future<void> _processQrCode(String qrToken) async {
    setState(() => _isProcessing = true);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = ref.read(visitorRepositoryProvider);
      final visitor = await repo.getVisitorByQrToken(qrToken);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (visitor != null) {
        _showVisitorDetails(visitor);
      } else {
        _showErrorDialog('Invalid QR Code. No visitor found with this token.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('An error occurred while verifying the QR code: $e');
    } finally {
      if (mounted) {
        // Wait a bit before allowing next scan so we don't spam
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isProcessing = true);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        final barcodeCapture = await _scannerController.analyzeImage(image.path);
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        
        if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
          final String? code = barcodeCapture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            await _processQrCode(code);
          } else {
            _showErrorDialog('Could not read QR code from the selected image.');
            setState(() => _isProcessing = false);
          }
        } else {
          _showErrorDialog('No QR code found in the selected image.');
          setState(() => _isProcessing = false);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorDialog('Failed to process image: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
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

  void _showVisitorDetails(Visitor visitor) {
    final dateStr = visitor.expectedAt != null 
        ? DateFormat('MMM d, yyyy HH:mm').format(DateTime.parse(visitor.expectedAt!).toLocal())
        : 'Walk-in';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(PhosphorIconsFill.checkCircle, color: Color(0xFF10B981), size: 32),
            SizedBox(width: 12),
            Text('Scan Successful', style: TextStyle(color: Color(0xFF2B3674))),
          ],
        ),
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (visitor.status == 'pending' || visitor.status == 'pre-registered')
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                // Update status to checked-in
                await ref.read(guardVisitorsProvider.notifier).updateStatus(visitor.id, 'checked-in');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visitor checked in successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Check In Visitor', style: TextStyle(color: Colors.white)),
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
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleBarcode,
              ),
              // Scanner Overlay
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCorner(top: true, left: true),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCorner(top: true, left: false),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCorner(top: false, left: true),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCorner(top: false, left: false),
                    ),
                    // Scanning line animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animationController.value * 250,
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
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _scanFromGallery,
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
                top: 40,
                right: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.highlight, color: Colors.white),
                      onPressed: () => _scannerController.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                  ],
                ),
              ),
            ],
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
