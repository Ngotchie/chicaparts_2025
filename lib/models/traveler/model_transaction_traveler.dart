class TravelerTransaction {
  final int id;
  final String service;
  final String operatorName;
  final String transactionRef;
  final String operatorTransactionId;
  final String paymentDate;
  final String payer;
  final num amount;
  final String currency;
  final num fees;
  final String status;
  final bool success;
  final String paymentItemType;
  final String createdAt;

  const TravelerTransaction({
    required this.id,
    required this.service,
    required this.operatorName,
    required this.transactionRef,
    required this.operatorTransactionId,
    required this.paymentDate,
    required this.payer,
    required this.amount,
    required this.currency,
    required this.fees,
    required this.status,
    required this.success,
    required this.paymentItemType,
    required this.createdAt,
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
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  factory TravelerTransaction.fromJson(Map<String, dynamic> json) {
    return TravelerTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      service: '${json['service'] ?? ''}',
      operatorName: '${json['operator'] ?? ''}',
      transactionRef: '${json['transaction_ref'] ?? ''}',
      operatorTransactionId: '${json['operator_transaction_id'] ?? ''}',
      paymentDate: '${json['payment_date'] ?? ''}',
      payer: '${json['payer'] ?? ''}',
      amount: _asNum(json['amount']),
      currency: '${json['currency'] ?? ''}',
      fees: _asNum(json['fees']),
      status: '${json['status'] ?? ''}',
      success: _asBool(json['success']),
      paymentItemType: '${json['payment_item_type'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
    );
  }
}
