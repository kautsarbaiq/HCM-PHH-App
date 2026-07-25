import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../theme/app_colors.dart';

/// Reusable barcode/QR scanner. Returns the scanned code (or a manually-typed
/// one) via `Navigator.pop`. Used for both "Scan Goods Tag" and
/// "Scan Location Tag" across the WMS modules.
class ScannerPage extends StatefulWidget {
  final String title;
  final String subtitle;

  const ScannerPage({
    super.key,
    this.title = 'Scan Barcode',
    this.subtitle = 'Align the barcode within the frame',
  });

  /// Pushes the scanner and resolves to the scanned/typed code, or null if
  /// the user backed out.
  static Future<String?> open(
    BuildContext context, {
    String title = 'Scan Barcode',
    String subtitle = 'Align the barcode within the frame',
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ScannerPage(title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String code) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop(code.trim());
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code != null) _finish(code);
  }

  Future<void> _manualEntry() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter code manually'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. 8991002340012'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (code != null && code.trim().isNotEmpty) _finish(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Dim + framed cut-out
          const _ScannerOverlay(),
          // Top bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                        icon: Icon(
                          _torchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _manualEntry,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                      label: const Text('Enter code manually'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.brand, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.4),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
