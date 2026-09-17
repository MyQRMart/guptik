import 'package:flutter/material.dart';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/services/mediaplayer/mobile_bridge_service.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';

/// History / Watch Later / Playlists / Drafts — from THIS user's node.
class MobileLibraryScreen extends StatefulWidget {
  final String mode; // history | saved | playlists | drafts
  final String nodeUrl;
  final String? channelId;

  const MobileLibraryScreen({
    super.key,
    required this.mode,
    required this.nodeUrl,
    this.channelId,
  });

  @override
  State<MobileLibraryScreen> createState() => _MobileLibraryScreenState();
}

class _MobileLibraryScreenState extends State<MobileLibraryScreen> {
  late final MobileBridgeService _bridge;
  List<PlayerVideo> _videos = [];
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  bool get _isMeta => widget.mode == 'playlists' || widget.mode == 'drafts';

  @override
  void initState() {
    super.initState();
    _bridge = MobileBridgeService(gatewayUrl: NodeUrl.sanitize(widget.nodeUrl));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.mode == 'playlists') {
        _rows = await _bridge.fetchPlaylists(widget.channelId ?? '');
        _videos = [];
      } else if (widget.mode == 'drafts') {
        _rows = await _bridge.fetchDrafts(widget.channelId ?? '');
        _videos = [];
      } else if (widget.mode == 'saved') {
        _videos = await _bridge.fetchSavedList();
      } else {
        _videos = await _bridge.fetchHistoryList();
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach your node.';
        _loading = false;
      });
    }
  }

  String get _title {
    switch (widget.mode) {
      case 'saved':
        return 'Watch Later';
      case 'playlists':
        return 'Playlists';
      case 'drafts':
        return 'Drafts';
      default:
        return 'History';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _isMeta ? _metaList() : _videoList(),
                ),
    );
  }

  Widget _metaList() {
    if (_rows.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nothing here yet.', style: TextStyle(color: Colors.white54))),
        ],
      );
    }
    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (context, i) {
        final r = _rows[i];
        return ListTile(
          title: Text(
            (r['name'] ?? r['title'] ?? 'Untitled').toString(),
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            widget.mode == 'playlists'
                ? '${r['video_count'] ?? 0} videos'
                : (r['description'] ?? '').toString(),
            style: const TextStyle(color: Colors.white54),
          ),
        );
      },
    );
  }

  Widget _videoList() {
    if (_videos.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nothing here yet.', style: TextStyle(color: Colors.white54))),
        ],
      );
    }
    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, i) {
        final v = _videos[i];
        return ListTile(
          title: Text(v.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(v.channelName, style: const TextStyle(color: Colors.white54)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(backgroundColor: Colors.black),
                  body: MobileVideoPlayerWidget(video: v),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
