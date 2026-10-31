import 'package:flutter/material.dart';
import 'package:guptik/services/mediaplayer/local_media_history_service.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:guptik/widgets/mediaplayer/mobile_video_player_widget.dart';
import 'package:intl/intl.dart';

/// Watch history kept on this phone (up to 500 videos). No login or node needed.
class MobileLocalHistoryScreen extends StatefulWidget {
  const MobileLocalHistoryScreen({super.key});

  @override
  State<MobileLocalHistoryScreen> createState() => _MobileLocalHistoryScreenState();
}

class _MobileLocalHistoryScreenState extends State<MobileLocalHistoryScreen> {
  final _svc = LocalMediaHistoryService.instance;
  final _search = TextEditingController();
  List<LocalHistoryRecord> _records = [];
  List<MapEntry<String, int>> _tags = [];
  String? _tag;
  bool _paused = false;
  bool _loading = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final records = await _svc.getAll(query: _search.text, tag: _tag);
    final tags = await _svc.topTags(limit: 12);
    final paused = await _svc.isPaused();
    final total = await _svc.count();
    if (!mounted) return;
    setState(() {
      _records = records;
      _tags = tags;
      _paused = paused;
      _total = total;
      _loading = false;
    });
  }

  String _dayLabel(DateTime utc) {
    final d = utc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('d MMM yyyy').format(d);
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear history on this phone?', style: TextStyle(color: Colors.white)),
        content: const Text('This removes every record stored on this device. Your node is not affected.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _svc.clear();
      _load();
    }
  }

  void _open(LocalHistoryRecord r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: MobileVideoPlayerWidget(video: r.toPlayerVideo()),
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('On this phone ($_total/${LocalMediaHistoryService.maxRecords})',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: _paused ? 'Resume history' : 'Pause history',
            icon: Icon(_paused ? Icons.play_circle_outline : Icons.pause_circle_outline, color: Colors.white),
            onPressed: () async {
              await _svc.setPaused(!_paused);
              _load();
            },
          ),
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            onPressed: _total == 0 ? null : _confirmClear,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                if (_paused)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(10),
                    child: const Text('History is paused. New videos will not be saved.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => _load(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search title, channel or tag',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                if (_tags.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _tags.map((e) {
                        final selected = _tag == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('#${e.key}', style: const TextStyle(fontSize: 11)),
                            selected: selected,
                            selectedColor: Colors.orange,
                            backgroundColor: const Color(0xFF1E1E1E),
                            onSelected: (_) {
                              setState(() => _tag = selected ? null : e.key);
                              _load();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(child: _list()),
              ],
            ),
    );
  }

  Widget _list() {
    if (_records.isEmpty) {
      return const Center(child: Text('Nothing here yet.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (context, i) {
        final r = _records[i];
        final label = _dayLabel(r.watchedAt);
        final showHeader = i == 0 || _dayLabel(_records[i - 1].watchedAt) != label;
        final thumb = r.thumbnailUrl?.isNotEmpty == true
            ? r.thumbnailUrl!
            : '${NodeUrl.sanitize(r.creatorUrl)}/player/video/thumbnail/${r.videoId}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            Dismissible(
              key: ValueKey(r.videoId),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await _svc.remove(r.videoId);
                _load();
              },
              child: ListTile(
                onTap: () => _open(r),
                leading: SizedBox(
                  width: 112,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[850],
                          child: Image.network(thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.play_circle_fill, color: Colors.orange)),
                        ),
                        if (r.progress > 0)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: LinearProgressIndicator(
                              value: r.progress,
                              minHeight: 3,
                              color: Colors.orange,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                title: Text(r.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(
                  [
                    r.channelName,
                    DateFormat('h:mm a').format(r.watchedAt.toLocal()),
                    if (r.watchCount > 1) 'watched ${r.watchCount}×',
                    if (r.tags.isNotEmpty) r.tags.take(3).map((t) => '#$t').join(' '),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
