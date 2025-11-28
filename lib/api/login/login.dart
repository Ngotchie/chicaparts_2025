import 'dart:convert';
import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  AuthService({this.baseUrl = 'https://intranet.chic-aparts.com/chicaparts'});

  /// Appelle le backend Laravel: POST /chicaparts/reset-password
  /// Body: { "email": "..." }
  /// Réponses possibles:
  /// 200: { "message": "Email de reinitialisation envoyé" }
  /// 401: { "error": "..." }
  /// 422: { "errors": { "email": ["..."] } } (validation Laravel)
  Future<String> requestPasswordReset(String email) async {
    final uri = Uri.parse('$baseUrl/auth/reset-password');
    ApiUrl url = ApiUrl();
    String apiKey = url.getKey();
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));

    final body =
        res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};

    if (res.statusCode == 200) {
      return (body['message']?.toString() ??
          'Email de réinitialisation envoyé');
    }

    if (res.statusCode == 401) {
      throw Exception(body['error']?.toString() ?? 'Requête non autorisée.');
    }

    if (res.statusCode == 422) {
      // Erreurs de validation Laravel
      final errors = body['errors'];
      if (errors is Map &&
          errors['email'] is List &&
          errors['email'].isNotEmpty) {
        throw Exception(errors['email'][0].toString());
      }
      throw Exception('Erreur de validation.');
    }

    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}
