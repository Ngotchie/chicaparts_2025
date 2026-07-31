import 'dart:async';
import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/payment_models.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentApiException implements Exception {
  final String code;
  final int? statusCode;
  final String? technicalMessage;

  const PaymentApiException(
    this.code, {
    this.statusCode,
    this.technicalMessage,
  });

  @override
  String toString() => 'PaymentApiException($code, status: $statusCode)';
}

class ApiPayment {
  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<PaymentOrder> createPaymentOrder({
    required String service,
    required PaymentMoney money,
    required String name,
    required String customerEmail,
    required int bookingId,
    String? customerPhoneNumber,
    String paymentItemType = 'booking',
  }) async {
    if (money.minorUnits <= 0) {
      throw const PaymentApiException('invalid_amount');
    }

    final provider = service.trim().toLowerCase();
    final response = await _post(
      'payment-gateway/create-order/$provider/flutter',
      {
        'amount': money.apiAmount,
        'currency': money.currency,
        'name': name,
        'description': name,
        'customer_email': customerEmail.trim(),
        'booking_id': bookingId,
        'payment_item_type': paymentItemType,
        'payment_item_id': bookingId,
        'meta': {
          'platform': 'flutter',
          'booking_id': bookingId,
        },
        if (customerPhoneNumber?.trim().isNotEmpty == true)
          'customer_phone_number': customerPhoneNumber!.trim(),
      },
      operation: 'create_order',
      provider: provider,
      bookingId: bookingId,
    );

    return PaymentOrder.fromJson(response, provider: provider);
  }

  /// Conservée temporairement pour les anciens appels internes. Toute nouvelle
  /// intégration doit utiliser [createPaymentOrder].
  Future<dynamic> checkoutTransaction({
    required String service,
    required double amount,
    required String currency,
    required String name,
    required String customerEmail,
    required int bookingId,
    String? customerPhoneNumber,
    String paymentItemType = 'booking',
  }) async {
    final order = await createPaymentOrder(
      service: service,
      money: PaymentMoney.fromMajor(amount, currency),
      name: name,
      customerEmail: customerEmail,
      bookingId: bookingId,
      customerPhoneNumber: customerPhoneNumber,
      paymentItemType: paymentItemType,
    );
    return order.raw;
  }

  Future<Map<String, dynamic>?> completePaymentOrder({
    required String service,
    required String orderId,
  }) async {
    if (orderId.trim().isEmpty) {
      throw const PaymentApiException('missing_order_id');
    }
    return _post(
      'payment-gateway/check-order/${service.toLowerCase()}',
      {'order_id': orderId.trim()},
      operation: 'check_order',
      provider: service,
    );
  }

  /// Compatibilité avec les transactions créées avant la migration vers
  /// payment-gateway. Cette méthode doit seulement servir de solution de repli.
  Future<Map<String, dynamic>?> checkExistingTransaction({
    required String service,
    required int bookingId,
    String paymentItemType = 'booking',
  }) async {
    try {
      return await _post(
        'transactions/check',
        {
          'payment_service': service,
          'booking_id': bookingId,
          'payment_item_type': paymentItemType,
        },
        operation: 'legacy_check',
        provider: service,
        bookingId: bookingId,
        allowNotFound: true,
      );
    } on PaymentApiException catch (error) {
      if (error.code == 'not_found') return null;
      rethrow;
    }
  }

  Future<String> checkPaymentStatus(String service, int bookingId) async {
    final transaction = await checkExistingTransaction(
      service: service,
      bookingId: bookingId,
    );
    return transaction?['status']?.toString() ?? 'pending';
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    required String operation,
    required String provider,
    int? bookingId,
    bool allowNotFound = false,
  }) async {
    final api = ApiUrl();
    final endpoint = Uri.parse('${api.getChicapartsUrl()}$path');

    try {
      debugPrint(
        'Payment $operation started: provider=$provider booking=$bookingId',
      );
      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Authorization': api.getKey(),
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      debugPrint(
        'Payment $operation completed: provider=$provider '
        'booking=$bookingId status=${response.statusCode}',
      );

      final decoded = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      if (allowNotFound && response.statusCode == 404) {
        throw const PaymentApiException('not_found', statusCode: 404);
      }
      throw PaymentApiException(
        _errorCodeForStatus(response.statusCode),
        statusCode: response.statusCode,
        technicalMessage: _safeBackendMessage(decoded),
      );
    } on TimeoutException {
      throw const PaymentApiException('timeout');
    } on http.ClientException catch (error) {
      throw PaymentApiException('network', technicalMessage: error.message);
    } on FormatException catch (error) {
      throw PaymentApiException(
        'invalid_response',
        technicalMessage: error.message,
      );
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('Expected a JSON object');
  }

  String _errorCodeForStatus(int status) {
    if (status == 401 || status == 403) return 'unauthorized';
    if (status == 404) return 'not_found';
    if (status == 409) return 'conflict';
    if (status == 422) return 'validation';
    if (status == 429) return 'rate_limited';
    if (status >= 500) return 'server';
    return 'request_failed';
  }

  String? _safeBackendMessage(Map<String, dynamic> response) {
    final error = response['error'];
    final candidates = [
      response['message'],
      if (error is Map) error['message'],
      if (error is Map && error['details'] is Map) error['details']['message'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }
}
