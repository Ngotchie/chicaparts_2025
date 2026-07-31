import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/payment_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingPaymentAttempt {
  final int bookingId;
  final String paymentItemType;
  final String provider;
  final String orderId;
  final PaymentMoney amount;
  final DateTime createdAt;
  final TravelerPaymentStatus status;

  const PendingPaymentAttempt({
    required this.bookingId,
    required this.paymentItemType,
    required this.provider,
    required this.orderId,
    required this.amount,
    required this.createdAt,
    required this.status,
  });

  bool get canResume =>
      orderId.isNotEmpty &&
      !status.isTerminal &&
      createdAt.isAfter(DateTime.now().subtract(const Duration(days: 2)));

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'payment_item_type': paymentItemType,
        'provider': provider,
        'order_id': orderId,
        'amount': amount.toJson(),
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory PendingPaymentAttempt.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString();
    return PendingPaymentAttempt(
      bookingId: (json['booking_id'] as num?)?.toInt() ?? 0,
      paymentItemType: json['payment_item_type']?.toString() ?? 'booking',
      provider: json['provider']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: PaymentMoney.fromJson(
        Map<String, dynamic>.from(json['amount'] as Map? ?? const {}),
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: TravelerPaymentStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => TravelerPaymentStatus.pending,
      ),
    );
  }

  PendingPaymentAttempt copyWith({TravelerPaymentStatus? status}) {
    return PendingPaymentAttempt(
      bookingId: bookingId,
      paymentItemType: paymentItemType,
      provider: provider,
      orderId: orderId,
      amount: amount,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

class PendingPaymentStore {
  static const _prefix = 'pending_payment_v2_';

  String _key(int bookingId, String paymentItemType, String provider) =>
      '$_prefix${paymentItemType}_${bookingId}_${provider.toLowerCase()}';

  Future<void> save(PendingPaymentAttempt attempt) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(attempt.bookingId, attempt.paymentItemType, attempt.provider),
      jsonEncode(attempt.toJson()),
    );
  }

  Future<PendingPaymentAttempt?> read({
    required int bookingId,
    required String paymentItemType,
    required String provider,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _key(bookingId, paymentItemType, provider);
    final encoded = preferences.getString(key);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      final attempt = PendingPaymentAttempt.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!attempt.canResume) {
        await preferences.remove(key);
        return null;
      }
      return attempt;
    } catch (_) {
      await preferences.remove(key);
      return null;
    }
  }

  Future<void> markStatus(
    PendingPaymentAttempt attempt,
    TravelerPaymentStatus status,
  ) async {
    if (status.isTerminal) {
      await clear(
        bookingId: attempt.bookingId,
        paymentItemType: attempt.paymentItemType,
        provider: attempt.provider,
      );
      return;
    }
    await save(attempt.copyWith(status: status));
  }

  Future<void> clear({
    required int bookingId,
    required String paymentItemType,
    required String provider,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(bookingId, paymentItemType, provider));
  }
}
