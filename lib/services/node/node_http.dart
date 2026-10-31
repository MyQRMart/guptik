import 'dart:convert';
import 'package:http/http.dart' as http;
import 'node_auth.dart';

/// HTTP client for GupTik node gateways.
///  * Your own paired node: sends the per-phone bearer token (secure storage).
///  * Other people's nodes: the paired token is NEVER sent. Read-only player GETs
///    (stream, thumbnail, stats, watch, channel profile/videos) use a short-lived anonymous
///    viewer token fetched from that node's POST /viewer/token (the "incognito" viewer).
class NodeHttp extends http.BaseClient {
  NodeHttp([http.Client? inner]) : _inner = inner ?? http.Client();
  final http.Client _inner;

  static final _viewerRead = RegExp(r'^/(player/video/(stream|thumbnail|stickers|stats)|watch|channel/(profile|videos))/[^/]+$');
  static final Map<String, _Viewer> _viewer = {};
  static final Map<String, DateTime> _cooldown = {};

  /// Headers for widgets that cannot use this client (Image.network, VideoPlayerController).
  static Map<String, String> headersFor(String url) {
    final o = NodeAuth.originOf(url);
    if (o.isEmpty) return const {};
    final auth = NodeAuth.instance;
    if (auth.isOwnOrigin(o) && auth.token != null) return {'Authorization': 'Bearer ${auth.token}'};
    final v = _viewer[o];
    if (v != null && v.valid) return {'Authorization': 'Bearer ${v.token}'};
    return const {};
  }

  /// Fetches (or reuses) an anonymous viewer token for the node at [url]. Null when the node has none.
  static Future<String?> viewerToken(String url) async {
    final o = NodeAuth.originOf(url);
    if (o.isEmpty) return null;
    final c = _viewer[o];
    if (c != null && c.valid) return c.token;
    final cool = _cooldown[o];
    if (cool != null && DateTime.now().isBefore(cool)) return null;
    try {
      final r = await http.post(Uri.parse('$o/viewer/token')).timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final m = jsonDecode(r.body) as Map;
        final ttl = (m['expires_in'] as num?)?.toInt() ?? 3600;
        final v = _Viewer(m['token'].toString(), DateTime.now().add(Duration(seconds: ttl > 300 ? ttl - 300 : ttl)));
        _viewer[o] = v;
        return v.token;
      }
    } catch (_) {}
    _cooldown[o] = DateTime.now().add(const Duration(minutes: 2)); // older node without /viewer/token
    return null;
  }

  /// Preloads headers for [url] so sync consumers (video player, images) can use [headersFor].
  static Future<Map<String, String>> prepareHeaders(String url) async {
    final o = NodeAuth.originOf(url);
    if (o.isNotEmpty && !NodeAuth.instance.isOwnOrigin(o)) await viewerToken(url);
    return headersFor(url);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final hasAuth = request.headers.keys.any((k) => k.toLowerCase() == 'authorization');
    var usedOwnToken = false;
    if (!hasAuth) {
      final o = NodeAuth.originOf(request.url.toString());
      final auth = NodeAuth.instance;
      if (auth.isOwnOrigin(o) && auth.token != null) {
        request.headers['Authorization'] = 'Bearer ${auth.token}';
        usedOwnToken = true;
      } else if (request.method == 'GET' && _viewerRead.hasMatch(request.url.path)) {
        final t = await viewerToken(request.url.toString());
        if (t != null) request.headers['Authorization'] = 'Bearer $t';
      }
    }
    final res = await _inner.send(request);
    if (usedOwnToken && res.statusCode == 401) NodeAuth.instance.markRejected();
    return res;
  }
}

class _Viewer {
  _Viewer(this.token, this.expires);
  final String token;
  final DateTime expires;
  bool get valid => DateTime.now().isBefore(expires);
}

/// Shared client; use instead of top-level `http.get/post/...` for node calls.
final NodeHttp nodeHttp = NodeHttp();
