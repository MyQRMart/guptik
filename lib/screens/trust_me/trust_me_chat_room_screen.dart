import 'package:flutter/material.dart';
import 'package:guptik/models/trust_me/trust_me_message_model.dart';
import 'package:guptik/widgets/trust_me/trust_me_message_bubble.dart';

class TrustMeChatRoomScreen extends StatelessWidget {
  final String name;
  const TrustMeChatRoomScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<TrustMeMessageModel> messages = [
      TrustMeMessageModel(message: "Hi there!", time: "10:00 AM", isMe: false),
      TrustMeMessageModel(message: "Hello! UI is ready.", time: "10:02 AM", isMe: true),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, color: Colors.white),
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text("online", style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        color: const Color(0xFFECE5DD),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  // Now this widget is recognized because of the import above
                  return TrustMeMessageBubble(message: messages[index]);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.attach_file, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Icon(Icons.camera_alt, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF075E54),
            child: Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}