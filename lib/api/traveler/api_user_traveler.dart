import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/model_transaction_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
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

  Future<http.Response> deleteAccount(User user) async {
    final url = ApiUrl();

    return http.delete(
      Uri.parse('${url.getChicapartsUrl()}auth/me?user_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );
  }

  Future<List<TravelerTransaction>> getUserTransactions(User user) async {
    final url = ApiUrl();
    final response = await http.get(
      Uri.parse('${url.getChicapartsUrl()}payments?user_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de récupération des transactions');
    }

    final body = jsonDecode(response.body);
    final List data =
        (body is Map && body['data'] is List) ? body['data'] : const [];

    return data
        .map((e) => TravelerTransaction.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }
}
