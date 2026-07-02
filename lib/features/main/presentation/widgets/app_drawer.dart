import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../theme/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  _buildProfileHeader(context, ref),
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
                        _buildDrawerTile(
                          context,
                          icon: PhosphorIconsRegular.identificationCard,
                          title: 'Scan ID',
                          subtitle: 'Auto-fill from your ID / license',
                          route: '/scan-id',
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
                        const SizedBox(height: 16),
                        _buildSectionLabel('Language'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: Row(
                            children: const [
                              Text(
                                'Language',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Spacer(),
                              LanguageSwitcher(),
                            ],
                          ),
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

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'Guest';
    final role = profile?.role;
    final subtitle = (role == null || role.isEmpty)
        ? 'Tap to view profile'
        : '${role[0].toUpperCase()}${role.substring(1)}';
    final avatarUrl = profile?.avatarUrl;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.push('/profile');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        width: 52,
                        height: 52,
                        errorBuilder: (_, __, ___) => const Icon(
                          PhosphorIconsRegular.user,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : const Icon(
                        PhosphorIconsRegular.user,
                        color: AppColors.primaryBlue,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
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
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
