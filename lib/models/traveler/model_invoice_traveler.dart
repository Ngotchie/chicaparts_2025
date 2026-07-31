class TravelerInvoice {
  final int id;
  final String ref;
  final String invoiceNumber;
  final String label;
  final String description;
  final String type;
  final String typeLabel;
  final String status;
  final String statusLabel;
  final num totalAmount;
  final num paidAmount;
  final num remainingAmount;
  final num paymentPercentage;
  final String currency;
  final String dueDate;
  final String dueDateFormatted;
  final bool isOverdue;
  final bool isPayable;
  final String createdAt;
  final String createdAtFormatted;
  final String paidAtFormatted;
  final String accommodationName;
  final String bookingRef;
  final int bookingId;
  final List<InvoicePaymentAttempt> paymentAttempts;

  const TravelerInvoice({
    required this.id,
    required this.ref,
    required this.invoiceNumber,
    required this.label,
    required this.description,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentPercentage,
    required this.currency,
    required this.dueDate,
    required this.dueDateFormatted,
    required this.isOverdue,
    required this.isPayable,
    required this.createdAt,
    required this.createdAtFormatted,
    required this.paidAtFormatted,
    required this.accommodationName,
    required this.bookingRef,
    required this.bookingId,
    required this.paymentAttempts,
  });

  static num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  factory TravelerInvoice.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] is Map
        ? Map<String, dynamic>.from(json['booking'] as Map)
        : const <String, dynamic>{};
    final accommodation = json['accommodation'] is Map
        ? Map<String, dynamic>.from(json['accommodation'] as Map)
        : const <String, dynamic>{};

    return TravelerInvoice(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ref: '${json['ref'] ?? ''}',
      invoiceNumber: '${json['invoice_number'] ?? ''}',
      label: '${json['label'] ?? ''}',
      description: '${json['description'] ?? ''}',
      type: '${json['type'] ?? ''}',
      typeLabel: '${json['type_label'] ?? ''}',
      status: '${json['status'] ?? ''}',
      statusLabel: '${json['status_label'] ?? ''}',
      totalAmount: _asNum(json['total_amount']),
      paidAmount: _asNum(json['paid_amount']),
      remainingAmount: _asNum(json['remaining_amount']),
      paymentPercentage: _asNum(json['payment_percentage']),
      currency: '${json['currency'] ?? ''}',
      dueDate: '${json['due_date'] ?? ''}',
      dueDateFormatted: '${json['due_date_formatted'] ?? ''}',
      isOverdue: _asBool(json['is_overdue']),
      isPayable: _asBool(json['is_payable']),
      createdAt: '${json['created_at'] ?? ''}',
      createdAtFormatted: '${json['created_at_formatted'] ?? ''}',
      paidAtFormatted: '${json['paid_at_formated'] ?? json['paid_at_formatted'] ?? ''}',
      accommodationName:
          '${accommodation['external_name'] ?? accommodation['internal_name'] ?? ''}',
      bookingRef: '${booking['booking_ref'] ?? booking['reference'] ?? ''}',
      bookingId: booking['id'] is int
          ? booking['id']
          : int.tryParse('${booking['id']}') ?? 0,
      paymentAttempts: (json['transactions'] is List)
          ? (json['transactions'] as List)
              .whereType<Map>()
              .map(
                (item) => InvoicePaymentAttempt.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const <InvoicePaymentAttempt>[],
    );
  }
}

class InvoicePaymentAttempt {
  final int id;
  final String reference;
  final num amount;
  final String currency;
  final String service;
  final String paymentMethod;
  final bool success;
  final String status;
  final String paymentDate;

  const InvoicePaymentAttempt({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.service,
    required this.paymentMethod,
    required this.success,
    required this.status,
    required this.paymentDate,
  });

  factory InvoicePaymentAttempt.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentAttempt(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      reference: '${json['ref'] ?? ''}',
      amount: TravelerInvoice._asNum(json['amount']),
      currency: '${json['currency'] ?? ''}',
      service: '${json['service'] ?? ''}',
      paymentMethod: '${json['payment_method'] ?? ''}',
      success: TravelerInvoice._asBool(json['success']),
      status: '${json['status'] ?? ''}',
      paymentDate: '${json['payment_date'] ?? json['created_at'] ?? ''}',
    );
  }
}

class TravelerInvoiceStats {
  final num totalAmount;
  final num totalUnpaid;
  final num totalPaid;
  final int countUnpaid;
  final int countPaid;
  final int overdueCount;
  final String currency;

  const TravelerInvoiceStats({
    required this.totalAmount,
    required this.totalUnpaid,
    required this.totalPaid,
    required this.countUnpaid,
    required this.countPaid,
    required this.overdueCount,
    required this.currency,
  });

  static num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory TravelerInvoiceStats.fromJson(Map<String, dynamic> json) {
    return TravelerInvoiceStats(
      totalAmount: _asNum(json['total_amount']),
      totalUnpaid: _asNum(json['total_unpaid']),
      totalPaid: _asNum(json['total_paid']),
      countUnpaid: _asInt(json['count_unpaid']),
      countPaid: _asInt(json['count_paid']),
      overdueCount: _asInt(json['overdue_count']),
      currency: '${json['currency'] ?? 'EUR'}',
    );
  }
}
