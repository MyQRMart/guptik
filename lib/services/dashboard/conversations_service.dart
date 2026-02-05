import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guptik/config/app_config.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';
import 'package:http/http.dart' as http;



class ConversationsService {
    // Get all conversations
    Future<List<Conversation>> getConversations({String? filter}) async {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/$_phoneNumberId/conversations'),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> conversationsData = data['data'] ?? [];
          List<Conversation> conversations = conversationsData
              .map((item) => Conversation.fromMap(item))
              .toList();

          // Apply filter if specified
          if (filter != null) {
            switch (filter.toLowerCase()) {
              case 'active':
                conversations = conversations.where((c) => c.status == ConversationStatus.active).toList();
                break;
              case 'closed':
                conversations = conversations.where((c) => c.status == ConversationStatus.closed).toList();
                break;
            }
          }
          return conversations;
        } else {
          debugPrint('Failed to fetch conversations: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        debugPrint('Error fetching conversations: $e');
        return [];
      }
    }

    // Get messages for a specific conversation
    Future<List<Message>> getConversationMessages(String conversationId) async {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/$conversationId/messages'),
          headers: _headers,
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> messagesData = data['data'] ?? [];
          return messagesData
              .map((item) => Message.fromJson(item))
              .toList();
        } else {
          debugPrint('Failed to fetch messages: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        debugPrint('Error fetching conversation messages: $e');
        return [];
      }
    }
  static final ConversationsService _instance = ConversationsService._internal();
  factory ConversationsService() => _instance;
  ConversationsService._internal();

  final String _baseUrl = AppConfig.whatsappApiBaseUrl;
  final String _accessToken = AppConfig.whatsappAccessToken;
  final String _phoneNumberId = AppConfig.whatsappPhoneNumberId;
  // Note: _businessAccountId will be used for real API calls
  // final String _businessAccountId = AppConfig.whatsappBusinessAccountId;

  // Get headers for API requests
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  // Get all conversations (no filter)
  Future<List<Conversation>> getAllConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_phoneNumberId/conversations'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> conversationsData = data['data'] ?? [];
        
        return conversationsData
            .map((item) => Conversation.fromMap(item))
            .toList();
      } else {
        debugPrint('Failed to fetch messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching conversation messages: $e');
      return [];
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
    String? messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_phoneNumberId/messages'),
        headers: _headers,
        body: json.encode({
          'messaging_product': 'whatsapp',
          'to': phoneNumber,
          'type': messageType,
          'text': {
            'body': message,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Mark conversation as read
  Future<bool> markAsRead(String conversationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$conversationId/messages'),
        headers: _headers,
        body: json.encode({
          'messaging_product': 'whatsapp',
          'status': 'read',
          'message_id': conversationId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      return false;
    }
  }

  // Search conversations
  Future<List<Conversation>> searchConversations(String query) async {
    try {
      final allConversations = await getAllConversations();
      return allConversations.where((conv) {
        final contactName = conv.contactName?.toLowerCase() ?? '';
        final lastMessage = conv.lastMessage?.toLowerCase() ?? '';
        final phoneNumber = conv.phoneNumber;
        final q = query.toLowerCase();
        return contactName.contains(q) ||
               lastMessage.contains(q) ||
               phoneNumber.contains(q);
      }).toList();
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      return [];
    }
  }

}


class Message {
  final String id;
  final String conversationId;
  final String content;
  final DateTime timestamp;
  final bool isFromBusiness;
  final MessageType messageType;
  final MessageStatus status;
  final String? mediaUrl;

  Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.timestamp,
    required this.isFromBusiness,
    required this.messageType,
    required this.status,
    this.mediaUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isFromBusiness: json['is_from_business'] ?? false,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      mediaUrl: json['media_url'],
    );
  }
}

// enum ConversationStatus { active, closed }
enum MessageType { text, image, document, audio, video }
enum MessageStatus { sent, delivered, read, failed }