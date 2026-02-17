import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_chat_model.dart';
import 'package:guptik/widgets/trust_me/trust_me_chat_tile.dart';
import 'trust_me_chat_room_screen.dart';

class TrustMeChatListScreen extends StatelessWidget {
  const TrustMeChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<TrustMeChatModel> chats = [
      TrustMeChatModel(name: "Alice", message: "Hey, is the project ready?", time: "10:30 AM", unreadCount: 2),
      TrustMeChatModel(name: "Bob", message: "See you tomorrow!", time: "Yesterday", unreadCount: 0),
    ];

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        return TrustMeChatTile(
          chat: chats[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrustMeChatRoomScreen(name: chats[index].name),
              ),
            );
          },
        );
      },
    );
  }
}