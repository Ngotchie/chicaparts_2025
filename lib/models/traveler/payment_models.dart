enum TravelerPaymentStatus {
  initiated,
  pending,
  processing,
  paid,
  failed,
  cancelled,
  expired,
  refunded,
  partiallyRefunded,
  unknown,
}

extension TravelerPaymentStatusX on TravelerPaymentStatus {
  bool get isSuccessful => this == TravelerPaymentStatus.paid;

  bool get isTerminal =>
      isSuccessful ||
      this == TravelerPaymentStatus.failed ||
      this == TravelerPaymentStatus.cancelled ||
      this == TravelerPaymentStatus.expired ||
      this == TravelerPaymentStatus.refunded;
}

class PaymentMoney {
  final int minorUnits;
  final String currency;

  const PaymentMoney({
    required this.minorUnits,
    required this.currency,
  });

  factory PaymentMoney.fromMajor(num amount, String currency) {
    final normalizedCurrency = normalizePaymentCurrency(currency);
    final factor = isZeroDecimalPaymentCurrency(normalizedCurrency) ? 1 : 100;
    return PaymentMoney(
      minorUnits: (amount * factor).round(),
      currency: normalizedCurrency,
    );
  }

  double get majorAmount {
    final factor = isZeroDecimalPaymentCurrency(currency) ? 1 : 100;
    return minorUnits / factor;
  }

  num get apiAmount =>
      isZeroDecimalPaymentCurrency(currency) ? minorUnits : majorAmount;

  Map<String, dynamic> toJson() => {
        'minor_units': minorUnits,
        'currency': currency,
      };

  factory PaymentMoney.fromJson(Map<String, dynamic> json) {
    return PaymentMoney(
      minorUnits: (json['minor_units'] as num?)?.round() ?? 0,
      currency: normalizePaymentCurrency(json['currency']?.toString() ?? ''),
    );
  }
}

class PaymentOrder {
  final String provider;
  final String orderId;
  final String? paymentUrl;
  final String? clientSecret;
  final TravelerPaymentStatus status;
  final Map<String, dynamic> raw;

  const PaymentOrder({
    required this.provider,
    required this.orderId,
    required this.status,
    required this.raw,
    this.paymentUrl,
    this.clientSecret,
  });

  factory PaymentOrder.fromJson(
    Map<String, dynamic> json, {
    required String provider,
  }) {
    final data = _asMap(json['data']);
    return PaymentOrder(
      provider: provider.toLowerCase(),
      orderId: _firstString([
            json['order_id'],
            json['orderId'],
            json['id'],
            json['transaction_id'],
            data?['order_id'],
            data?['orderId'],
            data?['id'],
            data?['transaction_id'],
          ]) ??
          '',
      paymentUrl: _firstString([
        json['payment_url'],
        json['paymentUrl'],
        json['payment_link'],
        json['checkout_url'],
        json['redirect_url'],
        json['approval_url'],
        json['url'],
        data?['payment_url'],
        data?['paymentUrl'],
        data?['payment_link'],
        data?['checkout_url'],
        data?['redirect_url'],
        data?['approval_url'],
        data?['url'],
      ]),
      clientSecret: _firstString([
        json['clientSecret'],
        json['client_secret'],
        data?['clientSecret'],
        data?['client_secret'],
      ]),
      status: parseTravelerPaymentStatus(json),
      raw: json,
    );
  }
}

class PaymentTransaction {
  final String id;
  final String provider;
  final TravelerPaymentStatus status;
  final num? amount;
  final String? currency;
  final DateTime? paymentDate;
  final Map<String, dynamic> raw;

  const PaymentTransaction({
    required this.id,
    required this.provider,
    required this.status,
    required this.raw,
    this.amount,
    this.currency,
    this.paymentDate,
  });

  bool get isPaid => status.isSuccessful;

  factory PaymentTransaction.fromJson(
    Map<String, dynamic> json, {
    String? provider,
  }) {
    final transaction = _asMap(json['transaction']) ?? json;
    return PaymentTransaction(
      id: _firstString([
            transaction['transaction_ref'],
            transaction['operator_transaction_id'],
            transaction['id'],
          ]) ??
          '',
      provider: (provider ??
              transaction['service']?.toString() ??
              transaction['operator']?.toString() ??
              '')
          .toLowerCase(),
      status: parseTravelerPaymentStatus(transaction),
      amount: transaction['amount'] as num?,
      currency: transaction['currency']?.toString().toUpperCase(),
      paymentDate: DateTime.tryParse(
        transaction['payment_date']?.toString() ?? '',
      ),
      raw: Map<String, dynamic>.from(transaction),
    );
  }
}

TravelerPaymentStatus parseTravelerPaymentStatus(dynamic value) {
  if (value is Map && value['success'] == true) {
    return TravelerPaymentStatus.paid;
  }

  final map = value is Map ? value : null;
  final data = map == null ? null : _asMap(map['data']);
  final candidates = <String>[
    if (value is String) value,
    if (map?['status'] != null) map!['status'].toString(),
    if (map?['payment_status'] != null) map!['payment_status'].toString(),
    if (data?['status'] != null) data!['status'].toString(),
  ].map((item) => item.trim().toUpperCase()).toList();

  if (candidates.any(
    (status) => const {
      'PAID',
      'ACCEPTED',
      'COMPLETED',
      'SUCCESS',
      'SUCCEEDED',
    }.contains(status),
  )) {
    return TravelerPaymentStatus.paid;
  }
  if (candidates.any((status) => status.contains('PARTIAL_REFUND'))) {
    return TravelerPaymentStatus.partiallyRefunded;
  }
  if (candidates.any((status) => status.contains('REFUND'))) {
    return TravelerPaymentStatus.refunded;
  }
  if (candidates.any((status) => status.contains('EXPIRE'))) {
    return TravelerPaymentStatus.expired;
  }
  if (candidates.any(
    (status) => status.contains('CANCEL') || status.contains('CANCELED'),
  )) {
    return TravelerPaymentStatus.cancelled;
  }
  if (candidates.any(
    (status) =>
        status.contains('FAIL') ||
        status.contains('ERROR') ||
        status.contains('DECLIN'),
  )) {
    return TravelerPaymentStatus.failed;
  }
  if (candidates.any(
    (status) =>
        status.contains('PROCESS') || status.contains('REQUIRES_ACTION'),
  )) {
    return TravelerPaymentStatus.processing;
  }
  if (candidates.any(
    (status) =>
        status.contains('PEND') ||
        status.contains('WAIT') ||
        status.contains('CREATED') ||
        status.contains('APPROVED'),
  )) {
    return TravelerPaymentStatus.pending;
  }
  if (candidates.any((status) => status.contains('INIT'))) {
    return TravelerPaymentStatus.initiated;
  }
  return TravelerPaymentStatus.unknown;
}

String normalizePaymentCurrency(String currency) {
  final value = currency.trim().toUpperCase();
  if (value == 'FCFA' || value == 'CFA') return 'XAF';
  return value;
}

bool isZeroDecimalPaymentCurrency(String currency) {
  return const {
    'BIF',
    'CLP',
    'DJF',
    'GNF',
    'JPY',
    'KMF',
    'KRW',
    'MGA',
    'PYG',
    'RWF',
    'UGX',
    'VND',
    'VUV',
    'XAF',
    'XOF',
    'XPF',
  }.contains(normalizePaymentCurrency(currency));
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _firstString(Iterable<dynamic> values) {
  for (final value in values) {
    final result = value?.toString().trim();
    if (result != null && result.isNotEmpty && result != 'null') return result;
  }
  return null;
}
