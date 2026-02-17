import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_call_model.dart';

class TrustMeCallTile extends StatelessWidget {
  final TrustMeCallModel call;

  const TrustMeCallTile({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600]),
      ),
      title: Text(call.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          Icon(
            call.isIncoming ? Icons.call_received : Icons.call_made,
            color: call.isIncoming ? Colors.red : const Color(0xFF25D366),
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(call.time),
        ],
      ),
      trailing: Icon(
        call.isVideoCall ? Icons.videocam : Icons.call,
        color: const Color(0xFF075E54),
      ),
    );
  }
}