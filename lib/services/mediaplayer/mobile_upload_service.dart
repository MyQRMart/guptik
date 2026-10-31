import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:guptik/services/node/node_http.dart';

class MobileUploadService {
  final String gatewayUrl;
  final _supabase = Supabase.instance.client;

  MobileUploadService({required this.gatewayUrl});

  Future<bool> uploadVideoFromMobile({
    required File videoFile,
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    required String visibility,
    required bool isReel,
    required bool isMonetized,
    required String channelName,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final videoId = const Uuid().v4();
      final personalUrl = await NodeUrl.resolveMine();
      if (personalUrl == null || personalUrl.isEmpty) {
        debugPrint('Upload aborted: no node URL');
        return false;
      }
      final cleanTunnelUrl = personalUrl;
      final safeUrl = personalUrl;
       
      // A. SYNC METADATA GLOBALLY TO SUPABASE
      await _supabase.from('mp_channels').upsert({
        'owner_uid': currentUser.id,
        'channel_id': currentUser.id, 
        'channel_name': channelName,
        'tunnel_url': cleanTunnelUrl, // Ensure this is saved for future lookups
      }, onConflict: 'channel_id');

      await _supabase.from('mp_videos').insert({
        'video_id': videoId,
        'channel_id': currentUser.id, // 🚀 Matches the desktop channel record
        'creator_uid': currentUser.id,
        'channel_name': channelName,
        'title': title,
        'description': description,
        'tags': tags,
        'creator_cloudflare_url': cleanTunnelUrl, 
        'thumbnail_url': '$safeUrl/player/video/thumbnail/$videoId', 
        'category': category.toLowerCase(),
        'visibility': visibility,
        'is_reel': isReel,
        'is_monetized': isMonetized,
      });

      // B. STREAM RAW VIDEO BYTES TO GATEWAY
      final request = http.Request('POST', Uri.parse('$safeUrl/player/video/upload'));
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['x-video-id'] = videoId;
      request.headers['x-creator-uid'] = currentUser.id;
      request.headers['x-channel-id'] = currentUser.id; // 🚀 Passes channel id to local node
      request.headers['x-title'] = Uri.encodeComponent(title);
      request.headers['x-description'] = Uri.encodeComponent(description);
      request.headers['x-category'] = category.toLowerCase();
      request.headers['x-visibility'] = visibility;
      request.headers['x-is-reel'] = isReel.toString();
      request.headers['x-is-monetized'] = isMonetized.toString();
      request.headers['x-channel-name'] = Uri.encodeComponent(channelName);
      request.headers['x-tags'] = Uri.encodeComponent(tags.join(','));

      request.bodyBytes = await videoFile.readAsBytes();
      
      final streamedResponse = await nodeHttp.send(request);
      return streamedResponse.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Mobile cross-sync upload failure: $e");
      return false;
    }
  }
}