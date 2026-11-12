class ChatMessage {
  final int id;
  final int bookingId;
  final String message;
  final String senderType;
  final DateTime? createdAt;
  final DateTime? customerReadAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.message,
    required this.senderType,
    this.createdAt,
    this.customerReadAt,
  });

  bool get isFromCustomer => senderType == 'customer';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;

    DateTime? asDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return ChatMessage(
      id: asInt(json['id']),
      bookingId: asInt(json['booking_id']),
      message: (json['message'] ?? '').toString(),
      senderType: (json['sender_type'] ?? '').toString(),
      createdAt: asDate(json['created_at']),
      customerReadAt: asDate(json['customer_read_at']),
    );
  }
}

class ChatDiscussion {
  final int bookingId;
  final String bookingReference;
  final String accommodationName;
  final String city;
  final String? imageUrl;
  final DateTime? firstNight;
  final DateTime? lastNight;
  final int unreadCount;
  final ChatMessage? lastMessage;

  const ChatDiscussion({
    required this.bookingId,
    required this.bookingReference,
    required this.accommodationName,
    required this.city,
    required this.imageUrl,
    required this.firstNight,
    required this.lastNight,
    required this.unreadCount,
    required this.lastMessage,
  });

  factory ChatDiscussion.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    DateTime? asDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    final accommodation = json['accommodation'] is Map
        ? Map<String, dynamic>.from(json['accommodation'])
        : const <String, dynamic>{};
    final rawLastMessage = json['last_message'];

    return ChatDiscussion(
      bookingId: asInt(json['id']),
      bookingReference: (json['booking_ref'] ?? json['id'] ?? '').toString(),
      accommodationName: (accommodation['display_name'] ??
              accommodation['external_name'] ??
              accommodation['internal_name'] ??
              '')
          .toString(),
      city: (accommodation['city'] ?? '').toString(),
      imageUrl: accommodation['main_photo']?.toString(),
      firstNight: asDate(json['firstNight']),
      lastNight: asDate(json['lastNight']),
      unreadCount: asInt(json['unread_count']),
      lastMessage: rawLastMessage is Map
          ? ChatMessage.fromJson({
              ...Map<String, dynamic>.from(rawLastMessage),
              'booking_id': json['id'],
            })
          : null,
    );
  }
}
