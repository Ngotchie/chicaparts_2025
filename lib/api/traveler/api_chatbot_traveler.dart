import 'dart:convert';

import 'package:chicaparts_partner/services/api.dart';
import 'package:http/http.dart' as http;

class ChatbotReply {
  final String reply;
  final String conversationId;
  final bool aiUsed;

  const ChatbotReply({
    required this.reply,
    required this.conversationId,
    required this.aiUsed,
  });

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    return ChatbotReply(
      reply: '${json['reply'] ?? ''}',
      conversationId: '${json['conversation_id'] ?? ''}',
      aiUsed: json['ai_used'] == true,
    );
  }
}

class ApiChatbotTraveler {
  Future<ChatbotReply> chat({
    required String message,
    String? conversationId,
    int? accommodationId,
  }) async {
    final url = ApiUrl();
    final response = await http.post(
      Uri.parse('${url.getChicapartsUrl()}chatbot/chat'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': url.getKey(),
      },
      body: jsonEncode({
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversation_id': conversationId,
        if (accommodationId != null) 'accommodation_id': accommodationId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur assistant (${response.statusCode})');
    }

    return ChatbotReply.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }
}
