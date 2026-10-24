import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_guard.dart';
import 'profile_repository.dart';

class Billing {
  final String id;
  final String invoiceNumber;
  final String title;
  final double amount;
  final String? dueDate; // ISO date (yyyy-MM-dd)
  /// unpaid | submitted | paid | overdue
  ///
  /// 'submitted' means the resident uploaded proof of a bank transfer but
  /// nobody in the office has confirmed the money arrived yet. It is
  /// deliberately not 'paid': a photo is a claim, not a settled debt.
  final String status;
  final String? period;
  final String? paidAt;
  final String residentId;
  final String houseId;

  /// Storage path in the private `payment_receipts` bucket, not a URL.
  /// Open it with [BillingRepository.receiptSignedUrl].
  final String? receiptUrl;
  final String? receiptUploadedAt;

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
    this.receiptUrl,
    this.receiptUploadedAt,
    this.resident,
  });

  bool get hasReceipt => (receiptUrl ?? '').isNotEmpty;

  /// Waiting for someone in the office to check the receipt.
  bool get awaitingConfirmation => status == 'submitted';

  factory Billing.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return Billing(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      title: json['title'] as String? ?? '',
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse('$rawAmount') ?? 0,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      period: json['period'] as String?,
      paidAt: json['paid_at'] as String?,
      residentId: json['resident_id'] as String,
      houseId: json['house_id'] as String,
      receiptUrl: json['receipt_url'] as String?,
      receiptUploadedAt: json['receipt_uploaded_at'] as String?,
      resident: json['resident'] != null
          ? Profile.fromJson(json['resident'] as Map<String, dynamic>)
          : null,
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

  static const _selectWithResident =
      '*, resident:profiles!billings_resident_id_fkey(*)';

  Future<List<Billing>> getAllBillings() async {
    final response = await _supabase
        .from('billings')
        .select(_selectWithResident)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Billing.fromJson(json)).toList();
  }

  /// Bills the current resident may see. RLS (`resident_read_own`, migration
  /// 34) returns bills addressed to them, to their household's main account,
  /// and bills raised against the unit they live in — a house can hold several
  /// resident accounts, and a maintenance bill belongs to the unit.
  ///
  /// Wrapped in [SessionGuard] so a stale access token refreshes and retries
  /// instead of failing the page.
  Future<List<Billing>> getMyBillings() {
    return SessionGuard.run(() async {
      final response = await _supabase
          .from('billings')
          .select(_selectWithResident)
          .order('due_date', ascending: false);

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    });
  }

  static const _receiptBucket = 'payment_receipts';

  /// Uploads the resident's proof of a bank transfer and moves the bill to
  /// 'submitted'.
  ///
  /// The status change goes through the `submit_payment_receipt` SQL function
  /// rather than a plain update: residents must not hold a general UPDATE
  /// grant on billings, or the same grant would let them set their own bills
  /// to 'paid'. The function checks ownership and refuses an already-paid
  /// bill.
  ///
  /// The file is stored under `<user id>/...` because the bucket's policies
  /// key off that first folder segment — a resident can only ever read or
  /// replace files inside their own folder.
  Future<void> submitReceipt({
    required String billingId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');

    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final path = '$uid/$billingId-${DateTime.now().millisecondsSinceEpoch}.$ext';

    await SessionGuard.run(() async {
      await _supabase.storage.from(_receiptBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeFor(ext),
            ),
          );
      await _supabase.rpc('submit_payment_receipt', params: {
        'p_billing_id': billingId,
        'p_receipt_path': path,
      });
    });
  }

  /// Receipts live in a private bucket — a receipt shows a bank account and a
  /// name, so it must not be readable by guessing a URL. Management opens one
  /// through a short-lived signed link instead.
  Future<String> receiptSignedUrl(String path) {
    return SessionGuard.run(
      () => _supabase.storage.from(_receiptBucket).createSignedUrl(path, 3600),
    );
  }

  /// Management confirms the money arrived. Separate from the resident's
  /// upload on purpose: only a human decision clears a debt.
  Future<void> confirmPayment(String billingId) {
    return SessionGuard.run(
      () => _supabase.rpc('confirm_payment', params: {
        'p_billing_id': billingId,
      }),
    );
  }

  static String _contentTypeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
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
