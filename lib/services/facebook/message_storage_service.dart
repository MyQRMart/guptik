import 'package:flutter/material.dart';
import 'package:guptik/services/node/node_table_client.dart';

class MessageStorageService {
  final _store = NodeTableClient();

  String _convTable(String platform) =>
      platform == 'facebook' ? 'fb_conversations' : 'ig_conversations';

  String _msgTable(String platform) =>
      platform == 'facebook' ? 'fb_messages' : 'ig_messages';

  Future<bool> testConnection() async {
    try {
      await _store.select('fb_conversations', limit: 1);
      return true;
    } catch (e) {
      debugPrint('Node FB/IG store: $e');
      return false;
    }
  }

  Future<String?> getConversationIdBySender(
    String platform,
    String senderId,
    String userId,
  ) async {
    try {
      final trimmed = senderId.trim();
      final all = await _store.select(_convTable(platform), eq: {'user_id': userId});
      for (final row in all) {
        if (row['sender_id']?.toString().trim() == trimmed) {
          return row['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting conversation ID by sender: $e');
      return null;
    }
  }

  Future<void> saveConversation({
    required String platform,
    required String conversationId,
    required String participantId,
    required String participantName,
    String? participantUsername,
    String? participantAvatar,
    String? lastMessage,
    String? lastMessageTime,
    int unreadCount = 0,
    required String userId,
  }) async {
    try {
      final table = _convTable(platform);
      final existing = await _store.maybeSingle(table, {'id': conversationId});
      if (platform == 'facebook') {
        final data = {
          'id': conversationId,
          'user_id': userId,
          'sender_id': participantId,
          'sender_username': participantUsername ?? 'sender_$participantId',
          'sender_avatar': participantAvatar,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'unread_count': unreadCount,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (existing == null) {
          await _store.insert(table, data);
        } else {
          await _store.update(table, eq: {'id': conversationId}, set: data);
        }
      } else {
        final data = {
          'id': conversationId,
          'user_id': userId,
          'sender_id': participantId.trim(),
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'is_unread': unreadCount > 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (existing == null) {
          await _store.insert(table, data);
        } else {
          await _store.update(table, eq: {'id': conversationId}, set: data);
        }
      }
    } catch (e) {
      debugPrint('Error saving $platform conversation: $e');
    }
  }

  Future<void> saveMessage({
    required String platform,
    required String conversationId,
    required String messageId,
    required String content,
    required String messageType,
    required String direction,
    String? status,
    required String timestamp,
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? rawData,
  }) async {
    try {
      await _store.insert(_msgTable(platform), {
        'conversation_id': conversationId,
        'message_id': messageId,
        'content': content,
        'message_type': messageType,
        'direction': direction,
        'status': status ?? 'delivered',
        'timestamp': timestamp,
        'media_info': mediaInfo,
        'raw_data': rawData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving $platform message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String platform,
    String conversationId, {
    int limit = 50,
  }) async {
    try {
      return await _store.select(
        _msgTable(platform),
        eq: {'conversation_id': conversationId},
        order: 'timestamp',
        ascending: true,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  Future<void> updateMessageStatus(
    String platform,
    String messageId,
    String status,
  ) async {
    try {
      await _store.update(
        _msgTable(platform),
        eq: {'message_id': messageId},
        set: {
          'status': status,
          'status_timestamp': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error updating message status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserConversations(
    String platform,
    String userId,
  ) async {
    try {
      return await _store.select(
        _convTable(platform),
        eq: {'user_id': userId},
        order: 'last_message_time',
        ascending: false,
      );
    } catch (e) {
      debugPrint('Error getting user conversations: $e');
      return [];
    }
  }
}
