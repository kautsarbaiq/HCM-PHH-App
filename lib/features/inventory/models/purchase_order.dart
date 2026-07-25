import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

enum ReceiveStatus { pending, partial, received }

extension ReceiveStatusX on ReceiveStatus {
  String get label => switch (this) {
        ReceiveStatus.pending => 'Pending',
        ReceiveStatus.partial => 'Partial',
        ReceiveStatus.received => 'Received',
      };

  Color get color => switch (this) {
        ReceiveStatus.pending => AppColors.textSecondary,
        ReceiveStatus.partial => AppColors.warning,
        ReceiveStatus.received => AppColors.success,
      };
}

/// A single line item on a purchase order.
class PoItem {
  final String id;
  final String sku;
  final String name;
  final String barcode;
  final String unit;
  final int expectedQty;
  int receivedQty;

  PoItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.barcode,
    required this.expectedQty,
    this.receivedQty = 0,
    this.unit = 'pcs',
  });

  int get remaining => (expectedQty - receivedQty).clamp(0, expectedQty);
  bool get isComplete => receivedQty >= expectedQty;
  bool get isOver => receivedQty > expectedQty;

  factory PoItem.fromJson(Map<String, dynamic> json) => PoItem(
        id: json['id'].toString(),
        sku: json['sku'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String,
        unit: json['unit'] as String? ?? 'pcs',
        expectedQty: (json['expected_qty'] as num).toInt(),
        receivedQty: (json['received_qty'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'barcode': barcode,
        'unit': unit,
        'expected_qty': expectedQty,
        'received_qty': receivedQty,
      };
}

/// A purchase order received into the warehouse.
class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplier;
  final DateTime expectedDate;
  final DateTime createdAt;
  final List<PoItem> items;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplier,
    required this.expectedDate,
    required this.createdAt,
    required this.items,
  });

  int get totalExpected => items.fold(0, (s, i) => s + i.expectedQty);
  int get totalReceived => items.fold(0, (s, i) => s + i.receivedQty);
  int get lineCount => items.length;

  double get progress =>
      totalExpected == 0 ? 0 : (totalReceived / totalExpected).clamp(0, 1).toDouble();

  ReceiveStatus get status {
    if (totalReceived == 0) return ReceiveStatus.pending;
    if (items.every((i) => i.isComplete)) return ReceiveStatus.received;
    return ReceiveStatus.partial;
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
        id: json['id'].toString(),
        poNumber: json['po_number'] as String,
        supplier: json['supplier'] as String,
        expectedDate: DateTime.parse(json['expected_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => PoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum VarianceType { match, short, over }

extension VarianceTypeX on VarianceType {
  String get label => switch (this) {
        VarianceType.match => 'Match',
        VarianceType.short => 'Short',
        VarianceType.over => 'Over',
      };

  Color get color => switch (this) {
        VarianceType.match => AppColors.success,
        VarianceType.short => AppColors.error,
        VarianceType.over => AppColors.warning,
      };
}

/// Expected-vs-received reconciliation row (Comparison module).
class ComparisonRow {
  final String sku;
  final String name;
  final int expected;
  final int received;

  ComparisonRow({
    required this.sku,
    required this.name,
    required this.expected,
    required this.received,
  });

  int get variance => received - expected;

  VarianceType get type {
    if (variance == 0) return VarianceType.match;
    return variance < 0 ? VarianceType.short : VarianceType.over;
  }

  factory ComparisonRow.fromItem(PoItem item) => ComparisonRow(
        sku: item.sku,
        name: item.name,
        expected: item.expectedQty,
        received: item.receivedQty,
      );
}
