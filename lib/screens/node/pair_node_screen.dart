import 'package:flutter/material.dart';
import 'package:guptik/screens/profilepopup/qr_scanner_screen.dart';
import 'package:guptik/services/node/node_auth.dart';
import 'package:guptik/services/profilepopup_service/deep_link_navigator.dart';

/// Opens the pairing screen for a guptik://pair link received from outside the app.
void handlePairLink(String link) {
  final ctx = DeepLinkNavigator.navigatorKey.currentContext;
  if (ctx == null) return;
  Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => PairNodeScreen(initialLink: link)));
}

const Color _gold = Color(0xFFD4AF37);

/// Pair this phone with your GupTik PC (scan the QR in Desktop → Settings → Phone pairing).
/// Without pairing the app still works as an anonymous viewer: public videos only, no uploads.
class PairNodeScreen extends StatefulWidget {
  const PairNodeScreen({super.key, this.initialLink});
  final String? initialLink;

  @override
  State<PairNodeScreen> createState() => _PairNodeScreenState();
}

class _PairNodeScreenState extends State<PairNodeScreen> {
  final _auth = NodeAuth.instance;
  bool _busy = false;
  String? _message;
  final _paste = TextEditingController();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_changed);
    final l = widget.initialLink;
    if (l != null) WidgetsBinding.instance.addPostFrameCallback((_) => _confirmAndPair(l));
  }

  @override
  void dispose() {
    _auth.removeListener(_changed);
    _paste.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _scan() async {
    final raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
    if (raw != null && mounted) await _confirmAndPair(raw);
  }

  Future<void> _confirmAndPair(String link) async {
    final node = NodeAuth.parseLink(link);
    if (node == null) {
      setState(() => _message = 'That is not a GupTik pairing code.');
      return;
    }
    final where = node.tunnelUrl ?? node.lanUrl ?? '';
    // A pairing link can arrive from any app or website, so always confirm what we are about to trust.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pair with this PC?'),
        content: Text('"${node.name}" at\n$where\n\nOnly continue if you just showed this code on your own GupTik Desktop.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pair')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final r = await _auth.pairFromLink(link);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (r) {
        PairResult.ok => 'Paired. This phone can now use your PC.',
        PairResult.invalidLink => 'That pairing code is not valid.',
        PairResult.rejected => 'Your PC rejected this code. It may have been revoked or already replaced. Create a new one on the PC.',
        PairResult.unreachable => 'Could not reach your PC. Check that GupTik Desktop is running and try again.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _auth.paired;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pair with PC', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF111111),
            child: ListTile(
              leading: Icon(p != null ? Icons.verified_user : Icons.visibility, color: p != null ? Colors.greenAccent : _gold),
              title: Text(p != null ? 'Paired with ${p.name}' : 'Viewer mode (not paired)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                p != null
                    ? 'You can upload, like, comment and subscribe through your PC.'
                    : 'You can watch public videos and see basic details. Pair your PC to upload or interact.',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          ),
          if (_auth.pairingRejected.value && p != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Your PC no longer accepts this phone. Pair again from the desktop app.',
                  style: TextStyle(color: Colors.orangeAccent)),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(p == null ? 'Scan pairing QR' : 'Scan a new pairing QR'),
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paste,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'or paste a guptik://pair link',
              labelStyle: TextStyle(color: Colors.white54),
            ),
            onSubmitted: (v) => _confirmAndPair(v),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator(color: _gold)),
          if (_message != null)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: Colors.white70))),
          if (p != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _busy ? null : () => _auth.unpair(),
              child: const Text('Unpair this phone', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ],
      ),
    );
  }
}
