import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

enum PickStatus { pending, partial, picked }

extension PickStatusX on PickStatus {
  String get label => switch (this) {
        PickStatus.pending => 'Pending',
        PickStatus.partial => 'In Progress',
        PickStatus.picked => 'Picked',
      };

  Color get color => switch (this) {
        PickStatus.pending => AppColors.textSecondary,
        PickStatus.partial => AppColors.warning,
        PickStatus.picked => AppColors.success,
      };
}

/// A single line to pick from a storage bin.
class PickLine {
  final String id;
  final String sku;
  final String name;
  final String barcode;
  final String binCode;
  final int qtyToPick;
  int qtyPicked;

  PickLine({
    required this.id,
    required this.sku,
    required this.name,
    required this.barcode,
    required this.binCode,
    required this.qtyToPick,
    this.qtyPicked = 0,
  });

  int get remaining => (qtyToPick - qtyPicked).clamp(0, qtyToPick);
  bool get isComplete => qtyPicked >= qtyToPick;

  factory PickLine.fromJson(Map<String, dynamic> json) => PickLine(
        id: json['id'].toString(),
        sku: json['sku'] as String,
        name: json['name'] as String,
        barcode: json['barcode'] as String,
        binCode: json['bin_code'] as String,
        qtyToPick: (json['qty_to_pick'] as num).toInt(),
        qtyPicked: (json['qty_picked'] as num?)?.toInt() ?? 0,
      );
}

/// A picking task (e.g. a sales order to fulfil).
class PickList {
  final String id;
  final String reference;
  final String customer;
  final DateTime createdAt;
  final List<PickLine> lines;

  PickList({
    required this.id,
    required this.reference,
    required this.customer,
    required this.createdAt,
    required this.lines,
  });

  int get totalToPick => lines.fold(0, (s, l) => s + l.qtyToPick);
  int get totalPicked => lines.fold(0, (s, l) => s + l.qtyPicked);
  int get lineCount => lines.length;

  double get progress =>
      totalToPick == 0 ? 0 : (totalPicked / totalToPick).clamp(0, 1).toDouble();

  PickStatus get status {
    if (totalPicked == 0) return PickStatus.pending;
    if (lines.every((l) => l.isComplete)) return PickStatus.picked;
    return PickStatus.partial;
  }

  factory PickList.fromJson(Map<String, dynamic> json) => PickList(
        id: json['id'].toString(),
        reference: json['reference'] as String,
        customer: json['customer'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        lines: ((json['lines'] as List?) ?? const [])
            .map((e) => PickLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
