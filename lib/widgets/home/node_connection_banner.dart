import 'package:flutter/material.dart';
import 'package:guptik/screens/mediaplayer/mobile_main_layout.dart';
import 'package:guptik/services/node/node_link_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/screens/node/pair_node_screen.dart';
import 'package:guptik/services/node/node_auth.dart';

const Color _gold = Color(0xFFD4AF37);

class NodeConnectionBanner extends StatefulWidget {
  const NodeConnectionBanner({super.key});

  @override
  State<NodeConnectionBanner> createState() => _NodeConnectionBannerState();
}

class _NodeConnectionBannerState extends State<NodeConnectionBanner> {
  List<LinkedNode> _nodes = [];
  String? _activeUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final nodes = await NodeLinkService.instance.listDesktops();
    final url = await NodeLinkService.instance.connectBest();
    if (!mounted) return;
    setState(() {
      _nodes = nodes;
      _activeUrl = url;
      _loading = false;
    });
  }

  Future<void> _openPlayer() async {
    final user = Supabase.instance.client.auth.currentUser;
    final url = _activeUrl ?? await NodeLinkService.instance.connectBest();
    if (!mounted) return;
    final viewerOnly = !NodeAuth.instance.isPaired;
    if ((url == null || url.isEmpty) && !viewerOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No desktop on this account yet. Open GupTik on the PC with the same email.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobileMainLayout(gatewayUrl: url ?? '', currentUserUid: user?.id ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(color: _gold, minHeight: 2),
      );
    }
    final n = _nodes.isEmpty ? null : _nodes.first;
    final ok = _activeUrl != null && _activeUrl!.isNotEmpty;
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(ok ? Icons.check_circle : Icons.desktop_windows, color: ok ? Colors.greenAccent : _gold),
        title: Text(
          ok ? 'Node: ${n?.model ?? "Desktop"}' : (_nodes.isEmpty ? 'No desktop on this account' : 'Desktop found — tap Connect'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          ok ? _activeUrl! : 'Same email on PC + phone is enough. No QR required.',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PairNodeScreen()));
                if (mounted) setState(() {});
              },
              child: Text(NodeAuth.instance.isPaired ? 'Paired' : 'Pair', style: const TextStyle(color: _gold)),
            ),
            TextButton(
              onPressed: (ok || !NodeAuth.instance.isPaired) ? _openPlayer : _refresh,
              child: Text(ok ? 'Open' : (NodeAuth.instance.isPaired ? 'Connect' : 'Watch'), style: const TextStyle(color: _gold)),
            ),
          ],
        ),
        onTap: _refresh,
      ),
    );
  }
}
