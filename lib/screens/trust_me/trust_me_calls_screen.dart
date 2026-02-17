import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_call_model.dart';
import 'package:guptik/widgets/trust_me/trust_me_call_tile.dart';

class TrustMeCallsScreen extends StatelessWidget {
  const TrustMeCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<TrustMeCallModel> calls = [
      TrustMeCallModel(name: "Alice", time: "Today, 12:30 PM", isIncoming: true, isVideoCall: false),
    ];

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return TrustMeCallTile(call: calls[index]);
      },
    );
  }
}