import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft),
              onPressed: () => context.pop(),
            ),
            title: const Text('Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(PhosphorIconsRegular.gear),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Resident Documents'),
                  const SizedBox(height: 16),
                  _buildDocumentGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Financial Records'),
                  const SizedBox(height: 16),
                  _buildFinanceList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&h=150&q=80'),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const Icon(PhosphorIconsRegular.pencilSimple, size: 20, color: AppColors.deepSlate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Alex Morgan',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resident since Oct 2023',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(PhosphorIconsRegular.phone, 'Phone', '+60 12-345 6789'),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(PhosphorIconsRegular.envelopeSimple, 'Email', 'alex.morgan@hcm.com'),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(PhosphorIconsRegular.mapPin, 'Address', 'A-18-08, Block A, PHH Residency'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.deepSlate),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const Icon(PhosphorIconsRegular.caretRight, size: 18, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildDocumentGrid() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildDocumentCard('Unit Deed', 'DOC-882XX482', PhosphorIconsRegular.fileText),
          _buildDocumentCard('Tenancy Agreement', 'AGR-XX9-1318', PhosphorIconsRegular.signature),
          _buildDocumentCard('Pet License', 'PET-XXX1929', PhosphorIconsRegular.pawPrint),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String subtitle, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.deepSlate),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceList() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildFinanceRow(PhosphorIconsRegular.receipt, 'Monthly Statements'),
          const SizedBox(height: 8),
          _buildFinanceRow(PhosphorIconsRegular.shieldCheck, 'Maintenance Receipts'),
          const SizedBox(height: 8),
          _buildFinanceRow(PhosphorIconsRegular.bank, 'Billing Accounts'),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.deepSlate),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
          const Icon(PhosphorIconsRegular.caretRight, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
