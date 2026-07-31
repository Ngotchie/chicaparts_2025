import 'dart:convert';

import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SocialAuthResult {
  final String token;
  final User user;
  final Map<String, dynamic> raw;

  const SocialAuthResult({
    required this.token,
    required this.user,
    required this.raw,
  });
}

class SocialAuthService {
  SocialAuthService({ApiUrl? apiUrl}) : _apiUrl = apiUrl ?? ApiUrl();

  final ApiUrl _apiUrl;

  Future<String> getRedirectUrl(String driver) async {
    final response = await http.get(
      Uri.parse('${_apiUrl.getChicapartsUrl()}oauth/connect/$driver?platform=mobile'),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': _apiUrl.getKey(),
      },
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      throw Exception(body['error']?.toString() ?? body['message']?.toString() ?? response.body);
    }

    final redirectUrl = body['redirect_url']?.toString();
    if (redirectUrl == null || redirectUrl.isEmpty) {
      throw Exception('OAuth redirect URL missing');
    }

    return redirectUrl;
  }

  Future<SocialAuthResult> completeWithToken(String token) async {
    final response = await http.get(
      Uri.parse('${_apiUrl.getChicapartsUrl()}auth/me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Authorization': _apiUrl.getKey(),
      },
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      throw Exception(body['error']?.toString() ?? body['message']?.toString() ?? response.body);
    }

    final userJson = body['user'];
    if (userJson is! Map) {
      throw Exception('OAuth user missing');
    }

    final user = User(
      _asInt(userJson['id']),
      _displayName(userJson),
      (userJson['email'] ?? '').toString(),
      'traveler',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setString('email', user.email);
    await prefs.setString('auth_token', token);
    await prefs.setString('user_raw_traveler', jsonEncode(body));

    return SocialAuthResult(token: token, user: user, raw: body);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _displayName(Map userJson) {
    final directName = userJson['name']?.toString().trim();
    if (directName != null && directName.isNotEmpty) return directName;

    final firstName = userJson['first_name']?.toString().trim() ?? '';
    final lastName = userJson['last_name']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : (userJson['email'] ?? '').toString();
  }
}
