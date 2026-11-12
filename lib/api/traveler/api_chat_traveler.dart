import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/chat_message.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  const ChatApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ChatMessagesPage {
  final List<ChatMessage> messages;
  final int currentPage;
  final int lastPage;

  const ChatMessagesPage({
    required this.messages,
    required this.currentPage,
    required this.lastPage,
  });
}

class ApiChatTraveler {
  ApiChatTraveler({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final ApiUrl _api = ApiUrl();

  Future<Map<String, String>> _headers({bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('user');
    int? userId;

    if (userJson != null) {
      final decoded = jsonDecode(userJson);
      if (decoded is Map) {
        userId = decoded['id'] is int
            ? decoded['id'] as int
            : int.tryParse('${decoded['id']}');
      }
    }

    return {
      'Accept': 'application/json',
      'X-Authorization': _api.getKey(),
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (userId != null) 'X-User-Id': '$userId',
    };
  }

  Future<ChatMessagesPage> getMessages(
    int bookingId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse(
      '${_api.getChicapartsUrl()}chat/discussions/$bookingId/messages',
    ).replace(queryParameters: {
      'page': '$page',
      'per_page': '$perPage',
    });
    final response = await _client.get(uri, headers: await _headers());
    final body = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(_errorMessage(body), response.statusCode);
    }

    final data = body['data'];
    final envelope = data is Map<String, dynamic> ? data : body;
    final rawMessages =
        envelope['data'] is List ? envelope['data'] as List : const [];

    return ChatMessagesPage(
      messages: rawMessages
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      currentPage: _asInt(envelope['current_page'], 1),
      lastPage: _asInt(envelope['last_page'], 1),
    );
  }

  Future<List<ChatDiscussion>> getDiscussions({int limit = 50}) async {
    final uri = Uri.parse(
      '${_api.getChicapartsUrl()}chat/discussions',
    ).replace(queryParameters: {'limit': '$limit'});
    final response = await _client.get(uri, headers: await _headers());
    final body = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(_errorMessage(body), response.statusCode);
    }

    final raw = body['data'] is List ? body['data'] as List : const [];
    final discussions = raw
        .whereType<Map>()
        .map((item) => ChatDiscussion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    discussions.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.firstNight;
      final bDate = b.lastMessage?.createdAt ?? b.firstNight;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return discussions;
  }

  Future<ChatMessage> sendMessage(int bookingId, String text) async {
    final response = await _client.post(
      Uri.parse('${_api.getChicapartsUrl()}chat/messages'),
      headers: await _headers(json: true),
      body: jsonEncode({'booking_id': bookingId, 'message': text}),
    );
    final body = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(_errorMessage(body), response.statusCode);
    }

    final data = body['data'];
    if (data is! Map) {
      throw const ChatApiException('Réponse invalide du serveur.');
    }
    return ChatMessage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> markAllAsRead(int bookingId) async {
    final response = await _client.put(
      Uri.parse(
        '${_api.getChicapartsUrl()}chat/discussions/$bookingId/read-all-by-customer',
      ),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatApiException(
          'Impossible de marquer les messages comme lus.', response.statusCode);
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String _errorMessage(Map<String, dynamic> body) {
    if (body['message'] != null) return body['message'].toString();
    if (body['error'] != null) return body['error'].toString();
    return 'Le service de messagerie est momentanément indisponible.';
  }

  int _asInt(dynamic value, int fallback) =>
      value is int ? value : int.tryParse('$value') ?? fallback;

  void close() => _client.close();
}
