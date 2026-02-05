import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';

class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final String Function(DateTime?) formatTime;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: conversation.isGroup ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: conversation.isGroup
                      ? const Icon(
                          Icons.group,
                          color: Colors.orange,
                          size: 28,
                        )
                      : Text(
                          conversation.initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Conversation Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: conversation.isUnread 
                                  ? FontWeight.bold 
                                  : FontWeight.w500,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      conversation.displayPhoneOrMembers,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        if (conversation.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: conversation.isUnread 
                                  ? Colors.black 
                                  : Colors.grey[600],
                              fontWeight: conversation.isUnread 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Unread badge
              if (conversation.isUnread)
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.messenger,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}