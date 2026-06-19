import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/house_repository.dart';

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
          SnackBar(content: Text('Could not start a call to $phone'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start a call to $phone'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final housesAsync = ref.watch(guardHousesProvider);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Directory',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B3674),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'List of all houses and their emergency contact persons',
            style: TextStyle(color: const Color(0xFFA3AED0), fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: housesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorState(
                  message: 'Error: $error',
                  onRetry: () => ref.invalidate(guardHousesProvider),
                ),
                data: (houses) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(guardHousesProvider),
                    child: houses.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 200.h),
                              const Center(
                                child: Text('No houses found.', style: TextStyle(color: Color(0xFFA3AED0))),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F7FE)),
                                      columns: const [
                                        DataColumn(label: Text('House No.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                      ],
                                      rows: houses.map((house) {
                                        final phone = house.owner?.phone;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                house.houseNumber,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                                              ),
                                            ),
                                            DataCell(Text(house.owner?.fullName ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                            DataCell(Text(phone ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.phone, color: Color(0xFF4318FF)),
                                                tooltip: phone != null ? 'Call $phone' : 'No number',
                                                onPressed: (phone != null && phone.isNotEmpty)
                                                    ? () => _callPhone(context, phone)
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
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA3AED0)),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
