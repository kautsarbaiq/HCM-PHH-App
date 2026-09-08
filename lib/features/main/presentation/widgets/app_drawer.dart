import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/config/brand.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rewards is a house-owner perk (meeting 20/07 point 9) — hidden for tenants.
    final isOwner =
        !(ref.watch(currentProfileProvider).valueOrNull?.isTenant ?? false);
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
                        _buildSectionLabel(ref.tr('menu.eGovernance')),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.fileText,
                          fillIcon: PhosphorIconsFill.fileText,
                          title: ref.tr('menu.eform'),
                          subtitle: ref.tr('menu.eformSub'),
                          route: '/eform',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.filePdf,
                          fillIcon: PhosphorIconsFill.filePdf,
                          title: ref.tr('menu.edocument'),
                          subtitle: ref.tr('menu.edocumentSub'),
                          route: '/edocument',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.identificationCard,
                          fillIcon: PhosphorIconsFill.identificationCard,
                          title: ref.tr('menu.scanId'),
                          subtitle: ref.tr('menu.scanIdSub'),
                          route: '/scan-id',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel(ref.tr('menu.directory')),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.usersThree,
                          fillIcon: PhosphorIconsFill.usersThree,
                          title: ref.tr('menu.committee'),
                          subtitle: ref.tr('menu.committeeSub'),
                          route: '/committee',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.shieldCheck,
                          fillIcon: PhosphorIconsFill.shieldCheck,
                          title: ref.tr('menu.guard'),
                          subtitle: ref.tr('menu.guardSub'),
                          route: '/security-guard',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.addressBook,
                          fillIcon: PhosphorIconsFill.addressBook,
                          title: ref.tr('menu.econtact'),
                          subtitle: ref.tr('menu.econtactSub'),
                          route: '/econtact',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel(ref.tr('menu.community')),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.calendarCheck,
                          fillIcon: PhosphorIconsFill.calendarCheck,
                          title: ref.tr('menu.events'),
                          subtitle: ref.tr('menu.eventsSub'),
                          route: '/events',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.chartBar,
                          fillIcon: PhosphorIconsFill.chartBar,
                          title: ref.tr('menu.epolling'),
                          subtitle: ref.tr('menu.epollingSub'),
                          route: '/epolling',
                        ),
                        const SizedBox(height: 8),
                        _buildSectionLabel(ref.tr('menu.lifestyle')),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.storefront,
                          fillIcon: PhosphorIconsFill.storefront,
                          title: ref.tr('menu.marketSquare'),
                          subtitle: ref.tr('menu.marketSquareSub'),
                          route: '/market-square',
                        ),
                        _buildDrawerTile(
                          context,
                          ref,
                          icon: PhosphorIconsRegular.buildings,
                          fillIcon: PhosphorIconsFill.buildings,
                          title: ref.tr('menu.facility'),
                          subtitle: ref.tr('menu.facilitySub'),
                          route: '/facility',
                        ),
                        if (isOwner)
                          _buildDrawerTile(
                            context,
                            ref,
                            icon: PhosphorIconsRegular.gift,
                            fillIcon: PhosphorIconsFill.gift,
                            title: ref.tr('menu.rewards'),
                            subtitle: ref.tr('menu.rewardsSub'),
                            route: '/rewards',
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
        ? ref.tr('menu.viewProfile')
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
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    IconData? fillIcon,
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
                // PHH: original boxed icon. HCA: duotone (soft teal fill
                // behind a navy outline), no box.
                if (Brand.isPhh || fillIcon == null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.deepSlate, size: 20),
                  )
                else
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          fillIcon,
                          color: AppColors.primaryBlue.withOpacity(0.40),
                          size: 30,
                        ),
                        Icon(icon, color: AppColors.deepSlate, size: 30),
                      ],
                    ),
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
