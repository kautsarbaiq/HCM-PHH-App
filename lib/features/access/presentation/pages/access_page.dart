import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/visitor_pass_card.dart';

// State Management
final accessTabIndexProvider = StateProvider<int>((ref) => 0);
final generatedPassesProvider = StateProvider<List<Map<String, String>>>((ref) => [
      {
        'name': 'John Doe',
        'type': 'Delivery',
        'time': 'Oct 25, 2026 - 10:30 AM',
        'qrData': 'v1-delivery-johndoe',
      }
    ]);

class AccessPage extends ConsumerStatefulWidget {
  const AccessPage({super.key});

  @override
  ConsumerState<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends ConsumerState<AccessPage> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _dateController = TextEditingController();
  final _plateController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _dateController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_nameController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulate network delay for success animation
    await Future.delayed(const Duration(milliseconds: 800));

    // Add new pass
    final newPass = {
      'name': _nameController.text,
      'type': _typeController.text.isEmpty ? 'Guest' : _typeController.text,
      'time': _dateController.text.isEmpty ? 'Today' : _dateController.text,
      'qrData': 'v-${DateTime.now().millisecondsSinceEpoch}-${_nameController.text}',
    };

    ref.read(generatedPassesProvider.notifier).update((state) => [newPass, ...state]);

    setState(() {
      _isSubmitting = false;
      _nameController.clear();
      _typeController.clear();
      _dateController.clear();
      _plateController.clear();
    });

    // Switch to Active Passes tab
    ref.read(accessTabIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(accessTabIndexProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSegmentedControl(tabIndex),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: IndexedStack(
                index: tabIndex,
                children: [
                  _buildPreRegisterForm().animate(target: tabIndex == 0 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  _buildActivePasses().animate(target: tabIndex == 1 ? 1 : 0).fade(duration: 300.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Visitor Access',
          style: TextStyle(
            fontSize: 28,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(0, 'Pre-Register', currentIndex),
          ),
          Expanded(
            child: _buildSegmentButton(1, 'Active Passes', currentIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label, int currentIndex) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(accessTabIndexProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            controller: _nameController,
            hintText: 'Visitor Name',
            prefixIcon: PhosphorIconsRegular.user,
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _typeController,
            hintText: 'Purpose (e.g. Guest, Delivery)',
            prefixIcon: PhosphorIconsRegular.tag,
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _dateController,
            hintText: 'Date & Time',
            prefixIcon: PhosphorIconsRegular.calendar,
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _plateController,
            hintText: 'Vehicle Plate (Optional)',
            prefixIcon: PhosphorIconsRegular.carProfile,
          ),
          const SizedBox(height: 32),
          _isSubmitting
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.sageGreen,
                  ),
                )
              : ActionButton(
                  label: 'Generate Pass',
                  onPressed: _submitForm,
                  backgroundColor: AppColors.sageGreen,
                  icon: PhosphorIconsRegular.qrCode,
                ),
        ],
      ),
    );
  }

  Widget _buildActivePasses() {
    final passes = ref.watch(generatedPassesProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: passes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final pass = passes[index];
        return VisitorPassCard(
          name: pass['name']!,
          type: pass['type']!,
          time: pass['time']!,
          qrData: pass['qrData']!,
        );
      },
    );
  }
}
