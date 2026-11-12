class PriceQuote {
  final String quoteId;
  final DateTime expiresAt;
  final String currency;
  final int numberOfNights;
  final int numberOfGuests;
  final int extraGuests;
  final double nightAmount;
  final double extraGuestAmount;
  final double stayAmount;
  final double partnerCleaningFee;
  final double cleaningServiceFee;
  final double cleaningTotal;
  final double serviceFee;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? promotionCode;
  final String? promotionName;

  const PriceQuote({
    required this.quoteId,
    required this.expiresAt,
    required this.currency,
    required this.numberOfNights,
    required this.numberOfGuests,
    required this.extraGuests,
    required this.nightAmount,
    required this.extraGuestAmount,
    required this.stayAmount,
    required this.partnerCleaningFee,
    required this.cleaningServiceFee,
    required this.cleaningTotal,
    required this.serviceFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.promotionCode,
    this.promotionName,
  });

  factory PriceQuote.fromJson(Map<String, dynamic> json) => PriceQuote(
        quoteId: json['quote_id']?.toString() ?? '',
        expiresAt: DateTime.parse(json['expires_at'].toString()),
        currency: json['currency']?.toString() ?? 'EUR',
        numberOfNights: _toInt(json['number_of_nights']),
        numberOfGuests: _toInt(json['number_of_guests']),
        extraGuests: _toInt(json['extra_guests']),
        nightAmount: _toDouble(json['night_amount']),
        extraGuestAmount: _toDouble(json['extra_guest_amount']),
        stayAmount: _toDouble(json['stay_amount']),
        partnerCleaningFee: _toDouble(json['partner_cleaning_fee']),
        cleaningServiceFee: _toDouble(json['cleaning_service_fee']),
        cleaningTotal: _toDouble(json['cleaning_total']),
        serviceFee: _toDouble(json['service_fee']),
        taxAmount: _toDouble(json['tax_amount']),
        discountAmount: _toDouble(json['discount_amount']),
        totalAmount: _toDouble(json['total_amount']),
        promotionCode: json['promotion'] is Map
            ? json['promotion']['code']?.toString()
            : null,
        promotionName: json['promotion'] is Map
            ? json['promotion']['name']?.toString()
            : null,
      );

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}
