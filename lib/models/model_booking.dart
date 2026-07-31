import 'package:flutter/material.dart';

class Booking {
  int id;
  int bookId;
  String accommodation;
  String lastNight;
  String firstNight;
  String bookedAt;
  String guestFirstName;
  String guestName;
  String referer;
  int status;
  num price;
  String currency;
  String arrivalTime;
  int adult;
  int child;
  String arriveTime;
  String validationStatus;
  Text note;
  int roomId;
  int propId;
  String img;
  String city;
  bool hasTips;

  dynamic multiplier;

  Booking(
    this.id,
    this.bookId,
    this.accommodation,
    this.lastNight,
    this.firstNight,
    this.bookedAt,
    this.guestFirstName,
    this.guestName,
    this.referer,
    this.status,
    this.price,
    this.currency,
    this.arrivalTime,
    this.adult,
    this.child,
    this.arriveTime,
    this.validationStatus,
    this.note,
    this.roomId,
    this.propId,
    this.img,
    this.city,
    this.hasTips,
    this.multiplier,
  );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) => value?.toString() ?? '';

  static String _asDateString(dynamic value) {
    final text = _asString(value);
    return DateTime.tryParse(text) == null ? '1970-01-01' : text;
  }

  static Text _asText(dynamic value) => Text(_asString(value));

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final accommodation = json['accommodation'];
    final accommodationMap =
        accommodation is Map<String, dynamic> ? accommodation : null;
    final photos = accommodationMap?['photos_site'];
    final image = photos is List && photos.isNotEmpty ? photos.first : null;

    return Booking(
      _asInt(json['id']),
      _asInt(json['bookId']),
      _asString(accommodationMap?['external_name']),
      _asDateString(json['lastNight']),
      _asDateString(json['firstNight']),
      _asDateString(json['bookedAt']),
      _asString(json['guestFirstName']),
      _asString(json['guestName']),
      _asString(json['referer']),
      _asInt(json['status']),
      _asNum(json['price']),
      _asString(json['currency']),
      _asString(json['arrivalTime']),
      _asInt(json['adult']),
      _asInt(json['child']),
      _asString(json['arriveTime']),
      _asString(json['validation_status']),
      _asText(json['notes']),
      _asInt(json['roomId']),
      _asInt(json['propId']),
      _asString(image),
      _asString(accommodationMap?['city']),
      _asBool(json['has_tips']),
      json['multiplier'] ?? '', // ✅ can be null or dynamic
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'accommodation': accommodation,
      'lastNight': lastNight,
      'firstNight': firstNight,
      'bookedAt': bookedAt,
      'guestFirstName': guestFirstName,
      'guestName': guestName,
      'referer': referer,
      'status': status,
      'price': price,
      'currency': currency,
      'arrivalTime': arrivalTime,
      'adult': adult,
      'child': child,
      'arriveTime': arriveTime,
      'validationStatus': validationStatus,
      'note': note,
      'roomId': roomId,
      'propId': propId,
      'img': img,
      'city': city,
      'hasTips': hasTips,
      'multiplier': multiplier,
    };
  }

  @override
  String toString() => 'Booking${toJson()}';
}

class OneBooking {
  int id;
  String referer;
  int bookId;
  int propId;
  int roomId;
  String bookedAt;
  String firstNight;
  String lastNight;
  int adult;
  int child;
  String arriveTime;

  String title;
  String guestFirstName;
  String guestName;
  String email;
  String phone;
  String mobile;
  String fax;
  String compagny;
  String address;
  String city;
  String state;
  String postCode;
  String country;
  Text comment;
  Text note;

  num price;
  num deposit;
  num tax;
  num commission;
  num cleaningFees;
  num transactionFees;
  num bookingFees;
  String currency;
  Text rateDescription;
  int currencyId;
  String validationStatus;

  OneBooking(
      this.id,
      this.referer,
      this.bookId,
      this.propId,
      this.roomId,
      this.bookedAt,
      this.firstNight,
      this.lastNight,
      this.adult,
      this.child,
      this.arriveTime,
      this.title,
      this.guestFirstName,
      this.guestName,
      this.email,
      this.phone,
      this.mobile,
      this.fax,
      this.compagny,
      this.address,
      this.city,
      this.state,
      this.postCode,
      this.country,
      this.comment,
      this.note,
      this.price,
      this.deposit,
      this.tax,
      this.commission,
      this.cleaningFees,
      this.transactionFees,
      this.bookingFees,
      this.currency,
      this.rateDescription,
      this.currencyId,
      this.validationStatus);
}
