import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/premium_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';

/// One entry in the Quick Access catalog (HCA home grid).
class QuickAccessItem {
  final String id;
  final String label;
  final IconData icon; // Regular (outline) variant
  final IconData fillIcon; // Fill variant, tinted behind the outline
  final Color color;
  final String? route; // null → special action (emergency)
  final bool isEmergency;

  const QuickAccessItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.fillIcon,
    required this.color,
    this.route,
    this.isEmergency = false,
  });
}

/// Every feature reachable from the HCA home grid ("More" shows all of them;
/// the user picks which subset lives on the home page via "Customize").
const List<QuickAccessItem> quickAccessCatalog = [
  QuickAccessItem(
    id: 'visitor',
    label: 'Visitor',
    icon: PhosphorIconsRegular.identificationCard,
    fillIcon: PhosphorIconsFill.identificationCard,
    color: AppColors.brand,
    route: '/access',
  ),
  QuickAccessItem(
    id: 'billing',
    label: 'E-Billing',
    icon: PhosphorIconsRegular.receipt,
    fillIcon: PhosphorIconsFill.receipt,
    color: AppColors.accentSky,
    route: '/bills',
  ),
  QuickAccessItem(
    id: 'facility',
    label: 'Facility',
    icon: PhosphorIconsRegular.buildings,
    fillIcon: PhosphorIconsFill.buildings,
    color: AppColors.accentAmber,
    route: '/facility',
  ),
  QuickAccessItem(
    id: 'events',
    label: 'Events',
    icon: PhosphorIconsRegular.calendarCheck,
    fillIcon: PhosphorIconsFill.calendarCheck,
    color: AppColors.accentMint,
    route: '/events',
  ),
  QuickAccessItem(
    id: 'document',
    label: 'Document',
    icon: PhosphorIconsRegular.filePdf,
    fillIcon: PhosphorIconsFill.filePdf,
    color: AppColors.accentCoral,
    route: '/edocument',
  ),
  QuickAccessItem(
    id: 'contact',
    label: 'Contact',
    icon: PhosphorIconsRegular.addressBook,
    fillIcon: PhosphorIconsFill.addressBook,
    color: AppColors.primaryBlue,
    route: '/econtact',
  ),
  QuickAccessItem(
    id: 'emergency',
    label: 'Emergency',
    icon: PhosphorIconsRegular.bellSimpleRinging,
    fillIcon: PhosphorIconsFill.bellSimpleRinging,
    color: AppColors.accentCoral,
    isEmergency: true,
  ),
  QuickAccessItem(
    id: 'eform',
    label: 'E-Form',
    icon: PhosphorIconsRegular.fileText,
    fillIcon: PhosphorIconsFill.fileText,
    color: AppColors.brandViolet,
    route: '/eform',
  ),
  QuickAccessItem(
    id: 'polling',
    label: 'E-Polling',
    icon: PhosphorIconsRegular.chartBar,
    fillIcon: PhosphorIconsFill.chartBar,
    color: AppColors.accentPink,
    route: '/epolling',
  ),
  QuickAccessItem(
    id: 'market',
    label: 'Market',
    icon: PhosphorIconsRegular.storefront,
    fillIcon: PhosphorIconsFill.storefront,
    color: AppColors.accentAmber,
    route: '/market-square',
  ),
  QuickAccessItem(
    id: 'committee',
    label: 'Committee',
    icon: PhosphorIconsRegular.usersThree,
    fillIcon: PhosphorIconsFill.usersThree,
    color: AppColors.brandViolet,
    route: '/committee',
  ),
  QuickAccessItem(
    id: 'guard',
    label: 'Security',
    icon: PhosphorIconsRegular.shieldCheck,
    fillIcon: PhosphorIconsFill.shieldCheck,
    color: AppColors.accentMint,
    route: '/security-guard',
  ),
  QuickAccessItem(
    id: 'scanid',
    label: 'Scan ID',
    icon: PhosphorIconsRegular.identificationBadge,
    fillIcon: PhosphorIconsFill.identificationBadge,
    color: AppColors.accentCyan,
    route: '/scan-id',
  ),
];

const List<String> _defaultVisible = [
  'visitor',
  'billing',
  'facility',
  'events',
  'document',
  'contact',
  'emergency',
];

/// Which catalog ids are shown on the home page, persisted per device.
final quickAccessVisibleProvider =
    StateNotifierProvider<QuickAccessVisibleNotifier, List<String>>(
      (ref) => QuickAccessVisibleNotifier(),
    );

class QuickAccessVisibleNotifier extends StateNotifier<List<String>> {
  static const _prefsKey = 'quick_access_items';

  QuickAccessVisibleNotifier() : super(_defaultVisible) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && mounted) state = saved;
  }

  Future<void> toggle(String id) async {
    final next = state.contains(id)
        ? state.where((e) => e != id).toList()
        : [...state, id];
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next);
  }
}

/// "Quick Access" home section (HCA): duotone icon grid of the user-chosen
/// features + a permanent "More" tile that opens the full catalog. The
/// "Customize" button lets the resident pick what lives on the home page.
class QuickAccessSection extends ConsumerWidget {
  const QuickAccessSection({super.key});

  static void _open(BuildContext context, QuickAccessItem item) {
    if (item.isEmergency) {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EmergencyBottomSheet(),
      );
    } else if (item.route != null) {
      context.push(item.route!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleIds = ref.watch(quickAccessVisibleProvider);
    final items = quickAccessCatalog
        .where((i) => visibleIds.contains(i.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showCustomizeSheet(context),
                child: const Text(
                  'Customize',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
            children: [
              for (final item in items) _GridTile(item: item),
              // Permanent "More" tile — shows the full catalog.
              _GridTile(
                item: const QuickAccessItem(
                  id: '_more',
                  label: 'More',
                  icon: PhosphorIconsRegular.circlesFour,
                  fillIcon: PhosphorIconsFill.circlesFour,
                  color: AppColors.accentAmber,
                ),
                onTapOverride: () => _showMoreSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Root navigator: render ABOVE the floating bottom nav and SOS button.
      useRootNavigator: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'All Features',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: [
                  for (final item in quickAccessCatalog)
                    _GridTile(
                      item: item,
                      onTapOverride: () {
                        Navigator.pop(ctx);
                        _open(context, item);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showCustomizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Root navigator: render ABOVE the floating bottom nav and SOS button.
      useRootNavigator: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Consumer(
          builder: (ctx2, ref, _) {
            final visible = ref.watch(quickAccessVisibleProvider);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
                    child: Text(
                      'Customize Quick Access',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Choose which features appear on your home page.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in quickAccessCatalog)
                          SwitchListTile(
                            value: visible.contains(item.id),
                            activeColor: AppColors.primaryBlue,
                            title: Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            secondary: Icon(
                              item.icon,
                              color: AppColors.deepSlate,
                              size: 22,
                            ),
                            onChanged: (_) => ref
                                .read(quickAccessVisibleProvider.notifier)
                                .toggle(item.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final QuickAccessItem item;
  final VoidCallback? onTapOverride;

  const _GridTile({required this.item, this.onTapOverride});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTapOverride ?? () => QuickAccessSection._open(context, item),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lime "sticker" fill, slightly offset from the outline —
                // matches the reference icon style.
                Transform.translate(
                  offset: const Offset(3, 3),
                  child: Icon(
                    item.fillIcon,
                    color: AppColors.duotoneFill,
                    size: 36,
                  ),
                ),
                Icon(item.icon, color: AppColors.deepSlate, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
