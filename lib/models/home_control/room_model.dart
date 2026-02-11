import 'board_model.dart';

class Room {
  final String id;
  final String homeId;
  final String name;
  final String? description;
  final String? icon;
  final int? displayOrder;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Board> boards;

  Room({
    required this.id,
    required this.homeId,
    required this.name,
    this.description,
    this.icon,
    this.displayOrder,
    this.metadata,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.boards = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // CRITICAL FIX: Supabase returns relations using the table name 'hc_boards'.
    // We check for 'hc_boards' first, then fallback to 'boards'.
    var rawBoards = json['hc_boards'] ?? json['boards'];

    List<Board> parsedBoards = [];
    if (rawBoards != null && rawBoards is List) {
      parsedBoards = rawBoards
          .map((b) => Board.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return Room(
      id: json['id'] as String,
      homeId: json['home_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      displayOrder: json['display_order'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      boards: parsedBoards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home_id': homeId,
      'name': name,
      'description': description,
      'icon': icon,
      'display_order': displayOrder,
      'metadata': metadata,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // We map this back to 'boards' for local use, or 'hc_boards' if sending to API (though usually not needed for updates)
      'boards': boards.map((b) => b.toJson()).toList(),
    };
  }

  Room copyWith({
    String? id,
    String? homeId,
    String? name,
    String? description,
    String? icon,
    int? displayOrder,
    Map<String, dynamic>? metadata,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Board>? boards,
  }) {
    return Room(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      boards: boards ?? this.boards,
    );
  }
}