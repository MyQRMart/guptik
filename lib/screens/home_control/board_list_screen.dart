import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/home_control/board_model.dart';
import '../../services/home_control/home_control_services.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';
import 'switch_control_screen.dart';

class BoardListScreen extends StatefulWidget {
  final String homeId;
  final String homeName;
  const BoardListScreen({super.key, required this.homeId, required this.homeName});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final _supabase = Supabase.instance.client;
  List<Board> _boards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    final res = await _supabase.from('hc_boards').select('*, switches(*)').eq('home_id', widget.homeId);
    if(mounted) setState(() {
      _boards = (res as List).map((e) => Board.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  void _showAddBoardDialog() {
    final idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Board'),
        content: TextField(controller: idController, decoration: const InputDecoration(hintText: 'Board ID (e.g. BOARD_001)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await HomeControlService().validateAndClaimBoard(boardId: idController.text.trim(), homeId: widget.homeId);
                  _loadBoards();
                } catch(e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Claim'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DynamicThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homeName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: _boards.length,
          itemBuilder: (context, index) {
            final board = _boards[index];
            return GlassCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SwitchControlScreen(boardId: board.id, boardName: board.name))),
              child: ListTile(
                leading: Icon(Icons.developer_board, color: board.status == BoardStatus.online ? Colors.green : Colors.red),
                title: Text(board.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${board.switches.length} Switches', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBoardDialog,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}