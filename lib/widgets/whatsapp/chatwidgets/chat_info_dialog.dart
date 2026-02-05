import 'package:flutter/material.dart';

class ChatInfoDialog extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  final int messagesCount;
  final bool aiEnabled;

  const ChatInfoDialog({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.messagesCount,
    required this.aiEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact: $contactName'),
          Text('Phone: $phoneNumber'),
          Text('Total Messages: $messagesCount'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: aiEnabled ? Colors.yellow : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Assistant: ${aiEnabled ? 'Enabled' : 'Disabled'}',
                style: TextStyle(
                  color: aiEnabled ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}