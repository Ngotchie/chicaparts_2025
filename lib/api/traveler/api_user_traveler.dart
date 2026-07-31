import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/model_claim_traveler.dart';
import 'package:chicaparts_partner/models/traveler/model_invoice_traveler.dart';
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

  Future<List<TravelerTransaction>> getUserTransactions(
    User user, [
    String? paymentType,
    String? status,
  ]) async {
    final url = ApiUrl();
    final query = <String, String>{
      'user_id': '${user.id}',
      if (paymentType != null) 'payment_type': paymentType,
      if (status != null) 'status': status,
    };
    final response = await http.get(
      Uri.parse('${url.getChicapartsUrl()}payments').replace(
        queryParameters: query,
      ),
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

  Future<List<TravelerInvoice>> getUserInvoices(
    User user, {
    String? status,
    String? type,
  }) async {
    final url = ApiUrl();
    final query = <String, String>{
      'user_id': '${user.id}',
      if (status != null && status != 'all') 'status': status,
      if (type != null && type != 'all') 'type': type,
    };
    final response = await http.get(
      Uri.parse('${url.getChicapartsUrl()}invoices').replace(
        queryParameters: query,
      ),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de recuperation des factures');
    }

    final body = jsonDecode(response.body);
    final List data =
        (body is Map && body['data'] is List) ? body['data'] : const [];

    return data
        .map((e) => TravelerInvoice.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<TravelerInvoiceStats> getUserInvoiceStats(User user) async {
    final url = ApiUrl();
    final response = await http.get(
      Uri.parse('${url.getChicapartsUrl()}invoices/stats').replace(
        queryParameters: {'user_id': '${user.id}'},
      ),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de recuperation des statistiques de factures');
    }

    return TravelerInvoiceStats.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<List<TravelerClaim>> getUserClaims(User user) async {
    final url = ApiUrl();
    final response = await http.get(
      Uri.parse('${url.getChicapartsUrl()}claims?auth_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de récupération des réclamations');
    }

    final body = jsonDecode(response.body);
    final List data =
        (body is Map && body['data'] is List) ? body['data'] : const [];

    return data
        .map((e) => TravelerClaim.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<TravelerClaim> createClaim(
    User user,
    Map<String, dynamic> payload,
  ) async {
    final url = ApiUrl();
    final response = await http.post(
      Uri.parse('${url.getChicapartsUrl()}claims?auth_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': url.getKey(),
      },
      body: jsonEncode({
        ...payload,
        'auth_id': user.id,
        'user_id': user.id,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur de création de la réclamation');
    }

    final body = jsonDecode(response.body);
    final data = (body is Map && body['data'] is Map) ? body['data'] : body;
    return TravelerClaim.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<TravelerClaim> updateClaim(
    User user,
    int claimId,
    Map<String, dynamic> payload,
  ) async {
    final url = ApiUrl();
    final response = await http.put(
      Uri.parse('${url.getChicapartsUrl()}claims/$claimId?auth_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': url.getKey(),
      },
      body: jsonEncode({
        ...payload,
        'auth_id': user.id,
        'user_id': user.id,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de modification de la réclamation');
    }

    final body = jsonDecode(response.body);
    final data = (body is Map && body['data'] is Map) ? body['data'] : body;
    return TravelerClaim.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteClaim(User user, int claimId) async {
    final url = ApiUrl();
    final response = await http.delete(
      Uri.parse('${url.getChicapartsUrl()}claims/$claimId?auth_id=${user.id}'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': url.getKey(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur de suppression de la réclamation');
    }
  }
}
