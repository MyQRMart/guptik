import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A PC node this phone has been paired with (via the guptik://pair QR / link).
class PairedNode {
  PairedNode({required this.nodeId, required this.token, required this.name, this.tunnelUrl, this.lanUrl});
  final String nodeId;
  final String token; // gt1.<id>.<secret>, only ever sent to this node's own origins
  final String name;
  final String? tunnelUrl;
  final String? lanUrl;

  Map<String, dynamic> toJson() => {'n': nodeId, 't': token, 'name': name, 'u': tunnelUrl, 'l': lanUrl};
  static PairedNode? fromJson(Map<String, dynamic> m) {
    final t = m['t']?.toString() ?? '';
    if (!t.startsWith('gt1.')) return null;
    return PairedNode(
      nodeId: m['n']?.toString() ?? '',
      token: t,
      name: m['name']?.toString() ?? 'My PC',
      tunnelUrl: m['u']?.toString(),
      lanUrl: m['l']?.toString(),
    );
  }
}

enum PairResult { ok, invalidLink, rejected, unreachable }

/// Holds the pairing token in secure storage (never SharedPreferences) and decides
/// which origins may receive it. Origins of other people's nodes never get it.
class NodeAuth extends ChangeNotifier {
  NodeAuth._();
  static final NodeAuth instance = NodeAuth._();

  static const _key = 'paired_node_v1';
  static const _storage = FlutterSecureStorage();

  PairedNode? _paired;
  final Set<String> _extraOrigins = {};
  bool _loaded = false;

  /// True after the node answered 401 to our token (revoked or the PC was reset).
  final ValueNotifier<bool> pairingRejected = ValueNotifier(false);

  PairedNode? get paired => _paired;
  bool get isPaired => _paired != null;

  /// Sync access for widgets/players; valid once [load] completed (done at app start).
  String? get token => _paired?.token;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        _paired = PairedNode.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('NodeAuth.load: $e');
    }
    notifyListeners();
  }

  static String originOf(String url) {
    final u = Uri.tryParse(url);
    if (u == null || !u.hasAuthority) return '';
    return '${u.scheme}://${u.authority}';
  }

  /// A discovered URL (e.g. from the account's desktop_devices row) for the paired node.
  void trustOrigin(String url) {
    final o = originOf(url);
    if (o.isNotEmpty && isPaired) _extraOrigins.add(o);
  }

  bool isOwnOrigin(String origin) {
    final p = _paired;
    if (p == null || origin.isEmpty) return false;
    if (_extraOrigins.contains(origin)) return true;
    for (final u in [p.tunnelUrl, p.lanUrl]) {
      if (u != null && u.isNotEmpty && originOf(u) == origin) return true;
    }
    return false;
  }

  /// Parses `guptik://pair?v=1&n=..&t=..&u=..&l=..&name=..`.
  static PairedNode? parseLink(String link) {
    final u = Uri.tryParse(link.trim());
    if (u == null || u.scheme != 'guptik' || u.host != 'pair') return null;
    final q = u.queryParameters;
    final t = q['t'] ?? '';
    if (q['v'] != '1' || !RegExp(r'^gt1\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]{16,}$').hasMatch(t)) return null;
    String? clean(String? s) => (s == null || s.isEmpty) ? null : s;
    final tunnel = clean(q['u']);
    final lan = clean(q['l']);
    if (tunnel == null && lan == null) return null;
    return PairedNode(nodeId: q['n'] ?? '', token: t, name: q['name'] ?? 'My PC', tunnelUrl: tunnel, lanUrl: lan);
  }

  /// Checks the token against the node (GET /admin/devices: 403 = valid device token,
  /// 401 = unknown/revoked) and stores it only when the node accepted it.
  Future<PairResult> pairFromLink(String link) async {
    final node = parseLink(link);
    if (node == null) return PairResult.invalidLink;
    var reached = false;
    for (final base in [node.tunnelUrl, node.lanUrl]) {
      if (base == null) continue;
      try {
        final r = await http
            .get(Uri.parse('$base/admin/devices'), headers: {'Authorization': 'Bearer ${node.token}'})
            .timeout(const Duration(seconds: 6));
        reached = true;
        if (r.statusCode == 401) return PairResult.rejected;
        if (r.statusCode == 403 || r.statusCode == 200) {
          await _save(node);
          return PairResult.ok;
        }
      } catch (_) {}
    }
    return reached ? PairResult.rejected : PairResult.unreachable;
  }

  Future<void> _save(PairedNode node) async {
    await _storage.write(key: _key, value: jsonEncode(node.toJson()));
    _paired = node;
    _extraOrigins.clear();
    pairingRejected.value = false;
    // Let the existing node-discovery code prefer this PC.
    final prefs = await SharedPreferences.getInstance();
    if (node.nodeId.isNotEmpty) await prefs.setString('linked_device_id', node.nodeId);
    final url = node.tunnelUrl ?? node.lanUrl;
    if (url != null) await prefs.setString('linked_node_url', url);
    notifyListeners();
  }

  Future<void> unpair() async {
    await _storage.delete(key: _key);
    _paired = null;
    _extraOrigins.clear();
    pairingRejected.value = false;
    notifyListeners();
  }

  void markRejected() {
    if (isPaired && !pairingRejected.value) pairingRejected.value = true;
  }
}
