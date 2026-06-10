import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardQrScannerPage extends StatefulWidget {
  const GuardQrScannerPage({super.key});

  @override
  State<GuardQrScannerPage> createState() => _GuardQrScannerPageState();
}

class _GuardQrScannerPageState extends State<GuardQrScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _simulateScan() {
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
            _buildDetailRow('Visitor Name', 'John Doe'),
            _buildDetailRow('House No.', 'A-01'),
            _buildDetailRow('Purpose', 'Delivery'),
            _buildDetailRow('Date', 'Oct 25, 2026'),
            _buildDetailRow('Plate No.', 'B 1234 CD'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visitor Logged in Successfully!')),
              );
            },
            child: const Text('Confirm Entry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QR Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Scan resident-generated QR codes to view visitor details',
              style: TextStyle(color: Color(0xFFA3AED0)),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanner reticle
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // Scanning animation line
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: 50 + (_animationController.value * 250),
                      child: Container(
                        width: 250,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Positioned(
                  bottom: 20,
                  child: Text(
                    'Align QR code within the frame',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _simulateScan,
            icon: const Icon(PhosphorIconsRegular.scan),
            label: const Text('Simulate Scan Success'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
