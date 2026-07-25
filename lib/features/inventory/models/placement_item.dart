import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

enum PlacementStatus { awaiting, placed }

extension PlacementStatusX on PlacementStatus {
  String get label => switch (this) {
        PlacementStatus.awaiting => 'Awaiting',
        PlacementStatus.placed => 'Placed',
      };

  Color get color => switch (this) {
        PlacementStatus.awaiting => AppColors.warning,
        PlacementStatus.placed => AppColors.success,
      };
}

/// A received item awaiting put-away (Placement) into a bin location.
class PlacementItem {
  final String id;
  final String sku;
  final String name;
  final String barcode;
  final int qty;
  final String sourcePo;
  String? binCode;
  PlacementStatus status;

  PlacementItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.barcode,
    required this.qty,
    required this.sourcePo,
    this.binCode,
    this.status = PlacementStatus.awaiting,
  });

  factory PlacementItem.fromJson(Map<String, dynamic> json) => PlacementItem(
        id: json['id'].toString(),
        sku: json['sku'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String,
        qty: (json['qty'] as num).toInt(),
        sourcePo: json['source_po'] as String,
        binCode: json['bin_code'] as String?,
        status: (json['bin_code'] != null)
            ? PlacementStatus.placed
            : PlacementStatus.awaiting,
      );
}
