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
  final int favorisCount;
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
    required this.favorisCount,
    required this.countryId,
    required this.status,
    required this.entityType,
  });

  // --- helpers robustes ---
  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  static List<String> _asStringList(dynamic v) {
    if (v is List) return v.map((e) => '$e').toList();
    if (v is String && v.trim().isNotEmpty) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final stats = (json['_stats'] is Map) ? json['_stats'] as Map : const {};
    // gérer les deux orthographes favorites/favourites
    final favRaw = json['favourites_hostings'] ?? json['favorites_hostings'];
    final favList = _asStringList(favRaw);

    return UserProfile(
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['mobile_phone_number'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] as String?),
      zipCode: (json['postcode'] as String?),
      bookingCount: _asInt(stats['bookings']),
      reviewCount: _asInt(stats['reviews']),
      favorisCount: favList.length,
      countryId: _asInt(json['country_id']),
      status: (json['status'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
    );
  }
}
