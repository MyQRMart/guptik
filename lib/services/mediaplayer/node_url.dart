import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/services/node/node_auth.dart';

/// Sanitizes and resolves GupTik media-node URLs.
/// Same-account desktop_devices + mp_channels. Empty = unknown (UI must say so).
class NodeUrl {
  NodeUrl._();

  static String sanitize(String? url) {
    if (url == null) return '';
    var clean = url.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.isEmpty) return '';

    final isLocal = RegExp(
          r'^(https?://)?(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)',
        ).hasMatch(clean) ||
        RegExp(r'^(https?://)?\d{1,3}(\.\d{1,3}){3}').hasMatch(clean);

    if (isLocal) {
      clean = clean.replaceFirst(RegExp(r'^https://'), 'http://');
      if (!clean.startsWith('http://')) clean = 'http://$clean';
      if (!RegExp(r':\d+').hasMatch(clean.replaceFirst('http://', ''))) {
        clean = '$clean:55000';
      }
    } else {
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'https://$clean';
      }
    }

    if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
    return clean;
  }

  static bool _isPlaceholder(String url) {
    final u = url.toLowerCase();
    return u.contains('your-tunnel') ||
        (u.contains('guptik.myqrmart.com') && !u.contains('-guptik.myqrmart.com'));
  }

  static Future<bool> alive(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> candidates() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final urls = <String>[];

    void add(String? raw) {
      final u = sanitize(raw);
      if (u.isEmpty || _isPlaceholder(u) || urls.contains(u)) return;
      urls.add(u);
    }

    try {
      final devices = await Supabase.instance.client
          .from('desktop_devices')
          .select('device_id, public_url, last_active_at')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 6));
      for (final r in (devices as List)) {
        add(r['public_url']?.toString());
        // Only the PC we paired with may receive our pairing token.
        if (r['device_id']?.toString() == NodeAuth.instance.paired?.nodeId) {
          NodeAuth.instance.trustOrigin(sanitize(r['public_url']?.toString()));
        }
      }
    } catch (e) {
      debugPrint('NodeUrl devices: $e');
    }

    try {
      final channels = await Supabase.instance.client
          .from('mp_channels')
          .select('tunnel_url')
          .or('owner_uid.eq.${user.id},channel_id.eq.${user.id}')
          .limit(5)
          .timeout(const Duration(seconds: 6));
      for (final r in (channels as List)) {
        add(r['tunnel_url']?.toString());
      }
    } catch (e) {
      debugPrint('NodeUrl channels: $e');
    }

    return urls;
  }

  /// This user's node. Pings candidates; falls back to first URL if none answer.
  static Future<String?> resolveMine() async {
    // A paired PC wins: its token is only ever sent to these origins.
    final paired = NodeAuth.instance.paired;
    if (paired != null) {
      for (final raw in [paired.tunnelUrl, paired.lanUrl]) {
        final u = sanitize(raw);
        if (u.isNotEmpty && await alive(u)) return u;
      }
    }
    final urls = await candidates();
    if (urls.isEmpty) return null;
    for (final u in urls) {
      if (await alive(u)) return u;
    }
    return urls.first;
  }
}
