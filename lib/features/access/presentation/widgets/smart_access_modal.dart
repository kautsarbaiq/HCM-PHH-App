import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_colors.dart';

class SmartAccessModal extends StatefulWidget {
  final int initialView; // 0 = menu, 1 = intercom, 2 = gate control

  const SmartAccessModal({super.key, this.initialView = 0});

  @override
  State<SmartAccessModal> createState() => _SmartAccessModalState();
}

class _SmartAccessModalState extends State<SmartAccessModal>
    with TickerProviderStateMixin {
  late int _currentView;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isGateUnlocked = false;
  double _volume = 0.8;
  int _activeGateIndex = 0;

  Timer? _autoLockTimer;
  int _autoLockSeconds = 10;

  Timer? _intercomTimer;
  int _intercomSeconds = 0;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _lockController;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.initialView == 1) {
      _startIntercomTimer();
    }
  }

  void _startIntercomTimer() {
    _intercomSeconds = 0;
    _intercomTimer?.cancel();
    _intercomTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _intercomSeconds++;
        });
      }
    });
  }

  void _startAutoLockTimer() {
    _autoLockSeconds = 10;
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_autoLockSeconds > 1) {
            _autoLockSeconds--;
          } else {
            _autoLockSeconds = 0;
            _isGateUnlocked = false;
            _lockController.reverse();
            _autoLockTimer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lockController.dispose();
    _autoLockTimer?.cancel();
    _intercomTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.95;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: sheetHeight,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border(
              top: BorderSide(
                color: AppColors.primaryWhite.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentView == 0
                  ? _buildMenu()
                  : _currentView == 1
                  ? _buildIntercom()
                  : _buildGateControl(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      key: const ValueKey('menu'),
      mainAxisSize: MainAxisSize.max,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.deepSlate.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Smart Access Control',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your community access control remotely.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _buildAccessOption(
                icon: PhosphorIconsFill.phoneCall,
                title: 'Mobile Intercom',
                subtitle: 'Call Guardhouse',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  setState(() => _currentView = 1);
                  _startIntercomTimer();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAccessOption(
                icon: PhosphorIconsFill.shieldCheck,
                title: 'Smart Lock',
                subtitle: 'Unlock Gates',
                color: const Color(0xFF8B5CF6),
                onTap: () => setState(() => _currentView = 2),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildAccessOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withOpacity(0.24), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepSlate,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntercom() {
    final String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    return Column(
      key: const ValueKey('intercom'),
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _currentView = 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.deepSlate.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  size: 20,
                  color: AppColors.deepSlate,
                ),
              ),
            ),
            const Text(
              'Mobile Intercom',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 40), // Balanced spacing
          ],
        ),
        const SizedBox(height: 20),

        // Scrollable middle so short/narrow phones never overflow.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // High-Fidelity Simulated Lobby Entrance Camera Feed
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&w=800&q=80',
                        ), // Premium upscale lobby
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Scanline visual effect overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: List.generate(
                                    50,
                                    (index) => Colors.black.withOpacity(
                                      index % 2 == 0 ? 0.08 : 0.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // HUD Camera overlays
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(),
                                      )
                                      .fadeIn(duration: 500.ms)
                                      .fadeOut(duration: 500.ms),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'LIVE REC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'LOBBY CAM 01',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Active Ringing Call Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pulser Avatar
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ...List.generate(2, (index) {
                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final progress =
                                    (_pulseController.value + index / 2) % 1.0;
                                return Container(
                                  width: 48 + (progress * 24),
                                  height: 48 + (progress * 24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.2 * (1 - progress)),
                                  ),
                                );
                              },
                            );
                          }),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1596495578065-6e0763fa1141?auto=format&fit=crop&w=150&h=150&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: const Color(0xFF3B82F6),
                                      child: const Icon(
                                        PhosphorIconsFill.userCircle,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guard Post Alpha',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .scale(
                                      duration: 800.ms,
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.3, 1.3),
                                    ),
                                const SizedBox(width: 6),
                                Text(
                                  _intercomSeconds < 3
                                      ? 'Calling Security Guard...'
                                      : 'Connected - 00:${_intercomSeconds.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Speaker Volume Slider
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.deepSlate.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.deepSlate.withOpacity(0.02),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMuted
                            ? PhosphorIconsFill.microphoneSlash
                            : PhosphorIconsFill.microphone,
                        color: _isMuted
                            ? AppColors.error
                            : const Color(0xFF3B82F6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.5,
                            ),
                            activeTrackColor: const Color(0xFF3B82F6),
                            inactiveTrackColor: AppColors.deepSlate.withOpacity(
                              0.08,
                            ),
                            thumbColor: const Color(0xFF3B82F6),
                            overlayColor: const Color(
                              0xFF3B82F6,
                            ).withOpacity(0.12),
                          ),
                          child: Slider(
                            value: _volume,
                            onChanged: (val) {
                              setState(() {
                                _volume = val;
                                _isMuted = val == 0;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _volume > 0.5
                            ? PhosphorIconsFill.speakerHigh
                            : PhosphorIconsFill.speakerLow,
                        color: const Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Responses / Actions
                const Text(
                  'QUICK RESPONSES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickReplyButton('Leave at Lobby 📦'),
                      _buildQuickReplyButton('Wait a Minute ⏳'),
                      _buildQuickReplyButton('Wrong Resident ❌'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Active Calling Buttons (End Call & Controls)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCallControlCircle(
              icon: _isMuted
                  ? PhosphorIconsFill.microphoneSlash
                  : PhosphorIconsFill.microphone,
              label: 'Mute',
              isActive: _isMuted,
              onTap: () => setState(() => _isMuted = !_isMuted),
            ),
            // LARGE EMERGENCY RED END CALL BUTTON
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsFill.phoneDisconnect,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            _buildCallControlCircle(
              icon: _isSpeakerOn
                  ? PhosphorIconsFill.speakerHigh
                  : PhosphorIconsFill.speakerNone,
              label: 'Speaker',
              isActive: _isSpeakerOn,
              onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildQuickReplyButton(String text) {
    return GestureDetector(
      onTap: () {
        // Capture the messenger from the root context before popping the modal,
        // otherwise this context is defunct after Navigator.pop and the
        // snackbar silently fails.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Quick reply sent: "$text"'),
            backgroundColor: const Color(0xFF3B82F6),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.deepSlate.withOpacity(0.12)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.deepSlate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallControlCircle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3B82F6) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : AppColors.deepSlate.withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFF3B82F6).withOpacity(0.2)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.deepSlate,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateControl() {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Column(
          key: const ValueKey('gate'),
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _currentView = 0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.deepSlate.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.caretLeft,
                      size: 20,
                      color: AppColors.deepSlate,
                    ),
                  ),
                ),
                const Text(
                  'Smart Lock Control',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable body so the fixed lock UI never overflows on short phones.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gate Sliding Selection Tab
                    _buildGateTabs(setInnerState),
                    const SizedBox(height: 24),

                    // Large Premium Lock circle
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isGateUnlocked = !_isGateUnlocked;
                            if (_isGateUnlocked) {
                              _lockController.forward();
                              _startAutoLockTimer();
                            } else {
                              _lockController.reverse();
                              _autoLockTimer?.cancel();
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _isGateUnlocked
                                ? const Color(0xFF10B981).withOpacity(0.06)
                                : const Color(0xFF8B5CF6).withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isGateUnlocked
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : const Color(0xFF8B5CF6).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Circular ticker countdown border
                              if (_isGateUnlocked) ...[
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    // Drive the ring from the live auto-lock countdown so
                                    // it stays in sync with the seconds text below.
                                    value: _autoLockSeconds / 10,
                                    strokeWidth: 3.5,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF10B981),
                                        ),
                                    backgroundColor: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.12),
                                  ),
                                ),
                              ],
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isGateUnlocked
                                        ? [
                                            const Color(0xFF10B981),
                                            const Color(0xFF059669),
                                          ]
                                        : [
                                            const Color(0xFF8B5CF6),
                                            const Color(0xFF6D28D9),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isGateUnlocked
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF8B5CF6))
                                              .withOpacity(0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedRotation(
                                    turns: _isGateUnlocked ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 350),
                                    child: Icon(
                                      _isGateUnlocked
                                          ? PhosphorIconsFill.lockSimpleOpen
                                          : PhosphorIconsFill.lockSimple,
                                      color: Colors.white,
                                      size: 46,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        _isGateUnlocked ? 'Gate Unlocked' : 'Gate Locked',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _isGateUnlocked
                            ? 'Will lock automatically in ${_autoLockSeconds}s...'
                            : 'Tap to toggle lock wirelessly',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isGateUnlocked
                              ? const Color(0xFF10B981)
                              : AppColors.textSecondary,
                          fontWeight: _isGateUnlocked
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invite Guest Passcard
                    _buildGuestPasscard(),
                    const SizedBox(height: 20),

                    // GATE HISTORY SECTION (Activity Log)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.deepSlate.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.deepSlate.withOpacity(0.02),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'RECENT ACTIVITY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildGateActivityRow(
                            name: 'Alex Morgan (You)',
                            time: '12 mins ago',
                            action: 'Bluetooth Unlock',
                            avatarUrl:
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=80&h=80&q=80',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, thickness: 0.6),
                          ),
                          _buildGateActivityRow(
                            name: 'Courier Delivery (Guest)',
                            time: '2 hours ago',
                            action: 'Scan QR Code Pass',
                            avatarUrl:
                                'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=80&h=80&q=80',
                          ),
                        ],
                      ),
                    ),

                    // Demo disclaimer — this flow is a simulation, not a real
                    // IoT/gate-unlock call yet.
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.info,
                          size: 13,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Demo mode — not connected to a physical gate',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Capture the messenger before popping; the modal context is
                  // defunct after Navigator.pop.
                  final messenger = ScaffoldMessenger.of(context);
                  final unlocked = _isGateUnlocked;
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        unlocked
                            ? 'Gate unlocked (demo)'
                            : 'Gate control updated (demo)',
                      ),
                      backgroundColor: unlocked
                          ? const Color(0xFF10B981)
                          : const Color(0xFF8B5CF6),
                    ),
                  );
                },
                icon: Icon(
                  _isGateUnlocked
                      ? PhosphorIconsFill.shieldSlash
                      : PhosphorIconsFill.shieldCheck,
                  size: 20,
                ),
                label: Text(
                  _isGateUnlocked ? 'Close & Done' : 'Unlock Manually',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isGateUnlocked
                      ? const Color(0xFF10B981)
                      : const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildGateTabs(StateSetter setInnerState) {
    final List<String> gates = ['Main Gate', 'Lift Lobby', 'Gym Room'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.deepSlate.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(gates.length, (index) {
          final isSelected = _activeGateIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setInnerState(() {
                  _activeGateIndex = index;
                  // Reset gate lock when changing gates for visual simulation
                  _isGateUnlocked = false;
                  _lockController.reverse();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    gates[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.deepSlate
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGuestPasscard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsFill.qrCode,
              color: Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Invite Guest / Friends',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSlate,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Generate a temporary visitor QR or PIN pass',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            PhosphorIconsRegular.caretRight,
            color: Color(0xFF8B5CF6),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildGateActivityRow({
    required String name,
    required String time,
    required String action,
    required String avatarUrl,
  }) {
    return Row(
      children: [
        // User Profile Pic or fallback icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.deepSlate.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.backgroundGrey,
                child: const Icon(
                  PhosphorIconsFill.user,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                action,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
