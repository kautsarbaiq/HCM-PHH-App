import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardRegisterVisitorPage extends StatefulWidget {
  const GuardRegisterVisitorPage({super.key});

  @override
  State<GuardRegisterVisitorPage> createState() => _GuardRegisterVisitorPageState();
}

class _GuardRegisterVisitorPageState extends State<GuardRegisterVisitorPage> {
  bool _vehiclePicTaken = false;
  bool _visitorPicTaken = false;
  bool _licensePicTaken = false;

  void _simulateCamera(String type) {
    // Show mock camera UI
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera: $type'),
        content: Container(
          width: 300,
          height: 300,
          color: Colors.black,
          child: const Center(
            child: Icon(PhosphorIconsRegular.camera, color: Colors.white, size: 48),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (type == 'Vehicle Plate') _vehiclePicTaken = true;
                if (type == 'Visitor') _visitorPicTaken = true;
                if (type == 'Driving License') _licensePicTaken = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Capture', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walk-in Registration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manually register walk-in visitors by capturing required proofs.',
            style: TextStyle(color: Color(0xFFA3AED0)),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Destination House Number', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674))),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'e.g. A-01',
                    hintStyle: const TextStyle(color: Color(0xFFA3AED0)),
                    filled: true,
                    fillColor: const Color(0xFFF4F7FE),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Required Captures', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674))),
                const SizedBox(height: 16),
                
                _buildCaptureItem(
                  'Vehicle Plate',
                  PhosphorIconsRegular.car,
                  _vehiclePicTaken,
                  () => _simulateCamera('Vehicle Plate'),
                ),
                _buildCaptureItem(
                  'Visitor Face',
                  PhosphorIconsRegular.userFocus,
                  _visitorPicTaken,
                  () => _simulateCamera('Visitor'),
                ),
                _buildCaptureItem(
                  'Driving License / ID',
                  PhosphorIconsRegular.identificationCard,
                  _licensePicTaken,
                  () => _simulateCamera('Driving License'),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_vehiclePicTaken && _visitorPicTaken && _licensePicTaken) 
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor registered successfully!')));
                          setState(() {
                            _vehiclePicTaken = false;
                            _visitorPicTaken = false;
                            _licensePicTaken = false;
                          });
                        }
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: const Color(0xFFE0E5F2),
                    ),
                    child: const Text('Complete Registration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureItem(String label, IconData icon, bool isCaptured, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isCaptured ? const Color(0xFF10B981) : const Color(0xFFE0E5F2), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isCaptured ? const Color(0xFF10B981).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isCaptured ? const Color(0xFF10B981) : const Color(0xFFA3AED0)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCaptured ? const Color(0xFF10B981) : const Color(0xFF2B3674),
                ),
              ),
            ),
            Icon(
              isCaptured ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.camera,
              color: isCaptured ? const Color(0xFF10B981) : const Color(0xFF4318FF),
            ),
          ],
        ),
      ),
    );
  }
}
