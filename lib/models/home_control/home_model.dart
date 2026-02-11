import 'board_model.dart';
import 'room_model.dart';

class Home {
  final String id;
  final String userId;
  final String name;
  final String? wallpaperPath;
  final List<Board> boards; // Strongly typed as Board
  final List<Room> rooms;   // Strongly typed as Room

  Home({
    required this.id,
    required this.userId,
    required this.name,
    this.wallpaperPath,
    this.boards = const [],
    this.rooms = const [],
  });

  factory Home.fromJson(Map<String, dynamic> json) {
    // 1. Check for Supabase relation keys first ('hc_boards', 'hc_rooms')
    // 2. Fallback to simple keys ('boards', 'rooms') if needed
    var boardsList = json['hc_boards'] ?? json['boards'];
    var roomsList = json['hc_rooms'] ?? json['rooms'];

    return Home(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      wallpaperPath: json['wallpaper_path'],
      
      // 3. Map the lists safely
      boards: boardsList != null
          ? (boardsList as List).map((b) => Board.fromJson(b)).toList()
          : [],
          
      rooms: roomsList != null
          ? (roomsList as List).map((r) => Room.fromJson(r)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'wallpaper_path': wallpaperPath,
      'boards': boards.map((b) => b.toJson()).toList(),
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
  }
}