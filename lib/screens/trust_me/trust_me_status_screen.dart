import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_status_model.dart';
import 'package:guptik/widgets/trust_me/trust_me_status_tile.dart';

class TrustMeStatusScreen extends StatelessWidget {
  const TrustMeStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TrustMeStatusTile(status: TrustMeStatusModel(name: "My Status", time: "Tap to add status update", isMyStatus: true)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Recent updates", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        TrustMeStatusTile(status: TrustMeStatusModel(name: "John Doe", time: "Today, 10:45 AM")),
      ],
    );
  }
}