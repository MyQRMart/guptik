import 'dart:convert';
import 'dart:io';
import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:guptik/models/mediaplyer/player_comment_model.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:guptik/services/mediaplayer/live_node_feed.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/services/node/node_http.dart';

class MobileBridgeService {
  final String gatewayUrl; 

  MobileBridgeService({required this.gatewayUrl});

 String get _cleanGateway {
    return NodeUrl.sanitize(gatewayUrl);
  }
  
  Future<List<PlayerVideo>> getRemoteFeed() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('mp_videos')
          .select()
          .order('published_at', ascending: false);
      
      final List<Map<String, dynamic>> allVideos = List<Map<String, dynamic>>.from(response as List);
      
      final List<String> repostIds = allVideos
          .where((v) => v['repost_id'] != null)
          .map((v) => v['repost_id'].toString())
          .toList();

      Map<String, Map<String, dynamic>> originalVideosMap = {};
      if (repostIds.isNotEmpty) {
        final originalsResponse = await supabase
            .from('mp_videos')
            .select('*')
            .filter('id', 'in', repostIds); 
            
        for (final orig in originalsResponse as List) {
          originalVideosMap[orig['id'].toString()] = Map<String, dynamic>.from(orig);
        }
      }

      final mapped = allVideos.map((v) {
        if (v['repost_id'] != null) {
          final orig = originalVideosMap[v['repost_id'].toString()];
          if (orig != null) {
            v['video_id'] = orig['video_id'] ?? orig['id']; 
            v['id'] = orig['id']; 
            v['creator_uid'] = orig['creator_uid'];
            v['creator_cloudflare_url'] = orig['creator_cloudflare_url'];
            v['thumbnail_url'] = orig['thumbnail_url'];
            v['original_channel_name'] = orig['channel_name'];
            v['is_repost'] = true;
          }
        }
        final nodeUrl = v['creator_cloudflare_url'] ?? _cleanGateway;
        return PlayerVideo.fromJson(v, nodeUrl);
      }).toList();
      return LiveNodeFeed.onlyLive(mapped);
      
    } catch (e) {
      debugPrint("Bridge Feed Error: $e");
      return [];
    }
  }

  Future<List<PlayerVideo>> fetchChannelVideos(String nodeUrl, String channelId) async {
    try {
      final safeUrl = nodeUrl.startsWith('http') ? nodeUrl : 'https://$nodeUrl';
      final response = await nodeHttp.get(Uri.parse('$safeUrl/channel/videos/$channelId'));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((v) => PlayerVideo.fromJson(v, safeUrl)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Bridge Channel Videos Error: $e');
      return [];
    }
  }

  Future<bool> postReaction(String videoId, String creatorUid, String reactionType) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId, 
          'creator_uid': creatorUid, 
          'reaction_type': reactionType
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'already_liked') return false;
        return true; 
      }
      return false;
    } catch (e) { 
      debugPrint('Bridge Reaction Error: $e');
      return false; 
    }
  }

  Future<void> addVideoView(String videoId, String viewerUid) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'video_id': videoId, 'viewer_uid': viewerUid}),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'view_added') {
        try {
          final supabase = Supabase.instance.client;
          final current = await supabase
              .from('mp_videos')
              .select('view_count')
              .eq('video_id', videoId)
              .maybeSingle();
          final int views = ((current?['view_count'] as int?) ?? 0) + 1;
          await supabase
              .from('mp_videos')
              .update({'view_count': views})
              .eq('video_id', videoId);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('View Tracker Error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchVideoStats(String videoId) async {
    try {
      final response = await nodeHttp.get(Uri.parse('$_cleanGateway/player/video/stats/$videoId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Stats Fetch Error: $e');
    }
    return null;
  }

  Future<bool> postComment(
    String videoId, 
    String creatorUid, 
    String commentText, {
    String? parentCommentId,
    String? viewerName,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId, 
          'creator_uid': creatorUid, 
          'comment_text': commentText,
          'parent_comment_id': parentCommentId,
          'viewer_name': viewerName ?? 'Mobile Creator',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Comment Error: $e');
      return false;
    }
  }

  // 🚀 FIX: now returns parsed PlayerComment objects (with reaction counts,
  // edit/delete state, and nested replies) instead of raw dynamic JSON, and
  // sends the viewer's uid so the gateway can include their own reaction.
  Future<List<PlayerComment>> fetchComments(String videoId, {String? viewerUid}) async {
    try {
      final response = await nodeHttp.get(
        Uri.parse('$_cleanGateway/player/video/comments/$videoId'),
        headers: {
          'Content-Type': 'application/json',
          if (viewerUid != null) 'X-Viewer-Uid': viewerUid,
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((c) => PlayerComment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Comments Error: $e');
      return [];
    }
  }

  // 🚀 ADDED: fetches replies for a specific parent comment.
  Future<List<PlayerComment>> fetchReplies(String videoId, String parentCommentId, {String? viewerUid}) async {
    try {
      final response = await nodeHttp.get(
        Uri.parse('$_cleanGateway/player/video/comments/$videoId/replies/$parentCommentId'),
        headers: {
          'Content-Type': 'application/json',
          if (viewerUid != null) 'X-Viewer-Uid': viewerUid,
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((c) => PlayerComment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Replies Error: $e');
      return [];
    }
  }

  // 🚀 ADDED: edits an existing comment (only succeeds if editorUid owns it).
  Future<bool> editComment(String commentId, String newText, String editorUid) async {
    try {
      final response = await nodeHttp.put(
        Uri.parse('$_cleanGateway/player/video/comment/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment_text': newText, 'editor_uid': editorUid}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Edit Comment Error: $e');
      return false;
    }
  }

  // 🚀 ADDED: soft-deletes a comment (only succeeds if deleterUid owns it).
  Future<bool> deleteComment(String commentId, String deleterUid) async {
    try {
      final response = await nodeHttp.delete(
        Uri.parse('$_cleanGateway/player/video/comment/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deleter_uid': deleterUid}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete Comment Error: $e');
      return false;
    }
  }

  // 🚀 ADDED: toggles a reaction on a comment. Returns the new active
  // reaction type, or null if the reaction was removed (toggled off).
  Future<String?> toggleCommentReaction({
    required String commentId,
    required String reactorUid,
    required String reactionType,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/comment/$commentId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reactor_uid': reactorUid, 'reaction_type': reactionType}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['active'] == true) {
          return data['reaction_type']?.toString();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Comment Reaction Error: $e');
      return null;
    }
  }

  // 🚀 ADDED: reports a comment for moderation review.
  Future<bool> reportComment({
    required String commentId,
    required String reporterUid,
    required String reason,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/comment/$commentId/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reporter_uid': reporterUid, 'reason': reason}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Report Comment Error: $e');
      return false;
    }
  }

  Future<bool> saveVideo(String videoId, String creatorUid) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'viewer_uid': Supabase.instance.client.auth.currentUser?.id,
          'folder_name': 'Watch Later',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Save Error: $e');
      return false;
    }
  }

  Future<bool> repostVideo({
    required String originalVideoId,
    required String originalCreatorUid,
    String? originalCreatorName,
    String? originalChannelName,
    required String reposterUid,
    String? reposterChannelName,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/repost'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'original_video_id': originalVideoId,
          'original_creator_uid': originalCreatorUid,
          'original_creator_name': originalCreatorName ?? '',
          'original_channel_name': originalChannelName ?? '',
          'reposter_uid': reposterUid,
          'reposter_channel_name': reposterChannelName ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'already_reposted') return false;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Bridge Repost Error: $e');
      return false;
    }
  }

  Future<bool> shareVideo({
    required String videoId,
    required String creatorUid,
    String shareMethod = 'link',
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'share_method': shareMethod,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Bridge Share Error: $e');
      return false;
    }
  }

  Future<bool> setVideoInterest({
    required String videoId,
    required String creatorUid,
    required String watcherUid,
    required bool? interested,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/interest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'watcher_uid': watcherUid,
          'interested': interested,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Interest Error: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchStickers(String videoId) async {
    try {
      final response = await nodeHttp.get(Uri.parse('$_cleanGateway/player/video/stickers/$videoId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Stickers Error: $e');
      return [];
    }
  }

  // 🚀 ADDED: posts a new shoppable sticker to the gateway's
  // POST /player/video/sticker endpoint. Metadata goes in headers, the
  // (optional) product image goes as raw bytes in the body — same pattern
  // mobile_upload_service.dart already uses for video uploads.
  Future<bool> addSticker({
    required String videoId,
    required String productName,
    String description = '',
    double timestampInVideo = 0,
    double durationOnScreen = 8,
    double? mrp,
    double? salePrice,
    String currency = 'USD',
    String? linkUrl,
    Map<String, double>? clickableZone,
    File? imageFile,
  }) async {
    try {
      final request = http.Request('POST', Uri.parse('$_cleanGateway/player/video/sticker'));
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['x-video-id'] = videoId;
      request.headers['x-product-name'] = Uri.encodeComponent(productName);
      request.headers['x-description'] = Uri.encodeComponent(description);
      request.headers['x-timestamp'] = timestampInVideo.toString();
      request.headers['x-duration'] = durationOnScreen.toString();
      if (mrp != null) request.headers['x-mrp'] = mrp.toString();
      if (salePrice != null) request.headers['x-price'] = salePrice.toString();
      request.headers['x-currency'] = currency;
      if (linkUrl != null && linkUrl.isNotEmpty) {
        request.headers['x-link-url'] = Uri.encodeComponent(linkUrl);
      }
      if (clickableZone != null) {
        request.headers['x-clickable-zone'] = Uri.encodeComponent(jsonEncode(clickableZone));
      }

      request.bodyBytes = imageFile != null ? await imageFile.readAsBytes() : <int>[];

      final streamedResponse = await nodeHttp.send(request);
      return streamedResponse.statusCode == 200;
    } catch (e) {
      debugPrint('Add Sticker Error: $e');
      return false;
    }
  }

 Future<Map<String, dynamic>?> fetchChannelProfile(String channelId) async {
    try {
      final response = await nodeHttp.get(Uri.parse('$_cleanGateway/channel/profile/$channelId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Profile Fetch Error: $e');
      return null;
    }
  }

  Future<bool> logWatchHistory({
    required String videoId,
    required String creatorUid,
    required int durationSeconds,
    required double percentCompleted,
    required String sessionId,
    String? channelId,
  }) async {
    if (_cleanGateway.isEmpty) return false;
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/player/video/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'video_id': videoId,
          'creator_uid': creatorUid,
          'channel_id': channelId ?? creatorUid,
          'watch_duration_seconds': durationSeconds,
          'percent_completed': percentCompleted,
          'session_id': sessionId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('History log error: $e');
      return false;
    }
  }

  Future<List<PlayerVideo>> fetchHistoryList() async =>
      _fetchNodeVideoList('/player/video/history/list');

  Future<List<PlayerVideo>> fetchSavedList() async =>
      _fetchNodeVideoList('/player/video/saved/list');

  Future<List<PlayerVideo>> _fetchNodeVideoList(String path) async {
    if (_cleanGateway.isEmpty) return [];
    try {
      final response = await nodeHttp.get(Uri.parse('$_cleanGateway$path'));
      if (response.statusCode != 200) return [];
      final List data = jsonDecode(response.body) as List;
      final parsed = data
          .map((v) => PlayerVideo.fromJson(
                Map<String, dynamic>.from(v as Map),
                _cleanGateway,
              ))
          .toList();
      return _hydrateFromDirectory(parsed);
    } catch (e) {
      debugPrint('Node list $path error: $e');
      return [];
    }
  }

  Future<List<PlayerVideo>> _hydrateFromDirectory(List<PlayerVideo> videos) async {
    final missing = videos
        .where((v) => v.title.isEmpty || v.title == 'Untitled Broadcast')
        .map((v) => v.videoId)
        .where((id) => id.isNotEmpty)
        .toList();
    if (missing.isEmpty) return videos;
    try {
      final rows = await Supabase.instance.client
          .from('mp_videos')
          .select()
          .filter('video_id', 'in', missing);
      final map = <String, Map<String, dynamic>>{};
      for (final row in rows as List) {
        final m = Map<String, dynamic>.from(row as Map);
        map[m['video_id'].toString()] = m;
      }
      return videos.map((v) {
        final extra = map[v.videoId];
        if (extra == null || v.title.isNotEmpty) return v;
        final node = extra['creator_cloudflare_url']?.toString() ?? _cleanGateway;
        return PlayerVideo.fromJson(extra, NodeUrl.sanitize(node));
      }).toList();
    } catch (e) {
      debugPrint('Hydrate directory error: $e');
      return videos;
    }
  }

  Future<bool> checkSubscription({
    required String channelId,
    required String subscriberUid,
  }) async {
    if (_cleanGateway.isEmpty) return false;
    try {
      final response = await nodeHttp.get(
        Uri.parse('$_cleanGateway/channel/subscribe/status/$channelId/$subscriberUid'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['is_subscribed'] == true;
      }
    } catch (e) {
      debugPrint('Sub check error: $e');
    }
    return false;
  }

  Future<bool?> toggleSubscription({
    required String channelId,
    required String subscriberUid,
  }) async {
    if (_cleanGateway.isEmpty) return null;
    try {
      final response = await nodeHttp.post(
        Uri.parse('$_cleanGateway/channel/subscribe/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channel_id': channelId,
          'subscriber_uid': subscriberUid,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['is_subscribed'] == true;
      }
    } catch (e) {
      debugPrint('Sub toggle error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchPlaylists(String channelId) async {
    if (_cleanGateway.isEmpty) return [];
    try {
      final response = await nodeHttp.get(
        Uri.parse('$_cleanGateway/player/playlists?channel_id=$channelId'),
      );
      if (response.statusCode != 200) return [];
      return (jsonDecode(response.body) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Playlists fetch error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDrafts(String channelId) async {
    if (_cleanGateway.isEmpty) return [];
    try {
      final response = await nodeHttp.get(
        Uri.parse('$_cleanGateway/player/drafts?channel_id=$channelId'),
      );
      if (response.statusCode != 200) return [];
      return (jsonDecode(response.body) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Drafts fetch error: $e');
      return [];
    }
  }
}