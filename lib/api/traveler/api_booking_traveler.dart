import 'dart:convert';

import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_details.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiBooking {
  Future<Map<DateTime, double>> fetchAvailabilities(accommodationId) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();

    final response = await http.get(
        Uri.parse('${apiUrl}properties/availabilities/$accommodationId'),
        headers: {
          'Accept': 'application/json',
          'X-Authorization': apiKey,
        });

    if (response.statusCode == 200) {
      Map<DateTime, double> availabilityData = {};
      dynamic jsonData = jsonDecode(response.body);
      jsonData = jsonData["data"];

      for (var item in jsonData) {
        DateTime date = DateTime.parse(item["day"]);
        bool available = item["available"];

        if (available) {
          Map<String, dynamic> rates = item["rate"][""];

          double price = extractMaxPrice(rates);

          availabilityData[date] = price;
        }
      }
      return availabilityData;
    } else {
      throw Exception("Failed to load availabilities");
    }
  }

  double extractMaxPrice(Map<String, dynamic> data) {
    if (!data.containsKey("prices") || data["prices"] is! List) {
      print("⚠️ Erreur: Pas de prix disponibles.");
      return 0.0;
    }

    List<dynamic> pricesList = data["prices"];

    // 🔥 Trouver le prix max basé sur le nombre de personnes `up`
    var bestPriceEntry =
        pricesList.reduce((a, b) => (a["up"] ?? 0) > (b["up"] ?? 0) ? a : b);

    double maxPrice = (bestPriceEntry["price"] is List)
        ? 0.0
        : (bestPriceEntry["price"] ?? 0).toDouble();
    return maxPrice;
  }

  Future<dynamic> submitReservation({
    required BookingDetails booking,
    required BillingInfo billing,
    required arrivalTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    User? user;

    if (userJson != null) {
      final currentUser = User.fromJson(jsonDecode(userJson));
      user = currentUser;
    }
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();

    final uri = Uri.parse('${apiUrl}properties/booking');

    final Map<String, dynamic> body = {
      ...booking.toJson(),
      ...billing.toJson(),
      'guestArrivalTime': arrivalTime,
      'user_id': userJson != null ? user?.id : null
    };

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Réservation créée !");
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      saveReservationLocally(data);
      return data;
    } else {
      throw Exception("❌ Erreur réservation : ${response.statusCode}");
    }
  }

  Future<void> saveReservationLocally(dynamic reservationData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("reservation_data", jsonEncode(reservationData));
  }

  Future<void> sendChangeDateRequest({
    required int bookingId,
    required String customerName,
    required DateTime oldStart,
    required DateTime oldEnd,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();

    final body = {
      "booking_id": bookingId,
      "customer_name": customerName,
      "old_first_night": oldStart.toIso8601String(),
      "old_last_night": oldEnd.toIso8601String(),
      "new_first_night": newStart.toIso8601String(),
      "new_last_night": newEnd.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('${apiUrl}booking/change-date-request'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erreur envoi demande (${response.statusCode})");
    }
  }

  Future<List<Booking>> getUserReservations(User user) async {
    ApiUrl url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();

    final response = await http.get(
      Uri.parse('${apiUrl}me/bookings?user_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> reservationList = decoded['data'];
      return reservationList.map((data) => Booking.fromJson(data)).toList();
    } else {
      throw Exception('Erreur de récupération des réservations');
    }
  }

  Future<OneBookingDetails> getOneBooking(id, User user) async {
    final url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();
    final uri = Uri.parse('${apiUrl}booking/$id?user_id=${user.id}');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      },
    );

    // debugPrint('➡️ GET $uri (${response.statusCode})');
    // debugPrint(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OneBookingDetails.fromJson(data['data']);
    } else {
      debugPrint('❌ Erreur ${response.statusCode}: ${response.body}');
      throw Exception('Erreur lors de la récupération du booking (#$id)');
    }
  }

  Future<void> requestCheckoutChange({
    required int bookingId,
    required User user,
    required DateTime lastNight,
    String? reason,
  }) async {
    final url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();
    final response = await http.post(
      Uri.parse('${apiUrl}booking/request-date-change?user_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode({
        'booking_id': bookingId,
        'lastNight': lastNight.toIso8601String(),
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur demande modification réservation (${response.statusCode})',
      );
    }
  }

  Future<UserProfile> fetchUserProfile(User user) async {
    ApiUrl url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();

    final response = await http.get(
      Uri.parse('${apiUrl}auth/me?user_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return UserProfile.fromJson(jsonBody);
    } else if (response.statusCode == 403) {
      throw Exception("⛔ Token invalide");
    } else {
      throw Exception("❌ Erreur serveur : ${response.statusCode}");
    }
  }

  /// -----------------------------------------------------------------------
  /// 🔹 STEP 1 : demander un code OTP pour synchroniser les réservations
  ///
  Future<Map<String, dynamic>> requestSyncOtp({
    required User user,
    required String email,
  }) async {
    final urlConfig = ApiUrl();
    final apiUrl = urlConfig.getChicapartsUrl();
    final apiKey = urlConfig.getKey();

    final url = Uri.parse('${apiUrl}booking/sync');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode({
        "step": 1,
        "email": email,
        //"code": "",
        "user_id": user.id, // 🔐 Auth backend
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 404) {
      final json = jsonDecode(response.body);
      throw Exception(
          json['error'] ?? "Aucune réservation trouvée ou déjà synchronisée.");
    }
    throw Exception("❌ Erreur serveur (Step 1) : ${response.statusCode}");
  }

  /// -----------------------------------------------------------------------
  /// 🔹 STEP 2 : envoyer le code OTP et lancer la synchronisation
  /// -----------------------------------------------------------------------
  Future<Map<String, dynamic>> confirmSync({
    required User user,
    required String email,
    required String code,
  }) async {
    final urlConfig = ApiUrl();
    final apiUrl = urlConfig.getChicapartsUrl();
    final apiKey = urlConfig.getKey();

    final url = Uri.parse('${apiUrl}booking/sync');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode({
        "step": 2,
        "email": email,
        "code": code,
        "user_id": user.id, // 🔐 Auth backend
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("❌ Erreur serveur (Step 2) : ${response.statusCode}");
  }

  Future<Map<String, dynamic>> sendTip({
    required int bookingId,
    required int transactionId,
    required int amount,
    required String currency,
    required int? percentage,
    required int userId,
    int? accommodationId,
    String? message,
  }) async {
    final urlConfig = ApiUrl();
    final apiUrl = urlConfig.getChicapartsUrl();
    final apiKey = urlConfig.getKey();

    final url = Uri.parse('${apiUrl}payments/tip');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': apiKey,
      },
      body: jsonEncode({
        "booking_id": bookingId,
        "transaction_id": transactionId,
        "accommodation_id": accommodationId,
        "currency": currency,
        "amount": amount,
        "percentage_of_booking": percentage,
        "message": message,
        "user_id": userId, // ton backend récupère via token
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erreur Tip: ${response.statusCode} ${response.body}");
  }
}

class ApiReview {
  final _api = ApiUrl();

  Map<String, String> _headersJson() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': _api.getKey(),
      };

  Future<Review?> getUserReviewForAccommodation({
    required int customerId,
    required int accommodationId,
  }) async {
    // On va utiliser /review/user puis filtrer côté app (simple & robuste)
    final url =
        Uri.parse('${_api.getChicapartsUrl()}review/user?user_id=$customerId');
    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      'X-Authorization': _api.getKey(),
    });
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);

    // Attendu: body["data"] = List
    final List data =
        (body is Map && body['data'] is List) ? body['data'] : const [];
    final match = data.cast<Map>().firstWhere(
          (e) => e['accommodation_id'] == accommodationId,
          orElse: () => {},
        );
    if (match.isEmpty) return null;
    return Review.fromJson(match.cast<String, dynamic>());
  }

  Future<Review> createReview(Review r) async {
    final url =
        Uri.parse('${_api.getChicapartsUrl()}review?user_id=${r.customerId}');
    final res = await http.post(url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Authorization': _api.getKey(),
        },
        body: jsonEncode(r.toPayload()));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erreur création avis (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    final data = (body is Map && body['data'] is Map) ? body['data'] : body;
    return Review.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Review> updateReview(int id, Review r) async {
    final url = Uri.parse('${_api.getChicapartsUrl()}review/$id');
    final res = await http.put(url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Authorization': _api.getKey(),
        },
        body: jsonEncode(r.toPayload()));

    if (res.statusCode != 200) {
      throw Exception('Erreur mise à jour avis (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    final data = (body is Map && body['data'] is Map) ? body['data'] : body;
    return Review.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteReview(int id) async {
    final url = Uri.parse('${_api.getChicapartsUrl()}review/$id');
    final res = await http.delete(url, headers: {
      'Accept': 'application/json',
      'X-Authorization': _api.getKey(),
    });
    if (res.statusCode != 200) {
      throw Exception('Erreur suppression avis (${res.statusCode})');
    }
  }

  Future<List<Review>> getUserReviews(int userId) async {
    ApiUrl url = ApiUrl();
    final apiUrl = url.getChicapartsUrl();
    final apiKey = url.getKey();

    final response = await http.get(
      Uri.parse('${apiUrl}me/reviews?user_id=$userId'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list = decoded['data'];
      return list.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception('Erreur de récupération des avis');
    }
  }
}
