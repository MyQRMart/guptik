import 'package:flutter/material.dart';

class SwitchTimer {
  final String id;
  final String switchId;
  final String userId; // ✅ Added: Required by your DB schema
  final TimeOfDay time;
  final bool action; // true = Turn ON, false = Turn OFF
  final bool isActive;
  final List<bool> repeatDays; // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

  SwitchTimer({
    required this.id,
    required this.switchId,
    required this.userId, 
    required this.time,
    required this.action,
    this.isActive = true,
    this.repeatDays = const [false, false, false, false, false, false, false],
  });

  factory SwitchTimer.fromJson(Map<String, dynamic> json) {
    // Parse time "HH:MM"
    final timeParts = (json['time'] as String).split(':');
    
    // Map 'days_of_week' (e.g. [1, 2]) to repeatDays boolean list
    // Assuming DB stores 1=Mon, 2=Tue... 7=Sun
    List<bool> days = List.filled(7, false);
    if (json['days_of_week'] != null) {
      final dbDays = List<int>.from(json['days_of_week']);
      for (var dayIndex in dbDays) {
        // Adjust index: DB (1-7) -> List (0-6)
        if (dayIndex >= 1 && dayIndex <= 7) {
          days[dayIndex - 1] = true;
        }
      }
    }

    return SwitchTimer(
      id: json['id'],
      switchId: json['switch_id'],
      userId: json['user_id'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      action: json['action'] ?? true,
      isActive: json['is_active'] ?? true,
      repeatDays: days,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert repeatDays boolean list to 'days_of_week' integers [1, 2...]
    List<int> dbDays = [];
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) {
        dbDays.add(i + 1); // 1=Mon, 7=Sun
      }
    }

    return {
      'id': id,
      'switch_id': switchId,
      'user_id': userId, // ✅ Sending user_id
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'action': action,
      'is_active': isActive,
      'days_of_week': dbDays, // ✅ Mapping to correct column name
      'type': 'scheduled', // Matches your check constraint
    };
  }
}