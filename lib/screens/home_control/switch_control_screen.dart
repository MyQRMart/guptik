import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/home_control/switch_model.dart';
import '../../providers/home_control/home_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';

class SwitchControlScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  const SwitchControlScreen({super.key, required this.boardId, required this.boardName});

  @override
  State<SwitchControlScreen> createState() => _SwitchControlScreenState();
}

class _SwitchControlScreenState extends State<SwitchControlScreen> {
  final _supabase = Supabase.instance.client;
  List<SwitchDevice> _switches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSwitches();
    _subscribe();
  }

  void _subscribe() {
    _supabase.channel('public:hc_switches:board_id=${widget.boardId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'hc_switches',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'board_id', value: widget.boardId),
        callback: (payload) {
          final newRecord = payload.newRecord;
          final index = _switches.indexWhere((s) => s.id == newRecord['id']);
          if (index != -1) {
            setState(() {
              _switches[index] = SwitchDevice.fromJson(newRecord);
            });
          }
        }
      ).subscribe();
  }

  Future<void> _loadSwitches() async {
    final res = await _supabase.from('hc_switches').select().eq('board_id', widget.boardId).order('position');
    if(mounted) setState(() {
      _switches = (res as List).map((e) => SwitchDevice.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _toggle(SwitchDevice s) async {
    setState(() {
      final index = _switches.indexWhere((e) => e.id == s.id);
      _switches[index] = s.copyWith(state: !s.state);
    });
    await _supabase.from('hc_switches').update({'state': !s.state}).eq('id', s.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<HomeThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: _isLoading ? const Center(child: CircularProgressIndicator()) : GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
          itemCount: _switches.length,
          itemBuilder: (context, index) {
            return GlassSwitchControlTile(
              device: _switches[index],
              onToggle: (val) => _toggle(_switches[index]),
            );
          },
        ),
      ),
    );
  }
}