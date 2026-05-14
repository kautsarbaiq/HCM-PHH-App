import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryWhite.withOpacity(0.88),
              border: Border(
                right: BorderSide(color: AppColors.glassBorder, width: 1.5),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionLabel('E-Governance'),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.fileText,
                          title: 'E-Form',
                          subtitle: 'Submit forms online',
                          route: '/eform',
                        ),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.filePdf,
                          title: 'E-Document',
                          subtitle: 'Rules & regulations',
                          route: '/edocument',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel('Directory'),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.usersThree,
                          title: 'Committee',
                          subtitle: 'Management committee',
                          route: '/committee',
                        ),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.shieldCheck,
                          title: 'Security Guard',
                          subtitle: 'On duty today',
                          route: '/security-guard',
                        ),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.addressBook,
                          title: 'E-Contact',
                          subtitle: 'Essential contacts',
                          route: '/econtact',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel('Community'),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.calendarCheck,
                          title: 'Events (RSVP)',
                          subtitle: 'Upcoming community events',
                          route: '/events',
                        ),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.chartBar,
                          title: 'E-Polling',
                          subtitle: 'Vote on community matters',
                          route: '/epolling',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel('Lifestyle'),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.storefront,
                          title: 'Market Square',
                          subtitle: 'Trusted home services',
                          route: '/market-square',
                        ),
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.buildings,
                          title: 'Book Facilities',
                          subtitle: 'Pool, gym, BBQ & more',
                          route: '/facility',
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageGreen.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child: Text(
                'AM',
                style: TextStyle(
                  color: AppColors.sageGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Morgan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unit A-12-03',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context); // Close drawer
            context.push(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.deepSlate, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textSecondary.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
