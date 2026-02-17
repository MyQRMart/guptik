import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_status_model.dart';

class TrustMeStatusTile extends StatelessWidget {
  final TrustMeStatusModel status;

  const TrustMeStatusTile({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: status.isMyStatus
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF25D366), width: 2),
                  ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600]),
            ),
          ),
          if (status.isMyStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  border: Border.all(color: Colors.white, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.white),
              ),
            )
        ],
      ),
      title: Text(status.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(status.time),
    );
  }
}