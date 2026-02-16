import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final MetaChat conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MetaService _metaService = MetaService();
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      // This calls the function we are about to add to MetaService
      final msgs = await _metaService.getChatMessages(widget.conversation.id);
      
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error loading chat details: $e"); // Fixed: print -> debugPrint
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: Text(widget.conversation.senderName.isNotEmpty 
                  ? widget.conversation.senderName[0] 
                  : '?'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.conversation.senderName, 
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Start from bottom
                  itemCount: _messages.isEmpty ? 1 : _messages.length,
                  itemBuilder: (context, index) {
                    if (_messages.isEmpty) {
                      return _buildMessageBubble(
                        widget.conversation.lastMessage, 
                        false, 
                        widget.conversation.time
                      );
                    }
                    final msg = _messages[index];
                    return _buildMessageBubble(
                      msg['message'], 
                      msg['is_from_me'] ?? false, 
                      msg['created_time'] ?? ''
                    );
                  },
                ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  blurRadius: 2, 
                  // Fixed: withOpacity -> withValues
                  color: Colors.grey.withValues(alpha: 0.1) 
                )
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), 
                        borderSide: BorderSide.none
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1877F2)),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _textController.clear();
                      // Send logic goes here
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1877F2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}