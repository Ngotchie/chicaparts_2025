class Review {
  final int id;
  final int customerId;
  final int accommodationId;
  final String reviewer;
  final String comment;
  final int confort;
  final int staf;
  final int facilities;
  final int cleanliness;
  final num? score;

  final AccommodationLite? accommodation;

  Review(
      {required this.id,
      required this.customerId,
      required this.accommodationId,
      required this.reviewer,
      required this.comment,
      required this.confort,
      required this.staf,
      required this.facilities,
      required this.cleanliness,
      required this.score,
      required this.accommodation});

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
        customerId: j['user_id'] ?? 0,
        accommodationId: j['accommodation_id'] ?? 0,
        reviewer: j['reviewer'] ?? '',
        comment: j['comment'] ?? '',
        confort: j['confort'] ?? 0,
        staf: j['staf'] ?? 0,
        facilities: j['facilities'] ?? 0,
        cleanliness: j['cleanliness'] ?? 0,
        score: (j['score'] is num)
            ? j['score']
            : num.tryParse("${j['score'] ?? 0}") ?? 0,
        accommodation: j["accommodation"] != null
            ? AccommodationLite.fromJson(j["accommodation"])
            : null,
      );

  Map<String, dynamic> toPayload() => {
        "user_id": customerId,
        "accommodation_id": accommodationId,
        "reviewer": reviewer,
        "comment": comment,
        "confort": confort,
        "staf": staf,
        "facilities": facilities,
        "cleanliness": cleanliness,
      };

  @override
  String toString() {
    return 'Review(id: $id, customer: $customerId, accommodation: $accommodationId, '
        'reviewer: $reviewer, confort: $confort, staf: $staf, '
        'facilities: $facilities, cleanliness: $cleanliness, comment: $comment, score: $score)';
  }
}

class AccommodationLite {
  final int id;
  final String name;
  final String city;
  final String? image;

  AccommodationLite({
    required this.id,
    required this.name,
    required this.city,
    this.image,
  });

  factory AccommodationLite.fromJson(Map<String, dynamic> j) {
    final photos = j["photos_site"] as List?;
    final firstPhoto =
        (photos != null && photos.isNotEmpty) ? photos[0]["url"] : null;

    return AccommodationLite(
      id: j["id"],
      name: j["external_name"] ?? j["ref"] ?? "Hébergement",
      city: j["city"] ?? "",
      image: firstPhoto,
    );
  }
}
