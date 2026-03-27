import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/services/facebook/message_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailScreen extends StatefulWidget {
  final MetaChat conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MetaService _metaService = MetaService();
  final MessageStorageService _storageService = MessageStorageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNewMessages() {
    final table = widget.conversation.platform == SocialPlatform.facebook
        ? 'fb_messages'
        : 'ig_messages';

    _realtimeChannel = Supabase.instance.client
        .channel('messages-${widget.conversation.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversation.supabaseId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final message = {
              'id': newMessage['message_id'],
              'message': newMessage['content'],
              'is_from_me':
                  newMessage['direction'] == 'outgoing' ||
                  newMessage['direction'] == 'ai_outgoing',
              'created_time': newMessage['timestamp'],
              'message_id': newMessage['message_id'],
              'content': newMessage['content'],
              'message_type': newMessage['message_type'],
              'direction': newMessage['direction'],
              'timestamp': newMessage['timestamp'],
              'media_info': newMessage['media_info'],
              'raw_data': newMessage['raw_data'],
            };

            if (!_messages.any(
              (m) => m['message_id'] == message['message_id'],
            )) {
              if (mounted) {
                setState(() {
                  _messages.add(message);
                  _messages.sort((a, b) {
                    final timeA = DateTime.parse(a['created_time']);
                    final timeB = DateTime.parse(b['created_time']);
                    return timeA.compareTo(timeB);
                  });
                });
                _scrollToBottom();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load only from Supabase – no API fallback
      final storedMessages = await _storageService.getMessages(
        widget.conversation.platform == SocialPlatform.facebook
            ? 'facebook'
            : 'instagram',
        widget.conversation.supabaseId,
      );

      if (storedMessages.isNotEmpty) {
        _messages = storedMessages.map((msg) {
          return {
            'id': msg['message_id'],
            'message': msg['content'],
            'is_from_me':
                msg['direction'] == 'outgoing' ||
                msg['direction'] == 'ai_outgoing',
            'created_time': msg['timestamp'],
            'message_id': msg['message_id'],
            'content': msg['content'],
            'message_type': msg['message_type'],
            'direction': msg['direction'],
            'timestamp': msg['timestamp'],
            'media_info': msg['media_info'],
            'raw_data': msg['raw_data'],
          };
        }).toList();

        _messages.sort((a, b) {
          final timeA = DateTime.parse(a['created_time']);
          final timeB = DateTime.parse(b['created_time']);
          return timeA.compareTo(timeB);
        });

        setState(() => _isLoading = false);
        _scrollToBottom();
      } else {
        // No messages in Supabase – show empty state
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text.trim();
    _textController.clear();

    final tempMessage = {
      'message': messageText,
      'is_from_me': true,
      'created_time': DateTime.now().toIso8601String(),
      'is_sending': true,
    };

    setState(() {
      _isSending = true;
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      bool success;
      if (widget.conversation.platform == SocialPlatform.instagram) {
        success = await _metaService.sendInstagramMessage(
          widget.conversation.participantId,
          messageText,
        );
      } else {
        // For Facebook, use the new sendMessage with recipientId (participantId)
        success = await _metaService.sendMessage(
          conversationId: widget.conversation.id,
          recipientId: widget.conversation.participantId,
          message: messageText,
        );
      }

      if (success && mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        await _loadMessages(); // reload to show stored outgoing message
      } else if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['is_sending'] == true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _textController.text = messageText;
                _sendMessage();
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg['is_sending'] == true);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.conversation.platform;
    final platformColor = platform == SocialPlatform.facebook
        ? Colors.blue
        : Colors.pink;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: platformColor.shade100,
              child: Text(
                widget.conversation.senderName.isNotEmpty
                    ? widget.conversation.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: platformColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.senderName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: platformColor.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      platform == SocialPlatform.facebook
                          ? 'Facebook'
                          : 'Instagram',
                      style: TextStyle(
                        fontSize: 10,
                        color: platformColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message to start the conversation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isSending = msg['is_sending'] == true;
                              return _buildMessageBubble(
                                msg['message'] ?? '',
                                msg['is_from_me'] ?? false,
                                msg['created_time'] ?? '',
                                isSending,
                              );
                            },
                          ),
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 2, color: Colors.grey.withValues(alpha: 0.1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.conversation.platform == SocialPlatform.facebook
                    ? [Colors.blue, Colors.blue.shade700]
                    : [Colors.pink, Colors.pink.shade700],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isMe,
    String time,
    bool isSending,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  widget.conversation.platform == SocialPlatform.facebook
                  ? Colors.blue.shade100
                  : Colors.pink.shade100,
              child: Text(
                widget.conversation.senderName.isNotEmpty
                    ? widget.conversation.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.conversation.platform == SocialPlatform.facebook
                      ? Colors.blue
                      : Colors.pink,
                ),
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? (isSending ? Colors.blue.shade100 : Colors.blue)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (isSending)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sending',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isMe ? Colors.white70 : Colors.grey[600]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 10, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
