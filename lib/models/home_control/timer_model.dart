enum TimerType { scheduled, prescheduled, countdown }

class SwitchTimer {
  final String id;
  final String switchId;
  final TimerType type;
  final String time;
  final List<String> days;
  final bool state;
  final bool isEnabled;
  final DateTime? scheduledDate;

  SwitchTimer({
    required this.id,
    required this.switchId,
    required this.type,
    required this.time,
    required this.days,
    required this.state,
    required this.isEnabled,
    this.scheduledDate,
  });

  factory SwitchTimer.fromJson(Map<String, dynamic> json) {
    return SwitchTimer(
      id: json['id'],
      switchId: json['switch_id'],
      type: TimerType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type'] ?? 'scheduled').toLowerCase(),
        orElse: () => TimerType.scheduled,
      ),
      time: json['time'],
      days: List<String>.from(json['days'] ?? []),
      state: json['state'] ?? true,
      isEnabled: json['is_enabled'] ?? true,
      scheduledDate: json['scheduled_date'] != null ? DateTime.parse(json['scheduled_date']) : null,
    );
  }

  SwitchTimer copyWith({bool? isEnabled}) {
    return SwitchTimer(
      id: id,
      switchId: switchId,
      type: type,
      time: time,
      days: days,
      state: state,
      isEnabled: isEnabled ?? this.isEnabled,
      scheduledDate: scheduledDate,
    );
  }
}