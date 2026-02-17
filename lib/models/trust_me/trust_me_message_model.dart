class TrustMeMessageModel {
  final String message;
  final String time;
  final bool isMe; // True if sent by you

  TrustMeMessageModel({
    required this.message,
    required this.time,
    required this.isMe,
  });
}