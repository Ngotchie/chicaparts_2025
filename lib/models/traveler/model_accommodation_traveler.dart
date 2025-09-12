class Destination {
  final String name;
  final String imageUrl;
  final int accommodations;

  Destination(
      {required this.name,
      required this.imageUrl,
      required this.accommodations});

  // Convertir un JSON en objet Destination
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['city'],
      imageUrl: json['image'],
      accommodations: json['nbr_accommodation'],
    );
  }
}

class Stay {
  final int id;
  final String title;
  final String location;
  final double price;
  final String currency;
  final String imageUrl;

  Stay(
      {required this.id,
      required this.title,
      required this.location,
      required this.price,
      required this.currency,
      required this.imageUrl});

  // Convertir JSON en objet Stay
  factory Stay.fromJson(Map<String, dynamic> json) {
    return Stay(
      id: json['id'],
      title: json['external_name'],
      location: json['full_address'] ?? '',
      price: json.containsKey('day_price') && json['day_price'] != null
          ? json['day_price'].toDouble()
          : 0.0, // S'assurer que c'est un double
      currency: json['currency'] ?? 'EUR',
      imageUrl: (json['photos_site'] != null && json['photos_site'].isNotEmpty)
          ? json['photos_site'][0]
          : '',
    );
  }
}

class AccommodationFilter {
  final double lon;
  final double lat;
  final String? typeAcc;
  final bool? wifi;
  final bool? disabledAccess;
  final bool? hasElevator;
  final bool? entirePlace;
  final int? nbAdult;
  final int? nbChild;
  final int? nbBed;
  final DateTime? startDate;
  final DateTime? endDate;

  AccommodationFilter({
    required this.lon,
    required this.lat,
    this.typeAcc,
    this.wifi,
    this.disabledAccess,
    this.hasElevator,
    this.entirePlace,
    this.nbAdult,
    this.nbChild,
    this.nbBed,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      "lon": lon,
      "lat": lat,
      if (typeAcc != null) "type_acc": typeAcc,
      if (wifi != null) "wifi_identifiers": wifi,
      if (disabledAccess != null) "disabled_access": disabledAccess,
      if (hasElevator != null) "has_elevator": hasElevator,
      if (entirePlace != null) "entire_place": entirePlace,
      if (nbAdult != null) "nb_adult": nbAdult,
      if (nbChild != null) "nb_child": nbChild,
      if (nbBed != null) "nb_bed": nbBed,
      if (startDate != null) "start_date": startDate,
      if (endDate != null) "end_date": endDate
    };
  }
}
