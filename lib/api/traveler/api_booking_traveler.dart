import 'dart:convert';

import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
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
      return UserProfile.fromJson(jsonBody['user']);
    } else if (response.statusCode == 403) {
      throw Exception("⛔ Token invalide");
    } else {
      throw Exception("❌ Erreur serveur : ${response.statusCode}");
    }
  }
}
