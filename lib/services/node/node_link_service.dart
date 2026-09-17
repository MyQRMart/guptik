import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';

class LinkedNode {
  final String deviceId;
  final String model;
  final String status;
  final String? publicUrl;
  final DateTime? lastActive;
  final bool reachable;

  LinkedNode({
    required this.deviceId,
    required this.model,
    required this.status,
    this.publicUrl,
    this.lastActive,
    this.reachable = false,
  });

  bool get isFresh {
    if (lastActive == null) return status == 'online';
    return DateTime.now().toUtc().difference(lastActive!).inMinutes < 3;
  }
}

class NodeLinkService {
  NodeLinkService._();
  static final NodeLinkService instance = NodeLinkService._();

  Future<List<LinkedNode>> listDesktops() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    try {
      final rows = await Supabase.instance.client
          .from('desktop_devices')
          .select('device_id, device_model, status, public_url, last_active_at')
          .eq('user_id', user.id)
          .order('last_active_at', ascending: false);
      final out = <LinkedNode>[];
      for (final r in (rows as List)) {
        final url = NodeUrl.sanitize(r['public_url']?.toString());
        DateTime? ts;
        try {
          ts = DateTime.tryParse(r['last_active_at']?.toString() ?? '');
        } catch (_) {}
        out.add(LinkedNode(
          deviceId: r['device_id']?.toString() ?? '',
          model: r['device_model']?.toString() ?? 'Desktop',
          status: r['status']?.toString() ?? 'unknown',
          publicUrl: url.isEmpty ? null : url,
          lastActive: ts,
        ));
      }
      return out;
    } catch (e) {
      debugPrint('listDesktops: $e');
      return [];
    }
  }

  Future<bool> ping(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<String?> connectBest() async {
    final nodes = await listDesktops();
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getString('linked_device_id');

    final ordered = [
      ...nodes.where((n) => n.deviceId == pinned),
      ...nodes.where((n) => n.deviceId != pinned),
    ];

    for (final n in ordered) {
      final url = n.publicUrl;
      if (url == null || url.isEmpty) continue;
      if (await ping(url)) {
        await prefs.setString('linked_device_id', n.deviceId);
        await prefs.setString('linked_node_url', url);
        return url;
      }
    }

    final fromDb = await NodeUrl.resolveMine();
    if (fromDb != null && fromDb.isNotEmpty) {
      await prefs.setString('linked_node_url', fromDb);
      return fromDb;
    }
    return prefs.getString('linked_node_url');
  }

  Future<void> accept(LinkedNode node) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_device_id', node.deviceId);
    if (node.publicUrl != null) {
      await prefs.setString('linked_node_url', node.publicUrl!);
    }
  }
}
