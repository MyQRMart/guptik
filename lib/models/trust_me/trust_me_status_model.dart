class TrustMeStatusModel {
  final String name;
  final String time;
  final bool isMyStatus;

  TrustMeStatusModel({
    required this.name,
    required this.time,
    this.isMyStatus = false,
  });
}