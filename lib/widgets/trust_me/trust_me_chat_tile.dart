import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_chat_model.dart';

class TrustMeChatTile extends StatelessWidget {
  final TrustMeChatModel chat;
  final VoidCallback onTap;

  const TrustMeChatTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: chat.avatarUrl.isNotEmpty ? NetworkImage(chat.avatarUrl) : null,
        child: chat.avatarUrl.isEmpty ? Icon(Icons.person, color: Colors.grey[600]) : null,
      ),
      title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(
        chat.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.time,
            style: TextStyle(
              color: chat.unreadCount > 0 ? const Color(0xFF25D366) : Colors.grey,
              fontSize: 12,
              fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}