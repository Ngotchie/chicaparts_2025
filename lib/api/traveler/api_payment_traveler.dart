import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chicaparts_partner/services/api.dart';

class ApiPayment {
  Future<dynamic> checkoutTransaction({
    required String service,
    required double amount,
    required String currency,
    required String name,
    required String customerEmail,
    required int bookingId,
  }) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl(); // Base URL de votre API
    String apiKey = url.getKey(); // Clé d'authentification si nécessaire

    String endpoint =
        "${apiUrl}transactions/checkout/$service/flutter"; // URL complète de l'API

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Authorization':
          apiKey, // Ajoutez cette ligne si l'API exige une authentification
    };

    Map<String, dynamic> body = service == "stripe"
        ? {
            "amount": amount,
            "currency": currency,
            "name": name,
            "customer_email": customerEmail,
            "booking_id": bookingId,
          }
        : {
            "amount": amount,
            "currency": currency,
            "booking_id": bookingId,
            "customer_email": customerEmail,
          };

    try {
      print(body);
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            "Erreur lors du paiement: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Une erreur s'est produite: $e");
    }
  }

  Future<String> checkPaymentStatus(String service, int bookingId) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl(); // Base URL de votre API
    String apiKey = url.getKey(); // Clé d'authentification si nécessaire

    String endpoint = "${apiUrl}transactions/check/";

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Authorization': apiKey,
        },
        body: jsonEncode({"payment_service": service, "booking_id": bookingId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String status = data['status']; // Ex: "success", "pending", "failed"
        return status;
      } else {
        throw Exception("Failed to check payment status.");
      }
    } catch (e) {
      return ("Error checking payment status: $e");
    }
  }
}
