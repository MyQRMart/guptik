import 'board_model.dart';
import 'room_model.dart';

class Home {
  final String id;
  final String userId;
  final String name;
  final String? wallpaperPath;
  final List<Board> boards;
  final List<Room> rooms;

  Home({
    required this.id,
    required this.userId,
    required this.name,
    this.wallpaperPath,
    required this.boards,
    this.rooms = const [],
  });

  factory Home.fromJson(Map<String, dynamic> json) {
    return Home(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      wallpaperPath: json['wallpaper_path'],
      boards: json['boards'] != null
          ? (json['boards'] as List).map((b) => Board.fromJson(b)).toList()
          : [],
      rooms: json['rooms'] != null
          ? (json['rooms'] as List).map((r) => Room.fromJson(r)).toList()
          : [],
    );
  }
}