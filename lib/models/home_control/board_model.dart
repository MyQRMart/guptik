import 'switch_model.dart';

enum BoardStatus { online, offline, maintenance }

class Board {
  final String id;
  final String ownerId;
  final String name;
  final String? roomId; 
  final BoardStatus status;
  final String? macAddress;
  final DateTime? lastOnline;
  final bool isActive;
  final List<SwitchDevice> switches;

  Board({
    required this.id,
    required this.ownerId,
    required this.name,
    this.roomId,
    this.status = BoardStatus.offline,
    this.macAddress,
    this.lastOnline,
    this.isActive = true,
    this.switches = const [],
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      roomId: json['room_id'],
      status: BoardStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'offline'),
        orElse: () => BoardStatus.offline,
      ),
      macAddress: json['mac_address'],
      lastOnline: json['last_online'] != null ? DateTime.parse(json['last_online']) : null,
      isActive: json['is_active'] ?? true,
      switches: (json['switches'] as List?)?.map((s) => SwitchDevice.fromJson(s)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'room_id': roomId,
      'status': status.name,
      'mac_address': macAddress,
      'last_online': lastOnline?.toIso8601String(),
      'is_active': isActive,
      'switches': switches.map((s) => s.toJson()).toList(),
    };
  }
}