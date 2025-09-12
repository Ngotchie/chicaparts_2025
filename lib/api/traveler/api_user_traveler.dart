import 'dart:convert';

import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;

class ApiUserTraveler {
  Future<dynamic> UserRegister(body) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();

    try {
      final response = await http.post(Uri.parse('${apiUrl}auth/register'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode(body));

      return response;
    } catch (e) {
      print("Erreur API: $e");
    }
  }
}
