import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_repository.dart';

class Billing {
  final String id;
  final String invoiceNumber;
  final String title;
  final double amount;
  final String? dueDate; // ISO date (yyyy-MM-dd)
  final String status; // unpaid | paid | overdue
  final String? period;
  final String? paidAt;
  final String residentId;
  final String houseId;

  // Joined
  final Profile? resident;

  Billing({
    required this.id,
    required this.invoiceNumber,
    required this.title,
    required this.amount,
    this.dueDate,
    required this.status,
    this.period,
    this.paidAt,
    required this.residentId,
    required this.houseId,
    this.resident,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return Billing(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      title: json['title'] as String? ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : double.tryParse('$rawAmount') ?? 0,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      period: json['period'] as String?,
      paidAt: json['paid_at'] as String?,
      residentId: json['resident_id'] as String,
      houseId: json['house_id'] as String,
      resident: json['resident'] != null ? Profile.fromJson(json['resident'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'house_id': houseId,
      'resident_id': residentId,
      'title': title,
      'amount': amount,
      'due_date': dueDate,
      'status': status,
      'period': period,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    };
  }
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(Supabase.instance.client);
});

class BillingRepository {
  final SupabaseClient _supabase;

  BillingRepository(this._supabase);

  static const _selectWithResident = '*, resident:profiles!billings_resident_id_fkey(*)';

  Future<List<Billing>> getAllBillings() async {
    final response = await _supabase
        .from('billings')
        .select(_selectWithResident)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Billing.fromJson(json)).toList();
  }

  /// Bills belonging to the current resident (RLS `resident_read_own` filters
  /// to rows where resident_id = auth.uid()).
  Future<List<Billing>> getMyBillings() async {
    final response = await _supabase
        .from('billings')
        .select(_selectWithResident)
        .order('due_date', ascending: false);

    return (response as List).map((json) => Billing.fromJson(json)).toList();
  }

  Future<void> createBilling(Billing billing) async {
    await _supabase.from('billings').insert(billing.toJson());
  }

  Future<void> updateBilling(String id, Map<String, dynamic> updates) async {
    await _supabase.from('billings').update(updates).eq('id', id);
  }

  Future<void> deleteBilling(String id) async {
    await _supabase.from('billings').delete().eq('id', id);
  }
}
