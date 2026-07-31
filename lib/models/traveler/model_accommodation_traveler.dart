import 'package:intl/intl.dart';

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
  final String thumbnailUrl;
  final double? latitude;
  final double? longitude;

  Stay(
      {required this.id,
      required this.title,
      required this.location,
      required this.price,
      required this.currency,
      required this.imageUrl,
      required this.thumbnailUrl,
      this.latitude,
      this.longitude});

  // Convertir JSON en objet Stay
  factory Stay.fromJson(Map<String, dynamic> json) {
    return Stay(
      id: json['id'],
      title: json['external_name'],
      location: json['full_address'] ?? '',
      price: json.containsKey('day_price') && json['day_price'] != null
          ? json['day_price'].toDouble()
          : 0.0, // S'assurer que c'est un double
      currency: _normalizeCurrency(json['currency']),
      imageUrl: _firstPhoto(json),
      thumbnailUrl: _thumbnail(json),
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lon']),
    );
  }

  bool get hasLocation => latitude != null && longitude != null;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _firstPhoto(Map<String, dynamic> json) {
    final photos = json['photos_site'];
    if (photos is List && photos.isNotEmpty) {
      return photos.first?.toString() ?? '';
    }
    return '';
  }

  static String _thumbnail(Map<String, dynamic> json) {
    final candidates = [
      json['thumbnail'],
      json['thumbnail_url'],
      json['cover_thumbnail'],
      json['cover_photo'],
      json['image_thumb'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    return _firstPhoto(json);
  }

  static String _normalizeCurrency(dynamic currency) {
    final value = currency?.toString().trim().toUpperCase() ?? '';
    if (value == 'FCFA' || value == 'CFA' || value == 'XOF') return 'XAF';
    return value.isEmpty ? 'EUR' : value;
  }
}

class AccommodationFilter {
  final double? lon;
  final double? lat;
  final String? city;
  final String? typeAcc;
  final bool? wifi;
  final bool? hasParking;
  final bool? disabledAccess;
  final bool? hasElevator;
  final bool? entirePlace;
  final int? nbAdult;
  final int? nbChild;
  final int? nbBed;
  final int? nbBedrooms;
  final DateTime? startDate;
  final DateTime? endDate;

  AccommodationFilter({
    this.lon,
    this.lat,
    this.city,
    this.typeAcc,
    this.wifi,
    this.hasParking,
    this.disabledAccess,
    this.hasElevator,
    this.entirePlace,
    this.nbAdult,
    this.nbChild,
    this.nbBed,
    this.nbBedrooms,
    this.startDate,
    this.endDate,
  });

  bool get hasActiveFilters {
    return (city != null && city!.trim().isNotEmpty) ||
        (lon != null && lat != null) ||
        (typeAcc != null && typeAcc!.trim().isNotEmpty) ||
        wifi == true ||
        hasParking == true ||
        disabledAccess == true ||
        hasElevator == true ||
        entirePlace == true ||
        (nbAdult != null && nbAdult! > 0) ||
        (nbChild != null && nbChild! > 0) ||
        (nbBed != null && nbBed! > 0) ||
        (nbBedrooms != null && nbBedrooms! > 0) ||
        (startDate != null && endDate != null);
  }

  Map<String, dynamic> toJson() {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return {
      if (lon != null && lat != null) "lon": lon,
      if (lon != null && lat != null) "lat": lat,
      if (city != null && city!.trim().isNotEmpty) "city": city!.trim(),
      if (typeAcc != null && typeAcc!.trim().isNotEmpty) "type_acc": typeAcc,
      if (wifi == true) "wifi_identifiers": true,
      if (hasParking == true) "has_parking": true,
      if (disabledAccess == true) "disabled_access": true,
      if (hasElevator == true) "has_elevator": true,
      if (entirePlace == true) "entire_place": true,
      if (nbAdult != null && nbAdult! > 0) "nb_adult": nbAdult,
      if (nbChild != null && nbChild! > 0) "nb_child": nbChild,
      if (nbBed != null && nbBed! > 0) "beds": nbBed,
      if (nbBedrooms != null && nbBedrooms! > 0) "bedrooms": nbBedrooms,
      if (startDate != null) "start_date": dateFormatter.format(startDate!),
      if (endDate != null) "end_date": dateFormatter.format(endDate!),
    };
  }
}
