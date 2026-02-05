import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_message.dart';
import 'package:guptik/widgets/whatsapp/chatwidgets/media_content.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback onLongPress;
  final String Function(DateTime) formatTime;
  final IconData Function(String?) getStatusIcon;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onLongPress,
    required this.formatTime,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = message.isIncoming;
    final isAI = message.isAiOutgoing;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isIncoming ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isIncoming ? const Color(0xFFF5F5F5) : 
                         isAI ? Colors.purple : Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20.0),
                    topRight: const Radius.circular(20.0),
                    bottomLeft: isIncoming ? const Radius.circular(0.0) : const Radius.circular(20.0),
                    bottomRight: isIncoming ? const Radius.circular(20.0) : const Radius.circular(0.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAI)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'AI Assistant',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (message.hasMedia)
                      MediaContent(message: message)
                    else if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isIncoming ? Colors.black : Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    
                    if (message.hasMedia && message.mediaInfo?['caption'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          message.mediaInfo!['caption'],
                          style: TextStyle(
                            color: isIncoming ? Colors.black : Colors.white,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          formatTime(message.timestamp),
                          style: TextStyle(
                            color: isIncoming ? Colors.grey.shade600 : Colors.white70,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        if (!isIncoming)
                          Icon(
                            getStatusIcon(message.status),
                            size: 12.0,
                            color: Colors.white70,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}