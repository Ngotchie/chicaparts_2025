import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OneBookingDetails {
  // Core
  final String id;
  final DateTime firstNight;
  final DateTime lastNight;
  final DateTime createdAt;
  final int nights;
  final String currency;
  final num price; // prix de base
  final num tax; // taxe de séjour
  final num serviceFee; // chicaparts_fees
  final num cleaningFee; // cleaning_fees
  final num total; // total_amount
  final num paidAmount; // pas dans le payload -> 0
  final String paymentStatus; // unpaid|paid|partial...
  final String validationStatus; // pending|confirmed...
  final String? reference;
  final String source;

  // Voyageurs
  final int numAdult;
  final int numChild;

  // Client
  final String guestFullName;
  final String guestEmail;
  final String guestPhone;
  final String? guestAddress;

  // Infos utiles
  final String? wifiSsid;
  final String? wifiPassword;
  final String? floor;
  final String? door;
  final String? parkingType;
  final String? parkingLocation;
  final String? parkingAccess;
  final String? parkingSlot;

  // Règlement & horaires
  final List<String> houseRules;
  final String? checkinTime; // "15:00 – 23:00"
  final String? checkoutTime; // "00:00 – 11:00"
  final String? quietHours; // null ici
  final List<String> specificRules; // ex: "Animaux Interdits", ...

  // Accès / sortie
  final String? accessInstructions;
  final String? checkoutInstructions;

  // Hébergement
  final String accommodationId;
  final String accommodationTitle;
  final String accommodationCity;
  final String? accommodationImage;
  final String capacityLabel; // "3 personnes"
  final String surfaceLabel; // "25 m²"
  final String typeLabel; // "Studio"
  final bool isEntirePlace;
  final bool isAccessible;

  OneBookingDetails({
    required this.id,
    required this.firstNight,
    required this.lastNight,
    required this.createdAt,
    required this.nights,
    required this.currency,
    required this.price,
    required this.tax,
    required this.serviceFee,
    required this.cleaningFee,
    required this.total,
    required this.paidAmount,
    required this.paymentStatus,
    required this.validationStatus,
    required this.reference,
    required this.source,
    required this.numAdult,
    required this.numChild,
    required this.guestFullName,
    required this.guestEmail,
    required this.guestPhone,
    required this.guestAddress,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.floor,
    required this.door,
    required this.parkingType,
    required this.parkingLocation,
    required this.parkingAccess,
    required this.parkingSlot,
    required this.houseRules,
    required this.checkinTime,
    required this.checkoutTime,
    required this.quietHours,
    required this.specificRules,
    required this.accessInstructions,
    required this.checkoutInstructions,
    required this.accommodationId,
    required this.accommodationTitle,
    required this.accommodationCity,
    required this.accommodationImage,
    required this.capacityLabel,
    required this.surfaceLabel,
    required this.typeLabel,
    required this.isEntirePlace,
    required this.isAccessible,
  });

  /// Couleur badge paiement (web-like)
  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'partial':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFFC62828); // unpaid
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Payé';
      case 'partial':
        return 'Partiel';
      default:
        return 'Impayé';
    }
  }

  String get travelersLabel {
    final a = "$numAdult Adulte${numAdult > 1 ? 's' : ''}";
    final c =
        numChild > 0 ? " + $numChild Enfant${numChild > 1 ? 's' : ''}" : "";
    return "$a$c";
  }

  static String? _range(List<dynamic>? arr) {
    if (arr == null || arr.length != 2) return null;
    return "${arr[0]} – ${arr[1]}";
    // ex: ["15:00","23:00"] -> "15:00 – 23:00"
  }

  static List<String> _splitRules(String? raw) {
    if (raw == null) return const [];
    return raw
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'^[-•]\s*'), '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _specificRules(Map<String, dynamic>? hr) {
    if (hr == null) return const [];
    final out = <String>[];
    final pets = hr['pets_allowed'] == true ? null : 'Animaux Interdits';
    final bag =
        hr['authorised_baggage_storage'] == true ? 'Stockage Bagage' : null;
    final long =
        hr['authorised_longterm_stays'] == true ? 'Séjours Longs' : null;
    for (final s in [pets, bag, long]) {
      if (s != null) out.add(s);
    }
    return out;
  }

  factory OneBookingDetails.fromJson(Map<String, dynamic> j,
      {String lang = 'fr'}) {
    final acc = (j['accommodation'] ?? {}) as Map<String, dynamic>;

    String? _asNullableString(dynamic v) => v == null ? null : v.toString();
    List<String> _asStringList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    num _asNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final createdAt = DateTime.parse(j['bookingTime']);
    final first = DateTime.parse(j['firstNight']);
    final last = DateTime.parse(j['lastNight']);
    final nights = last.difference(first).inDays;

    final hr = (acc['house_rules'] ?? {}) as Map<String, dynamic>;

    final accessFr = _asNullableString(acc['access_instruction_fr']);
    final accessEn = _asNullableString(acc['access_instruction_en']);
    final checkoutFr = _asNullableString(acc['checkout_instructions_fr']);
    final checkoutEn = _asNullableString(acc['checkout_instructions_en']);
    final accessTxt =
        lang == 'fr' ? (accessFr ?? accessEn) : (accessEn ?? accessFr);
    final checkoutTxt =
        lang == 'fr' ? (checkoutFr ?? checkoutEn) : (checkoutEn ?? checkoutFr);

    final photos = _asStringList(acc['photos_site']);

    final silent = hr['silent_hours'];
    final quiet =
        (silent is List) ? OneBookingDetails._range(silent.cast()) : null;

    return OneBookingDetails(
      id: "${j['id']}",
      firstNight: first,
      lastNight: last,
      createdAt: createdAt,
      nights: nights,

      currency: j['currency'] ?? 'FCFA',
      price: _asNum(j['price']),
      tax: _asNum(j['tax']),
      serviceFee: _asNum(j['chicaparts_fees']),
      cleaningFee: _asNum(j['cleaning_fees']),
      total: _asNum(j['total_amount']), // <- était string dans ton exemple
      paidAmount: _asNum(j['paid_amount']), // absent => 0
      paymentStatus: j['payment_status'] ?? 'unpaid',
      validationStatus: j['validation_status'] ?? 'pending',
      reference: _asNullableString(j['reference']),
      source: j['seller'] ?? j['referer'] ?? '—',

      numAdult: j['numAdult'] ?? 1,
      numChild: j['numChild'] ?? 0,

      guestFullName:
          "${j['guestTitle'] ?? ''} ${j['guestFirstName'] ?? ''} ${j['guestName'] ?? ''}"
              .trim(),
      guestEmail: j['guestEmail'] ?? '',
      guestPhone: j['guestPhone'] ?? '',
      guestAddress: _asNullableString(j['guestAddress']),

      wifiSsid: _asNullableString(acc['wifi_identifiers']),
      wifiPassword: _asNullableString(acc['wifi_password']),
      floor: _asNullableString(acc['floor_number']),
      door: _asNullableString(acc['door_number']),
      parkingType: _asNullableString(acc['parking_type']),
      parkingLocation:
          _asNullableString(acc['parking_address'] ?? acc['full_address']),
      parkingAccess: _asNullableString(acc['parking_opening_method']),
      parkingSlot: _asNullableString(acc['parking_slot']),

      houseRules: OneBookingDetails._splitRules(
          _asNullableString(acc['rule_of_procedure'])),
      checkinTime:
          OneBookingDetails._range(_asStringList(hr['arrival_time']).cast()),
      checkoutTime:
          OneBookingDetails._range(_asStringList(hr['departure_time']).cast()),
      quietHours: quiet,
      specificRules: OneBookingDetails._specificRules(hr),

      accessInstructions: accessTxt,
      checkoutInstructions: checkoutTxt,

      accommodationId: "${acc['id']}",
      accommodationTitle: acc['external_name'] ?? acc['ref'] ?? 'Hébergement',
      accommodationCity: acc['city'] ?? '',
      accommodationImage: photos.isNotEmpty ? photos.first : null,
      capacityLabel: "${acc['capacity'] ?? '-'} personnes",
      surfaceLabel: "${acc['area'] ?? '-'} m²",
      typeLabel: acc['type_accommodation'] ?? '—',
      isEntirePlace: acc['entire_place'] == true,
      isAccessible: acc['disabled_access'] == true,
    );
  }
}
