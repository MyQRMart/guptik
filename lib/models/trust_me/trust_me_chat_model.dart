class TrustMeChatModel {
  final String name;
  final String message;
  final String time;
  final String avatarUrl;
  final int unreadCount;

  TrustMeChatModel({
    required this.name,
    required this.message,
    required this.time,
    this.avatarUrl = "", 
    this.unreadCount = 0,
  });
}