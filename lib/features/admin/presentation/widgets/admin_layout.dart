import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/brand.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/app_strings.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      drawer: isDesktop ? null : _buildSidebar(context, ref, isDesktop: false),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logoBadge(28),
                  const SizedBox(width: 10),
                  const Text(
                    Brand.appName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () async =>
                      Supabase.instance.client.auth.signOut(),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildSidebar(context, ref, isDesktop: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _buildTopBar(context, ref),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoBadge(double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(Brand.isPhh ? 0 : size * 0.1),
      decoration: BoxDecoration(
        color: Brand.isPhh ? null : Colors.white,
        gradient: Brand.isPhh ? AppColors.brandGradient : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Brand.isPhh
          ? Icon(
              Icons.holiday_village_rounded,
              color: Colors.white,
              size: size * 0.6,
            )
          : Image.asset(Brand.logoAsset, fit: BoxFit.contain),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    String title = ref.tr('admin.dashboard');
    if (location.contains('residents')) {
      title = ref.tr('admin.residents');
    } else if (location.contains('communities')) {
      title = ref.tr('admin.communities');
    } else if (location.contains('alerts')) {
      title = ref.tr('admin.alertHistory');
    } else if (location.contains('houses')) {
      title = ref.tr('admin.houses');
    } else if (location.contains('announcements')) {
      title = ref.tr('admin.announcements');
    } else if (location.contains('billings')) {
      title = ref.tr('admin.billings');
    } else if (location.contains('visitors')) {
      title = ref.tr('admin.visitors');
    } else if (location.contains('events')) {
      title = ref.tr('admin.events');
    } else if (location.contains('polls')) {
      title = ref.tr('admin.polling');
    } else if (location.contains('documents')) {
      title = ref.tr('admin.documents');
    } else if (location.contains('forms')) {
      title = ref.tr('admin.eforms');
    } else if (location.contains('contacts')) {
      title = ref.tr('admin.contacts');
    } else if (location.contains('guards')) {
      title = ref.tr('admin.guards');
    } else if (location.contains('marketplace')) {
      title = ref.tr('admin.marketSquare');
    } else if (location.contains('facilities')) {
      title = ref.tr('admin.facilities');
    } else if (location.contains('id-scans')) {
      title = ref.tr('admin.residentIds');
    } else if (location.contains('bookings')) {
      title = ref.tr('admin.bookings');
    } else if (location.contains('rewards')) {
      title = ref.tr('admin.rewards');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ref.tr('admin.pages')} / ${ref.tr('admin.admin')} / '
                  '$title',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A7BA8).withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () async =>
                      Supabase.instance.client.auth.signOut(),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref,
      {required bool isDesktop}) {
    final String location = GoRouterState.of(context).uri.path;
    final double sidebarWidth = isDesktop
        ? 270
        : math.min(280, MediaQuery.of(context).size.width * 0.82);

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoBadge(40),
                const SizedBox(width: 12),
                const Text(
                  Brand.appName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(height: 1, color: const Color(0xFFEEF1FA)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Boss voice note 18/08: the sidebar was 19 flat rows —
                  // grouped into labelled sections so the portal is
                  // navigable at a glance.
                  _sectionLabel(ref.trs('Main')),
                  _item(context, ref, Icons.dashboard_rounded, ref.tr('admin.dashboard'),
                      '/admin/dashboard', location == '/admin/dashboard', isDesktop),
                  _item(context, ref, Icons.people_alt_rounded, ref.tr('admin.residents'),
                      '/admin/residents', location.startsWith('/admin/residents'), isDesktop),
                  _item(context, ref, Icons.house_rounded, ref.tr('admin.housesUnits'),
                      '/admin/houses', location.startsWith('/admin/houses'), isDesktop),
                  _item(context, ref, Icons.apartment_rounded, ref.tr('admin.communities'),
                      '/admin/communities', location.startsWith('/admin/communities'), isDesktop),
                  _sectionLabel(ref.trs('Operations')),
                  _item(context, ref, Icons.badge_rounded, ref.tr('admin.visitors'),
                      '/admin/visitors', location.startsWith('/admin/visitors'), isDesktop),
                  _item(context, ref, Icons.event_available_rounded, ref.tr('admin.bookings'),
                      '/admin/bookings', location.startsWith('/admin/bookings'), isDesktop),
                  _item(context, ref, Icons.pool_rounded, ref.tr('admin.facilities'),
                      '/admin/facilities', location.startsWith('/admin/facilities'), isDesktop),
                  _item(context, ref, Icons.shield_rounded, ref.tr('admin.guards'),
                      '/admin/guards', location.startsWith('/admin/guards'), isDesktop),
                  _item(context, ref, Icons.notifications_active_rounded, ref.tr('admin.alertHistory'),
                      '/admin/alerts', location.startsWith('/admin/alerts'), isDesktop),
                  _sectionLabel(ref.trs('Finance')),
                  _item(context, ref, Icons.receipt_long_rounded, ref.tr('admin.billings'),
                      '/admin/billings', location.startsWith('/admin/billings'), isDesktop),
                  _item(context, ref, Icons.card_giftcard_rounded, ref.tr('admin.rewards'),
                      '/admin/rewards', location.startsWith('/admin/rewards'), isDesktop),
                  _sectionLabel(ref.trs('Community')),
                  _item(context, ref, Icons.campaign_rounded, ref.tr('admin.announcements'),
                      '/admin/announcements', location.startsWith('/admin/announcements'), isDesktop),
                  _item(context, ref, Icons.celebration_rounded, ref.tr('admin.events'),
                      '/admin/events', location.startsWith('/admin/events'), isDesktop),
                  _item(context, ref, Icons.how_to_vote_rounded, ref.tr('admin.polling'),
                      '/admin/polls', location.startsWith('/admin/polls'), isDesktop),
                  _item(context, ref, Icons.storefront_rounded, ref.tr('admin.market'),
                      '/admin/marketplace', location.startsWith('/admin/marketplace'), isDesktop),
                  _sectionLabel(ref.trs('Records')),
                  _item(context, ref, Icons.picture_as_pdf_rounded, ref.tr('admin.documents'),
                      '/admin/documents', location.startsWith('/admin/documents'), isDesktop),
                  _item(context, ref, Icons.description_rounded, ref.tr('admin.forms'),
                      '/admin/forms', location.startsWith('/admin/forms'), isDesktop),
                  _item(context, ref, Icons.contacts_rounded, ref.tr('admin.contacts'),
                      '/admin/contacts', location.startsWith('/admin/contacts'), isDesktop),
                  // Boss feedback 15/07: HCA doesn't use the ID-scan module.
                  if (Brand.isPhh)
                    _item(context, ref, Icons.badge_outlined,
                        ref.tr('admin.residentIds'), '/admin/id-scans',
                        location.startsWith('/admin/id-scans'), isDesktop),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: LanguageSwitcher()),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _item(
                context,
                ref,
                Icons.logout_rounded,
                ref.tr('common.logout'),
                null,
                false,
                isDesktop,
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small uppercase group heading in the sidebar.
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.textSecondary.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String title,
    String? path,
    bool selected,
    bool isDesktop, {
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (isLogout) {
              await Supabase.instance.client.auth.signOut();
              return;
            }
            if (path != null) {
              context.go(path);
              if (!isDesktop) Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              // Boss 18/08: the old full-width gradient + heavy shadow made the
              // whole sidebar shout. A soft tint plus a brand accent bar reads
              // as "you are here" without dominating the page.
              color: selected
                  ? AppColors.brand.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.brand
                      : (isLogout ? AppColors.error : AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.brand
                          : (isLogout
                                ? AppColors.error
                                : AppColors.textPrimary),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
