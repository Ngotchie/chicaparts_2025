import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _key = 'favorite_stays';

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = await getFavorites();
    if (!favs.contains(id)) {
      favs.add(id);
      prefs.setStringList(_key, favs);
    }
  }

  static Future<void> removeFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = await getFavorites();
    favs.remove(id);
    prefs.setStringList(_key, favs);
  }

  static Future<bool> isFavorite(String id) async {
    final favs = await getFavorites();
    return favs.contains(id);
  }
}

class UserProfile {
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String phone;
  final String city;
  final String? state;
  final String? zipCode;
  final int bookingCount;
  final int reviewCount;
  final int countryId;
  final String status;
  final String entityType;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.phone,
    required this.city,
    this.state,
    this.zipCode,
    required this.bookingCount,
    required this.reviewCount,
    required this.countryId,
    required this.status,
    required this.entityType,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phone: json['mobile_phone_number'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      zipCode: json['postcode'],
      bookingCount: json['_stats']?['bookings'] ?? 0,
      reviewCount: json['_stats']?['reviews'] ?? 0,
      countryId: json['country_id'],
      status: json['status'],
      entityType: json['entity_type'],
    );
  }
}
