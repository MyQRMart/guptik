import 'meta_content_model.dart'; // For SocialPlatform enum

class MetaChat {
  final String id;
  final String senderName;
  final String lastMessage;
  final String time; // Display string like "10:30 AM"
  final String? rawTimestamp; // NEW: ISO string for sorting (e.g. "2023-10-27T10:30:00")
  final String avatarUrl;
  final SocialPlatform platform;
  final bool isUnread;

  MetaChat({
    required this.id,
    required this.senderName,
    required this.lastMessage,
    required this.time,
    this.rawTimestamp,
    required this.avatarUrl,
    required this.platform,
    this.isUnread = false,
  });
}