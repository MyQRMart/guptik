import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart'; // Needed for SocialPlatform enum
import 'package:guptik/services/facebook/meta_service.dart';
import 'chat_detail_screen.dart'; // Make sure you have this file created

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final MetaService _metaService = MetaService();
  late Future<List<MetaChat>> _inboxFuture;

  @override
  void initState() {
    super.initState();
    _inboxFuture = _metaService.getUnifiedInbox();
  }

  // Refresh function for Pull-to-Refresh
  Future<void> _refreshInbox() async {
    setState(() {
      _inboxFuture = _metaService.getUnifiedInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshInbox,
      child: FutureBuilder<List<MetaChat>>(
        future: _inboxFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Could not load Inbox.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceAll("Exception: ", ""),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshInbox,
                      child: const Text("Retry"),
                    )
                  ],
                ),
              ),
            );
          }

          final chats = snapshot.data ?? [];

          // 3. Empty State
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Your inbox is empty.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Success List
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatTile(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(MetaChat chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      leading: Stack(
        children: [
          // User Avatar (Initials)
          CircleAvatar(
            backgroundColor: Colors.blueGrey[50],
            radius: 26,
            child: Text(
              chat.senderName.isNotEmpty ? chat.senderName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.blueGrey[800],
                fontSize: 18,
              ),
            ),
          ),
          // Small Platform Badge (FB or Insta)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: FaIcon(
                chat.platform == SocialPlatform.facebook
                    ? FontAwesomeIcons.facebook
                    : FontAwesomeIcons.instagram,
                size: 12,
                color: chat.platform == SocialPlatform.facebook
                    ? const Color(0xFF1877F2)
                    : const Color(0xFFE1306C),
              ),
            ),
          )
        ],
      ),
      title: Text(
        chat.senderName,
        style: TextStyle(
          fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: chat.isUnread ? Colors.black87 : Colors.grey[600],
            fontWeight: chat.isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chat.time, 
            style: TextStyle(
              fontSize: 12, 
              color: chat.isUnread ? const Color(0xFF1877F2) : Colors.grey
            ),
          ),
          if (chat.isUnread) ...[
            const SizedBox(height: 6),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF1877F2),
                shape: BoxShape.circle,
              ),
            )
          ]
        ],
      ),
      // ✅ NAVIGATION: Opens the Chat Detail Screen
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(conversation: chat),
          ),
        );
      },
    );
  }
}