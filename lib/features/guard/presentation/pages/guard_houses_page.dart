import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/house_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../theme/app_colors.dart';

final guardHousesProvider = FutureProvider<List<House>>((ref) async {
  final repo = ref.read(houseRepositoryProvider);
  return repo.getAllHouses();
});

class GuardHousesPage extends ConsumerWidget {
  const GuardHousesPage({super.key});

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start a call to $phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start a call to $phone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final housesAsync = ref.watch(guardHousesProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.canvasGradient),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: PhosphorIconsFill.house,
                gradient: AppColors.brandGradient,
                size: 50,
                iconSize: 25,
                radius: 16,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'House Directory',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All houses and their emergency contacts',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryWhite,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A7BA8).withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: housesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => AppErrorState(
                  message: 'Error: $error',
                  onRetry: () => ref.invalidate(guardHousesProvider),
                ),
                data: (houses) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(guardHousesProvider),
                    child: houses.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 80),
                              const AppEmptyState(
                                icon: PhosphorIconsRegular.house,
                                title: 'No houses found',
                                message:
                                    'Houses will appear here once they are added to the directory.',
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Phones (< 600px): vertical cards, only up/down
                              // scrolling — never sideways.
                              if (constraints.maxWidth < 600) {
                                return ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.all(12),
                                  itemCount: houses.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildHouseCard(context, houses[index]),
                                );
                              }
                              // Tablet/desktop: keep the wide table.
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            AppColors.surfaceTint,
                                          ),
                                      columns: const [
                                        DataColumn(
                                          label: Text(
                                            'House No.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Owner Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Mobile Number',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Contact',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows: houses.map((house) {
                                        final phone = house.owner?.phone;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                house.houseNumber,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                house.owner?.fullName ?? '-',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                phone ?? '-',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(
                                                  PhosphorIconsFill.phone,
                                                  color: AppColors.brand,
                                                ),
                                                tooltip: phone != null
                                                    ? 'Call $phone'
                                                    : 'No number',
                                                onPressed:
                                                    (phone != null &&
                                                        phone.isNotEmpty)
                                                    ? () => _callPhone(
                                                        context,
                                                        phone,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCard(BuildContext context, House house) {
    final phone = house.owner?.phone;
    final hasPhone = phone != null && phone.isNotEmpty;
    return PremiumCard(
      padding: EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: PhosphorIconsFill.house,
                gradient: AppColors.brandGradient,
                size: 42,
                iconSize: 20,
                radius: 13,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'House ${house.houseNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _infoRow('Owner', house.owner?.fullName ?? '-'),
          SizedBox(height: 8),
          _infoRow('Mobile', phone ?? '-'),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: hasPhone ? AppColors.brandGradient : null,
                color: hasPhone
                    ? null
                    : AppColors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: hasPhone
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton.icon(
                onPressed: hasPhone ? () => _callPhone(context, phone) : null,
                icon: const Icon(PhosphorIconsFill.phone, size: 18),
                label: Text(
                  hasPhone ? 'Call $phone' : 'No number',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
