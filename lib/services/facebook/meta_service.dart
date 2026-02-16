import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class MetaService {
  static const String _graphApiVersion = "v19.0";
  Map<String, dynamic>? _cachedCredentials;

  // ---------------------------------------------------------------------------
  // 🔐 HELPER: Fetch Credentials from Supabase
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> _getCredentials() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("User not logged in to App");
    
    if (_cachedCredentials != null) return _cachedCredentials!;

    try {
      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .single();
      _cachedCredentials = response;
      return response;
    } catch (e) {
      throw Exception("Configure settings first.");
    }
  }

  // ---------------------------------------------------------------------------
  // 📸 1. GET CONTENT (Posts, Reels, Stories)
  // ---------------------------------------------------------------------------
  Future<List<MetaContent>> getContent(SocialPlatform platform, ContentType filter) async {
    final creds = await _getCredentials();
    final String? accessToken = creds['facebook_page_access_token'] ?? creds['facebook_user_access_token'];
    
    if (accessToken == null) return [];

    String url = '';
    
    // --- A. INSTAGRAM LOGIC ---
    if (platform == SocialPlatform.instagram) {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return [];

      if (filter == ContentType.story) {
        url = 'https://graph.facebook.com/$_graphApiVersion/$igId/stories?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count&access_token=$accessToken';
      } else if (filter == ContentType.mention) {
        url = 'https://graph.facebook.com/$_graphApiVersion/$igId/tags?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count&access_token=$accessToken';
      } else {
        url = 'https://graph.facebook.com/$_graphApiVersion/$igId/media?fields=id,caption,media_type,media_product_type,media_url,thumbnail_url,like_count,comments_count&access_token=$accessToken';
      }
    } 
    // --- B. FACEBOOK LOGIC ---
    else {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return [];

      if (filter == ContentType.story) {
        return []; 
      } else {
        url = 'https://graph.facebook.com/$_graphApiVersion/$pageId/feed?fields=id,message,full_picture,likes.summary(true),comments.summary(true),created_time&access_token=$accessToken';
      }
    }

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        debugPrint("API Error: ${response.body}");
        return [];
      }

      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];
      final List<dynamic> items = data['data'];

      List<MetaContent> results = [];

      for (var item in items) {
        ContentType itemType = ContentType.post;

        if (platform == SocialPlatform.instagram) {
          if (filter == ContentType.story) {
            itemType = ContentType.story;
          } else if (filter == ContentType.mention) {
            itemType = ContentType.mention;
          } else if (item['media_product_type'] == 'REELS') {
            itemType = ContentType.reel;
          }
          
          String img = item['media_url'] ?? '';
          if (item['media_type'] == 'VIDEO' && item['thumbnail_url'] != null) {
            img = item['thumbnail_url'];
          }

          if (filter == itemType) {
            results.add(MetaContent(
              id: item['id'],
              platform: platform,
              type: itemType,
              imageUrl: img,
              caption: item['caption'] ?? '',
              likes: item['like_count'] ?? 0,
              comments: item['comments_count'] ?? 0,
            ));
          }
        } else {
          results.add(MetaContent(
            id: item['id'],
            platform: platform,
            type: ContentType.post,
            imageUrl: item['full_picture'] ?? 'https://via.placeholder.com/150',
            caption: item['message'] ?? '',
            likes: item['likes']?['summary']?['total_count'] ?? 0,
            comments: item['comments']?['summary']?['total_count'] ?? 0,
          ));
        }
      }
      return results;
    } catch (e) {
      debugPrint("Error fetching content: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 2. UPLOAD POST (Binary Upload Fix)
  // ---------------------------------------------------------------------------
  Future<bool> uploadPost(SocialPlatform platform, File imageFile, String caption) async {
    final creds = await _getCredentials();
    final String? accessToken = creds['facebook_page_access_token'] ?? creds['facebook_user_access_token'];
    
    if (accessToken == null) return false;

    // --- A. FACEBOOK UPLOAD ---
    if (platform == SocialPlatform.facebook) {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return false;

      var uri = Uri.parse('https://graph.facebook.com/$_graphApiVersion/$pageId/photos');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['access_token'] = accessToken;
      request.fields['message'] = caption;
      request.files.add(await http.MultipartFile.fromPath('source', imageFile.path));

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        return response.statusCode == 200;
      } catch (e) {
        debugPrint("FB Upload Error: $e");
        return false;
      }
    } 
    
    // --- B. INSTAGRAM UPLOAD (Binary Upload Fix) ---
    else {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return false;

      try {
        // Step 1: Upload to Supabase to get Public URL
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
        
        // ✅ CRITICAL FIX: Read file as bytes first to bypass FileSystem attributes
        final bytes = await imageFile.readAsBytes();
        final String fileExt = path.extension(imageFile.path).replaceAll('.', ''); // e.g., 'jpg' or 'png'

        await Supabase.instance.client.storage.from('post_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExt', // Explicitly set content type
            upsert: true,                  // Force overwrite if needed
          ),
        );

        final String publicUrl = Supabase.instance.client.storage.from('post_images').getPublicUrl(fileName);

        // Step 2: Create Media Container
        final containerUrl = Uri.parse('https://graph.facebook.com/$_graphApiVersion/$igId/media');
        final containerResponse = await http.post(containerUrl, body: {
          'image_url': publicUrl,
          'caption': caption,
          'access_token': accessToken,
        });

        if (containerResponse.statusCode != 200) {
           debugPrint("IG Container Error: ${containerResponse.body}");
           return false;
        }

        final String creationId = json.decode(containerResponse.body)['id'];

        // Step 3: Publish Container
        final publishUrl = Uri.parse('https://graph.facebook.com/$_graphApiVersion/$igId/media_publish');
        final publishResponse = await http.post(publishUrl, body: {
          'creation_id': creationId,
          'access_token': accessToken,
        });

        return publishResponse.statusCode == 200;

      } catch (e) {
        debugPrint("IG Upload Error: $e");
        return false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 💬 3. GET UNIFIED INBOX (FB + IG Merged)
  // ---------------------------------------------------------------------------
  Future<List<MetaChat>> getUnifiedInbox() async {
    final creds = await _getCredentials();
    
    final String? fbPageId = creds['facebook_account_id'];
    final String? igAccountId = creds['instagram_account_id'];
    final String? accessToken = creds['facebook_page_access_token'] ?? creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    List<MetaChat> allChats = [];

    // Fetch FB
    if (fbPageId != null) {
      final fbUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$fbPageId/conversations?fields=id,updated_time,messages.limit(1){message,from,created_time},unread_count&access_token=$accessToken');
      try {
        final fbResponse = await http.get(fbUrl);
        if (fbResponse.statusCode == 200) {
          final fbData = json.decode(fbResponse.body);
          if (fbData.containsKey('data')) {
            final List<dynamic> fbConvos = fbData['data'];
            for (var conv in fbConvos) {
              allChats.add(_mapConversationToChat(conv, SocialPlatform.facebook));
            }
          }
        }
      } catch (e) { debugPrint("FB Inbox Error: $e"); }
    }

    // Fetch IG
    if (igAccountId != null) {
      final igUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igAccountId/conversations?platform=instagram&fields=id,updated_time,messages.limit(1){message,from,created_time},unread_count&access_token=$accessToken');
      try {
        final igResponse = await http.get(igUrl);
        if (igResponse.statusCode == 200) {
          final igData = json.decode(igResponse.body);
          if (igData.containsKey('data')) {
            final List<dynamic> igConvos = igData['data'];
            for (var conv in igConvos) {
              allChats.add(_mapConversationToChat(conv, SocialPlatform.instagram));
            }
          }
        }
      } catch (e) { debugPrint("IG Inbox Error: $e"); }
    }

    // Sort Newest First
    allChats.sort((a, b) {
      DateTime? timeA = _parseIsoTime(a.rawTimestamp);
      DateTime? timeB = _parseIsoTime(b.rawTimestamp);
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA); 
    });

    return allChats;
  }

  // ---------------------------------------------------------------------------
  // 🗨️ 4. GET SPECIFIC CHAT MESSAGES (Detail Screen)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getChatMessages(String conversationId) async {
    final creds = await _getCredentials();
    final String? accessToken = creds['facebook_page_access_token'] ?? creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$conversationId/messages?fields=message,from,created_time&limit=20&access_token=$accessToken');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawMsgs = data['data'];
        
        return rawMsgs.map((m) {
          return {
            'message': m['message'] ?? '',
            'is_from_me': false, // Logic to determine sender needed for perfection
            'created_time': m['created_time'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error loading chat details: $e");
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 📨 5. SEND MESSAGE (Reply Capability)
  // ---------------------------------------------------------------------------
  Future<bool> sendMessage(String conversationId, String message) async {
    final creds = await _getCredentials();
    final String? accessToken = creds['facebook_page_access_token'] ?? creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    // Use the /messages endpoint to send a reply
    final url = Uri.parse('https://graph.facebook.com/$_graphApiVersion/$conversationId/messages');

    try {
      final response = await http.post(url, body: {
        'recipient': json.encode({'id': conversationId}), 
        'message': message, 
        'access_token': accessToken,
      });

      if (response.statusCode != 200) {
         debugPrint("Send Error: ${response.body}");
         return false;
      }
      return true;
    } catch (e) {
      debugPrint("Send Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠️ HELPERS
  // ---------------------------------------------------------------------------
  MetaChat _mapConversationToChat(dynamic conv, SocialPlatform platform) {
    final lastMsgData = conv['messages']?['data']?[0];
    final String messageText = lastMsgData?['message'] ?? 'Attachment sent';
    final String senderName = lastMsgData?['from']?['username'] ?? lastMsgData?['from']?['name'] ?? 'User';
    final String rawTime = lastMsgData?['created_time'];
    final String displayTime = _formatTime(rawTime);
    
    return MetaChat(
      id: conv['id'],
      senderName: senderName,
      lastMessage: messageText,
      time: displayTime,
      rawTimestamp: rawTime,
      avatarUrl: '', 
      platform: platform, 
      isUnread: (conv['unread_count'] ?? 0) > 0,
    );
  }

  DateTime? _parseIsoTime(String? isoTime) {
    if (isoTime == null) return null;
    return DateTime.tryParse(isoTime);
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final date = DateTime.parse(isoTime);
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}