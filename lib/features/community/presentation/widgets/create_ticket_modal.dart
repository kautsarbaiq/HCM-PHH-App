import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/repositories/ticket_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../pages/community_page.dart';

class CreateTicketModal extends ConsumerStatefulWidget {
  const CreateTicketModal({super.key});

  @override
  ConsumerState<CreateTicketModal> createState() => _CreateTicketModalState();
}

class _CreateTicketModalState extends ConsumerState<CreateTicketModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a ticket title.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null)
        throw Exception('You must be logged in to create a ticket.');

      final ticket = Ticket(
        id: '', // Supabase generates this
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: 'Pending',
        createdBy: profile.id,
        createdAt: '',
      );

      await ref.read(ticketRepositoryProvider).createTicket(ticket);
      await ref.read(myTicketsProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Making it slightly shorter than 95% since it's just a simple form, but padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border(
              top: BorderSide(
                color: AppColors.primaryWhite.withOpacity(0.6),
                width: 1.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create New Ticket',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Report an issue, request maintenance, or submit feedback to the management office.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Issue Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _titleController,
                  hintText: 'e.g. Leaking pipe in master bathroom',
                  prefixIcon: PhosphorIconsRegular.wrench,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _descController,
                  hintText: 'Provide more details...',
                  prefixIcon: PhosphorIconsRegular.textAa,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : ActionButton(
                        label: 'Submit Ticket',
                        onPressed: _submitTicket,
                        backgroundColor: AppColors.primaryBlue,
                        icon: PhosphorIconsRegular.paperPlaneRight,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
