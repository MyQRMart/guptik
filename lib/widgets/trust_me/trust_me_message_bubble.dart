import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_message_model.dart';

class TrustMeMessageBubble extends StatelessWidget {
  final TrustMeMessageModel message;

  const TrustMeMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: message.isMe ? const Color(0xFFE7FFDB) : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message.message, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message.time, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    if (message.isMe) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.done_all, size: 15, color: Colors.blue),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}