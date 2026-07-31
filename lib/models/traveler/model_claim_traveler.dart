class TravelerClaim {
  final int id;
  final String ref;
  final int bookingId;
  final int accommodationId;
  final String type;
  final String description;
  final String desiredSolution;
  final String status;
  final String incidentDate;
  final String createdAt;
  final String updatedAt;
  final String adminNotes;
  final num compensationAmount;
  final String compensationCurrency;
  final String accommodationName;
  final String accommodationCity;
  final String accommodationAddress;
  final String accommodationPicture;
  final List<ClaimAttachment> attachments;

  const TravelerClaim({
    required this.id,
    required this.ref,
    required this.bookingId,
    required this.accommodationId,
    required this.type,
    required this.description,
    required this.desiredSolution,
    required this.status,
    required this.incidentDate,
    required this.createdAt,
    required this.updatedAt,
    required this.adminNotes,
    required this.compensationAmount,
    required this.compensationCurrency,
    required this.accommodationName,
    required this.accommodationCity,
    required this.accommodationAddress,
    required this.accommodationPicture,
    required this.attachments,
  });

  factory TravelerClaim.fromJson(Map<String, dynamic> json) {
    final accommodation = json['accommodation'] is Map
        ? Map<String, dynamic>.from(json['accommodation'] as Map)
        : <String, dynamic>{};
    final attachments = json['attachments'] is List
        ? (json['attachments'] as List)
            .whereType<Map>()
            .map((item) =>
                ClaimAttachment.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <ClaimAttachment>[];

    return TravelerClaim(
      id: _asInt(json['id']),
      ref: '${json['ref'] ?? ''}',
      bookingId: _asInt(json['booking_id']),
      accommodationId: _asInt(json['accommodation_id']),
      type: '${json['type'] ?? ''}',
      description: '${json['description'] ?? ''}',
      desiredSolution: '${json['desired_solution'] ?? ''}',
      status: '${json['status'] ?? ''}',
      incidentDate: '${json['incident_date'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      updatedAt: '${json['updated_at'] ?? ''}',
      adminNotes: '${json['admin_notes'] ?? ''}',
      compensationAmount: _asNum(json['compensation_amount']),
      compensationCurrency: '${json['compensation_currency'] ?? ''}',
      accommodationName:
          '${accommodation['external_name'] ?? accommodation['internal_name'] ?? ''}',
      accommodationCity: '${accommodation['city'] ?? ''}',
      accommodationAddress: '${accommodation['address'] ?? ''}',
      accommodationPicture: '${accommodation['picture'] ?? ''}',
      attachments: attachments,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}') ?? 0;
  }
}

class ClaimAttachment {
  final String name;
  final String path;
  final String url;

  const ClaimAttachment({
    required this.name,
    required this.path,
    required this.url,
  });

  factory ClaimAttachment.fromJson(Map<String, dynamic> json) {
    return ClaimAttachment(
      name: '${json['name'] ?? ''}',
      path: '${json['path'] ?? ''}',
      url: '${json['url'] ?? ''}',
    );
  }
}
