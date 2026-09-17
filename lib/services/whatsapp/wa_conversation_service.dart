import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';
import 'package:guptik/services/node/node_table_client.dart';

class ConversationService {
  final _store = NodeTableClient();

  String _getUtcTimestamp() => DateTime.now().toUtc().toIso8601String();

  Future<List<Conversation>> getConversations() async {
    final data = await _store.select('conversations', order: 'last_message_time', ascending: false);
    return data.map(Conversation.fromMap).toList();
  }

  Future<List<Conversation>> getIndividualConversations() async {
    final data = await _store.select(
      'wa_conversations',
      eq: {'is_archived': 'false'},
      order: 'last_message_time',
      ascending: false,
    );
    return data.map(Conversation.fromMap).toList();
  }

  Future<List<Conversation>> getGroupConversations() async {
    final data = await _store.select(
      'wa_conversations',
      eq: {'is_archived': 'false'},
      notNull: 'ai_agent_id',
      order: 'last_message_time',
      ascending: false,
    );
    return data.map(Conversation.fromMap).toList();
  }

  Future<void> markAsRead(String conversationId) async {
    await _store.update(
      'wa_conversations',
      eq: {'id': conversationId},
      set: {'is_unread': false, 'updated_at': _getUtcTimestamp()},
    );
  }

  Future<void> updateLastMessage({
    required String conversationId,
    required String message,
    bool fromUser = true,
  }) async {
    final currentTime = DateTime.now();
    await _store.update(
      'wa_conversations',
      eq: {'id': conversationId},
      set: {
        'last_message': message,
        'last_message_time': currentTime.toIso8601String(),
        'updated_at': currentTime.toUtc().toIso8601String(),
        'is_unread': fromUser,
      },
    );
  }

  Future<void> updateAIAgentStatus({
    required String conversationId,
    required bool aiEnabled,
    String defaultAgentId = '00000000-0000-0000-0000-000000000000',
  }) async {
    await _store.update(
      'conversations',
      eq: {'id': conversationId},
      set: {
        'ai_agent_id': aiEnabled ? defaultAgentId : null,
        'updated_at': _getUtcTimestamp(),
      },
    );
  }

  Future<bool> getAIAgentStatus(String conversationId) async {
    try {
      final row = await _store.maybeSingle('wa_conversations', {'id': conversationId});
      return row?['ai_agent_id'] != null;
    } catch (e) {
      debugPrint('Error getting AI agent status: $e');
      return false;
    }
  }

  Future<Conversation> getConversationById(String conversationId) async {
    final row = await _store.maybeSingle('wa_conversations', {'id': conversationId});
    if (row == null) throw Exception('Failed to get conversation');
    return Conversation.fromMap(row);
  }
}
