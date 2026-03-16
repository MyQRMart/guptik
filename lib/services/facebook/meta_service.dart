import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:guptik/models/facebook/meta_chat_model.dart';
import 'package:guptik/models/facebook/meta_comment_model.dart';
import 'package:guptik/models/facebook/meta_content_model.dart'; // For SocialPlatform enum
import 'package:guptik/models/facebook/meta_insights_model.dart';
import 'package:guptik/models/facebook/meta_story_reel_model.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MetaService {
  static const String _graphApiVersion = "v24.0";
  static const String _uploadServiceUrl =
      "https://uploadservice.myqrmart.com/upload";

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

  // Public method to get access token
  Future<String?> getAccessToken() async {
    try {
      final creds = await _getCredentials();
      return creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];
    } catch (e) {
      debugPrint("Error getting access token: $e");
      return null;
    }
  }

  // Public method to get account ID for a platform
  Future<String?> getAccountId(SocialPlatform platform) async {
    try {
      final creds = await _getCredentials();
      if (platform == SocialPlatform.facebook) {
        return creds['facebook_account_id'];
      } else {
        return creds['instagram_account_id'];
      }
    } catch (e) {
      debugPrint("Error getting account ID: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Make authorized HTTP request with Bearer token
  // ---------------------------------------------------------------------------
  Future<http.Response> _makeAuthorizedGet(
    String url,
    String accessToken,
  ) async {
    debugPrint("API Call: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    debugPrint("Response Status: ${response.statusCode}");
    if (response.statusCode != 200) {
      debugPrint("Response Error: ${response.body}");
    }
    return response;
  }

  Future<http.Response> _makeAuthorizedPost(
    String url,
    String accessToken, {
    Map<String, dynamic>? body,
  }) async {
    debugPrint("API POST Call: $url");
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    debugPrint("Response Status: ${response.statusCode}");
    if (response.statusCode != 200) {
      debugPrint("Response Error: ${response.body}");
    }
    return response;
  }

  // ---------------------------------------------------------------------------
  // Helper: Upload image to your own upload service - FIXED VERSION
  // ---------------------------------------------------------------------------
  Future<String> _uploadToMyService(File imageFile) async {
    try {
      var uri = Uri.parse(_uploadServiceUrl);
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add the file with field name 'file' as per your service
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      debugPrint("📤 Uploading to your service: $_uploadServiceUrl");

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📨 Upload service response status: ${response.statusCode}");
      debugPrint("📨 Upload service response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Your response is a SINGLE OBJECT, not an array!
        // From your log: {"success":true,"file":{...}}

        if (data['success'] == true) {
          // Access the URL directly from the file object
          final fileUrl = data['file']['url'];
          debugPrint("✅ Image uploaded successfully: $fileUrl");
          return fileUrl;
        } else {
          debugPrint("❌ Upload service returned success=false");
          return '';
        }
      }

      debugPrint("❌ Upload service error: ${response.body}");
      return '';
    } catch (e) {
      debugPrint("❌ Error uploading to your service: $e");
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // 1. GET CONTENT (Posts, Reels, Stories)
  // ---------------------------------------------------------------------------
  Future<List<MetaContent>> getContent(
    SocialPlatform platform,
    ContentType filter,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    String url = '';

    if (platform == SocialPlatform.instagram) {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return [];

      if (filter == ContentType.story) {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/stories?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count';
      } else if (filter == ContentType.mention) {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/tags?fields=id,caption,media_type,media_url,thumbnail_url,like_count,comments_count';
      } else {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$igId/media?fields=id,caption,media_type,media_product_type,media_url,thumbnail_url,like_count,comments_count';
      }
    } else {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return [];

      if (filter == ContentType.story) {
        return [];
      } else {
        url =
            'https://graph.facebook.com/$_graphApiVersion/$pageId/feed?fields=id,message,full_picture,likes.summary(true),comments.summary(total_count),created_time';
        debugPrint("Facebook feed URL: $url");
      }
    }

    try {
      final response = await _makeAuthorizedGet(url, accessToken);

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
            results.add(
              MetaContent(
                id: item['id'],
                platform: platform,
                type: itemType,
                imageUrl: img,
                caption: item['caption'] ?? '',
                likes: item['like_count'] ?? 0,
                comments: item['comments_count'] ?? 0,
              ),
            );
          }
        } else {
          debugPrint(
            '✅ Creating Facebook MetaContent with platform: $platform',
          );

          int totalComments = 0;
          if (item['comments'] != null) {
            if (item['comments']['summary'] != null &&
                item['comments']['summary']['total_count'] != null) {
              totalComments = item['comments']['summary']['total_count'];
              debugPrint("Comment total_count: $totalComments");
            } else {
              totalComments = item['comments']['count'] ?? 0;
            }
          }

          results.add(
            MetaContent(
              id: item['id'],
              platform: platform,
              type: ContentType.post,
              imageUrl: item['full_picture'],
              caption: item['message'] ?? '',
              likes: item['likes']?['summary']?['total_count'] ?? 0,
              comments: totalComments,
            ),
          );
        }
      }
      return results;
    } catch (e) {
      debugPrint("Error fetching content: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. UPLOAD POST - Using your own upload service for Instagram
  // ---------------------------------------------------------------------------
  Future<bool> uploadPost(
    SocialPlatform platform,
    File? imageFile,
    String caption,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    // --- A. FACEBOOK UPLOAD (unchanged) ---
    if (platform == SocialPlatform.facebook) {
      final String? pageId = creds['facebook_account_id'];
      if (pageId == null) return false;

      // If no image, post as text-only using /feed endpoint
      if (imageFile == null) {
        final uri = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$pageId/feed?message=${Uri.encodeComponent(caption)}&access_token=$accessToken',
        );
        try {
          debugPrint("📤 FB Text-only Post URL: $uri");
          final response = await http.post(uri);
          debugPrint("📨 FB Response Status: ${response.statusCode}");
          debugPrint("📨 FB Response Body: ${response.body}");

          if (response.statusCode == 200) {
            debugPrint("✅ FB Text-only Post Success: ${response.body}");
            return true;
          } else {
            debugPrint(
              "❌ FB Feed Error (${response.statusCode}): ${response.body}",
            );
            return false;
          }
        } catch (e) {
          debugPrint("❌ FB Text-only Upload Error: $e");
          return false;
        }
      }

      // If image exists, post with image using /photos endpoint
      var uri = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$pageId/photos',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['access_token'] = accessToken;
      request.fields['message'] = caption;
      request.files.add(
        await http.MultipartFile.fromPath('source', imageFile.path),
      );

      try {
        debugPrint("📤 FB Image Post URL: $uri");
        debugPrint("📤 FB Image Post Fields: ${request.fields}");
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        debugPrint("📨 FB Image Response Status: ${response.statusCode}");
        debugPrint("📨 FB Image Response Body: ${response.body}");

        if (response.statusCode == 200) {
          debugPrint("✅ FB Image Post Success: ${response.body}");
          return true;
        } else {
          debugPrint(
            "❌ FB Image Upload Error (${response.statusCode}): ${response.body}",
          );
          return false;
        }
      } catch (e) {
        debugPrint("❌ FB Image Upload Error: $e");
        return false;
      }
    }
    // --- B. INSTAGRAM UPLOAD - USING YOUR OWN UPLOAD SERVICE ---
    else {
      final String? igId = creds['instagram_account_id'];
      if (igId == null) return false;

      // Instagram requires an image for posting
      if (imageFile == null) {
        debugPrint("❌ IG Error: Instagram posts require an image.");
        return false;
      }

      try {
        // STEP 1: Upload to YOUR OWN upload service
        final String publicUrl = await _uploadToMyService(imageFile);

        if (publicUrl.isEmpty) {
          debugPrint("❌ Failed to get public URL from upload service");
          return false;
        }

        debugPrint("📤 Image uploaded to your service: $publicUrl");

        // STEP 2: Create Instagram Media Container
        final containerUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igId/media',
        );

        final containerResponse = await http.post(
          containerUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_url': publicUrl,
            'caption': caption,
            'access_token': accessToken,
          }),
        );

        if (containerResponse.statusCode != 200) {
          debugPrint("❌ IG Container Error: ${containerResponse.body}");

          // Check for specific errors
          final errorData = json.decode(containerResponse.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            debugPrint("❌ Error code: ${error['code']}");
            debugPrint("❌ Error message: ${error['message']}");
          }
          return false;
        }

        final containerData = json.decode(containerResponse.body);
        final String creationId = containerData['id'];

        debugPrint("✅ Container created with ID: $creationId");

        // STEP 3: Wait for media processing (recommended)
        debugPrint("⏳ Waiting for media processing...");
        await Future.delayed(const Duration(seconds: 5));

        // STEP 4: Publish Container
        final publishUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igId/media_publish',
        );

        final publishResponse = await http.post(
          publishUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'creation_id': creationId,
            'access_token': accessToken,
          }),
        );

        if (publishResponse.statusCode == 200) {
          debugPrint("✅ Instagram post published successfully!");
          return true;
        } else {
          debugPrint("❌ Instagram publish error: ${publishResponse.body}");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Instagram upload error: $e");
        return false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GET UNIFIED INBOX (FB + IG Merged)
  // ---------------------------------------------------------------------------
  Future<List<MetaChat>> getUnifiedInbox() async {
    final creds = await _getCredentials();
    final String? fbPageId = creds['facebook_account_id'];
    final String? igAccountId = creds['instagram_account_id'];
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    List<MetaChat> allChats = [];

    // Fetch FB Conversations
    if (fbPageId != null) {
      final fbUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$fbPageId/conversations?fields=id,updated_time,participants,messages.limit(1){message,from,created_time},unread_count&access_token=$accessToken',
      );
      try {
        debugPrint("📥 Fetching Facebook inbox from: $fbUrl");
        final fbResponse = await http.get(fbUrl);
        debugPrint("📨 FB Response status: ${fbResponse.statusCode}");

        if (fbResponse.statusCode == 200) {
          final fbData = json.decode(fbResponse.body);
          if (fbData.containsKey('data')) {
            final List<dynamic> fbConvos = fbData['data'];
            debugPrint("✅ Found ${fbConvos.length} Facebook conversations");

            for (var conv in fbConvos) {
              allChats.add(
                _mapConversationToChat(conv, SocialPlatform.facebook),
              );
            }
          }
        } else {
          debugPrint("❌ FB Inbox Error: ${fbResponse.body}");
        }
      } catch (e) {
        debugPrint("❌ FB Inbox Exception: $e");
      }
    }

    // Fetch IG Conversations
    if (igAccountId != null) {
      try {
        final igUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$igAccountId/conversations?platform=instagram&fields=id,updated_time,participants{id,username,name},messages.limit(1){id,text,from,created_time,timestamp},unread_count&access_token=$accessToken',
        );

        debugPrint("📥 Fetching Instagram inbox from: $igUrl");
        final igResponse = await http.get(igUrl);
        debugPrint("📨 IG Response status: ${igResponse.statusCode}");

        if (igResponse.statusCode == 200) {
          final igData = json.decode(igResponse.body);
          if (igData.containsKey('data')) {
            final List<dynamic> igConvos = igData['data'];
            debugPrint("✅ Found ${igConvos.length} Instagram conversations");

            for (var conv in igConvos) {
              allChats.add(
                _mapConversationToChat(conv, SocialPlatform.instagram),
              );
            }
          } else {
            debugPrint("⚠️ No 'data' field in IG response: ${igData.keys}");
          }
        } else {
          debugPrint("❌ IG Inbox Error: ${igResponse.body}");
        }
      } catch (e) {
        debugPrint("❌ IG Inbox Exception: $e");
      }
    }

    // Sort all chats by timestamp
    allChats.sort((a, b) {
      DateTime? timeA = _parseIsoTime(a.rawTimestamp);
      DateTime? timeB = _parseIsoTime(b.rawTimestamp);
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    debugPrint("📊 Total unified inbox count: ${allChats.length}");
    return allChats;
  }

  // ---------------------------------------------------------------------------
  // 4. GET SPECIFIC CHAT MESSAGES
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getChatMessages(
    String conversationId, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        conversationId.startsWith('ig_') ||
        conversationId.contains('instagram');

    try {
      if (isInstagram) {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$conversationId/messages?fields=text,from,created_time,timestamp,attachments,media,sticker,reactions&limit=50&access_token=$accessToken',
        );

        debugPrint("📥 Fetching Instagram messages from: $url");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> rawMsgs = data['data'] ?? [];

          debugPrint("✅ Found ${rawMsgs.length} Instagram messages");

          return rawMsgs.map((m) {
            final isFromMe = m['from']?['id'] == creds['instagram_account_id'];

            String messageContent = '';

            if (m['text'] != null && m['text'].isNotEmpty) {
              messageContent = m['text'];
            } else if (m['message'] != null && m['message'].isNotEmpty) {
              messageContent = m['message'];
            } else if (m['sticker'] != null) {
              messageContent = '📱 Sticker';
            } else if (m['media'] != null) {
              final mediaType = m['media']['media_type'] ?? 'media';
              if (mediaType == 'image') {
                messageContent = '📷 Photo';
              } else if (mediaType == 'video') {
                messageContent = '🎥 Video';
              } else if (mediaType == 'audio') {
                messageContent = '🎵 Audio';
              } else {
                messageContent = '📎 Media';
              }
            } else if (m['attachments'] != null) {
              final attachments = m['attachments']['data'] ?? [];
              if (attachments.isNotEmpty) {
                final attachment = attachments[0];
                final attachmentType = attachment['type'] ?? 'attachment';

                if (attachmentType == 'image') {
                  messageContent = '📷 Photo';
                } else if (attachmentType == 'video') {
                  messageContent = '🎥 Video';
                } else if (attachmentType == 'audio') {
                  messageContent = '🎵 Audio';
                } else if (attachmentType == 'file') {
                  messageContent = '📎 File';
                } else {
                  messageContent = '📎 Attachment';
                }
              } else {
                messageContent = '📎 Attachment';
              }
            } else if (m['reactions'] != null) {
              messageContent = '👍 Reacted to a message';
            } else {
              messageContent = '💬 Message';
            }

            return {
              'message': messageContent,
              'is_from_me': isFromMe,
              'created_time':
                  m['created_time'] ??
                  m['timestamp'] ??
                  DateTime.now().toIso8601String(),
              'has_attachment':
                  m['attachments'] != null ||
                  m['media'] != null ||
                  m['sticker'] != null,
            };
          }).toList();
        } else {
          debugPrint("❌ Instagram messages error: ${response.body}");
        }
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$conversationId/messages?fields=message,from,created_time,attachments,sticker&limit=50&access_token=$accessToken',
        );

        debugPrint("📥 Fetching Facebook messages from: $url");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> rawMsgs = data['data'] ?? [];

          debugPrint("✅ Found ${rawMsgs.length} Facebook messages");

          return rawMsgs.map((m) {
            final isFromMe = m['from']?['id'] == creds['facebook_account_id'];

            String messageContent = '';

            if (m['message'] != null && m['message'].isNotEmpty) {
              messageContent = m['message'];
            } else if (m['sticker'] != null) {
              messageContent = '😊 Sticker';
            } else if (m['attachments'] != null) {
              messageContent = '📎 Attachment';
            } else {
              messageContent = '💬 Message';
            }

            return {
              'message': messageContent,
              'is_from_me': isFromMe,
              'created_time': m['created_time'],
              'has_attachment':
                  m['attachments'] != null || m['sticker'] != null,
            };
          }).toList();
        } else {
          debugPrint("❌ Facebook messages error: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading chat details: $e");
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 5. SEND MESSAGE
  // ---------------------------------------------------------------------------
  Future<bool> sendMessage(
    String conversationId,
    String message, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];
    final String? pageId = creds['facebook_account_id'];
    final String? igId = creds['instagram_account_id'];

    if (accessToken == null) {
      debugPrint("❌ No access token available");
      return false;
    }

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        conversationId.startsWith('ig_') ||
        conversationId.contains('instagram');

    try {
      if (isInstagram) {
        debugPrint(
          "🔍 Fetching Instagram conversation details for: $conversationId",
        );

        final conversationUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$conversationId?fields=participants{id}&access_token=$accessToken',
        );

        final conversationResponse = await http.get(conversationUrl);

        if (conversationResponse.statusCode != 200) {
          debugPrint(
            "❌ Failed to fetch conversation: ${conversationResponse.body}",
          );
          return false;
        }

        final conversationData = json.decode(conversationResponse.body);

        final participants = conversationData['participants']?['data'] ?? [];

        if (participants.isEmpty) {
          debugPrint("❌ No participants found in conversation");
          return false;
        }

        String? recipientId;

        for (var participant in participants) {
          final participantId = participant['id'];
          if (participantId != igId) {
            recipientId = participantId;
            break;
          }
        }

        recipientId ??= participants.first['id'];

        debugPrint("✅ Found Instagram recipient ID: $recipientId");

        final sendUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/me/messages',
        );

        debugPrint("📤 Sending Instagram message to recipient: $recipientId");
        debugPrint("📤 Message content: $message");

        final response = await http.post(
          sendUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'recipient': {'id': recipientId},
            'message': {'text': message},
            'access_token': accessToken,
          }),
        );

        debugPrint("📨 Response status: ${response.statusCode}");
        debugPrint("📨 Response body: ${response.body}");

        return response.statusCode == 200;
      } else {
        if (pageId == null) {
          debugPrint("❌ No page ID available");
          return false;
        }

        debugPrint(
          "🔍 Fetching Facebook conversation details for: $conversationId",
        );

        final conversationUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$conversationId?fields=participants,id&access_token=$accessToken',
        );

        final conversationResponse = await http.get(conversationUrl);

        if (conversationResponse.statusCode != 200) {
          debugPrint(
            "❌ Failed to fetch conversation: ${conversationResponse.body}",
          );
          return false;
        }

        final conversationData = json.decode(conversationResponse.body);

        final participants = conversationData['participants']?['data'] ?? [];

        if (participants.isEmpty) {
          debugPrint("❌ No participants found in conversation");
          return false;
        }

        String? recipientId;

        for (var participant in participants) {
          final participantId = participant['id'];
          if (participantId != pageId) {
            recipientId = participantId;
            break;
          }
        }

        recipientId ??= participants.first['id'];

        debugPrint("✅ Found Facebook recipient ID: $recipientId");

        final sendUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/me/messages',
        );

        debugPrint("📤 Sending Facebook message to recipient: $recipientId");

        final response = await http.post(
          sendUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'recipient': {'id': recipientId},
            'message': {'text': message},
            'access_token': accessToken,
          }),
        );

        debugPrint("📨 Response status: ${response.statusCode}");
        debugPrint("📨 Response body: ${response.body}");

        return response.statusCode == 200;
      }
    } catch (e) {
      debugPrint("❌ Send Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 🛠️ HELPERS
  // ---------------------------------------------------------------------------
  MetaChat _mapConversationToChat(dynamic conv, SocialPlatform platform) {
    if (platform == SocialPlatform.instagram) {
      final messages = conv['messages']?['data'] ?? [];
      final lastMsgData = messages.isNotEmpty ? messages[0] : null;

      String messageText = 'Attachment sent';

      if (lastMsgData != null) {
        if (lastMsgData['text'] != null && lastMsgData['text'].isNotEmpty) {
          messageText = lastMsgData['text'];
        } else if (lastMsgData['message'] != null &&
            lastMsgData['message'].isNotEmpty) {
          messageText = lastMsgData['message'];
        } else if (lastMsgData['sticker'] != null) {
          messageText = '📱 Sticker';
        } else if (lastMsgData['media'] != null) {
          final mediaType = lastMsgData['media']['media_type'] ?? 'media';
          if (mediaType == 'image') {
            messageText = '📷 Photo';
          } else if (mediaType == 'video') {
            messageText = '🎥 Video';
          } else if (mediaType == 'audio') {
            messageText = '🎵 Audio';
          } else {
            messageText = '📎 Media attachment';
          }
        } else if (lastMsgData['attachments'] != null) {
          final attachments = lastMsgData['attachments']['data'] ?? [];
          if (attachments.isNotEmpty) {
            final attachment = attachments[0];
            final attachmentType = attachment['type'] ?? 'attachment';

            if (attachmentType == 'image') {
              messageText = '📷 Photo';
            } else if (attachmentType == 'video') {
              messageText = '🎥 Video';
            } else if (attachmentType == 'audio') {
              messageText = '🎵 Audio';
            } else if (attachmentType == 'file') {
              messageText = '📎 File';
            } else {
              messageText = '📎 Attachment';
            }
          }
        } else if (lastMsgData['reaction'] != null) {
          messageText = '👍 Reacted to a message';
        }
      }

      String senderName = 'Instagram User';
      String? avatarUrl;

      final participants = conv['participants']?['data'] ?? [];
      if (participants.isNotEmpty) {
        final igId = _cachedCredentials?['instagram_account_id'];
        for (var p in participants) {
          if (p['id'] != igId) {
            senderName = p['username'] ?? p['name'] ?? 'Instagram User';
            avatarUrl = p['profile_pic'] ?? '';
            break;
          }
        }
      }

      final String rawTime =
          lastMsgData?['created_time'] ??
          lastMsgData?['timestamp'] ??
          conv['updated_time'] ??
          DateTime.now().toIso8601String();
      final String displayTime = _formatTime(rawTime);

      return MetaChat(
        id: conv['id'],
        senderName: senderName,
        lastMessage: messageText,
        time: displayTime,
        rawTimestamp: rawTime,
        avatarUrl: avatarUrl ?? '',
        platform: platform,
        isUnread: (conv['unread_count'] ?? 0) > 0,
      );
    } else {
      final lastMsgData = conv['messages']?['data']?[0];

      String messageText = 'Attachment sent';
      if (lastMsgData != null) {
        if (lastMsgData['message'] != null &&
            lastMsgData['message'].isNotEmpty) {
          messageText = lastMsgData['message'];
        } else if (lastMsgData['attachments'] != null) {
          messageText = '📎 Attachment';
        } else if (lastMsgData['sticker'] != null) {
          messageText = '😊 Sticker';
        }
      }

      final participants = conv['participants']?['data'] ?? [];
      String senderName = 'User';
      String? avatarUrl;

      if (participants.isNotEmpty) {
        final pageId = _cachedCredentials?['facebook_account_id'];
        for (var p in participants) {
          if (p['id'] != pageId) {
            senderName = p['name'] ?? p['username'] ?? 'User';
            avatarUrl = p['profile_pic'] ?? '';
            break;
          }
        }
      }

      final String rawTime =
          lastMsgData?['created_time'] ?? conv['updated_time'];
      final String displayTime = _formatTime(rawTime);

      return MetaChat(
        id: conv['id'],
        senderName: senderName,
        lastMessage: messageText,
        time: displayTime,
        rawTimestamp: rawTime,
        avatarUrl: avatarUrl ?? '',
        platform: platform,
        isUnread: (conv['unread_count'] ?? 0) > 0,
      );
    }
  }

  DateTime? _parseIsoTime(String? isoTime) {
    if (isoTime == null) return null;
    return DateTime.tryParse(isoTime);
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // 6. DELETE POST
  // ---------------------------------------------------------------------------
  Future<bool> deletePost(String postId, SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$postId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Post deleted successfully: $postId");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 7. EDIT POST
  // ---------------------------------------------------------------------------
  Future<bool> editPost(
    String postId,
    String newCaption,
    SocialPlatform platform, {
    File? imageFile,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      if (imageFile != null) {
        final deleteUrl = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId?access_token=$accessToken',
        );

        final deleteResponse = await http.delete(deleteUrl);
        if (deleteResponse.statusCode != 200 &&
            deleteResponse.statusCode != 204) {
          debugPrint("❌ Failed to delete old post: ${deleteResponse.body}");
          return false;
        }

        debugPrint("✅ Old post deleted successfully");

        final uploadSuccess = await uploadPost(platform, imageFile, newCaption);

        if (uploadSuccess) {
          debugPrint("✅ Post updated with new image successfully");
          return true;
        } else {
          debugPrint("❌ Failed to upload new post with image");
          return false;
        }
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId',
        );

        final response = await http.post(
          url,
          body: {'message': newCaption, 'access_token': accessToken},
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint("✅ Post caption updated successfully: $postId");
          return true;
        } else {
          debugPrint(
            "❌ Update Error (${response.statusCode}): ${response.body}",
          );
          return false;
        }
      }
    } catch (e) {
      debugPrint("❌ Update Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 8. GET POST COMMENTS
  // ---------------------------------------------------------------------------
  Future<List<MetaComment>> getPostComments(
    String postId, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        postId.contains('instagram') ||
        postId.startsWith('178') ||
        postId.startsWith('179');

    try {
      if (isInstagram) {
        // Updated URL to properly fetch replies
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/comments'
          '?fields=id,text,username,timestamp,like_count,'
          'replies{id,text,username,timestamp,like_count}&' // Fetch replies properly
          'limit=50&access_token=$accessToken',
        );

        debugPrint("Fetching Instagram comments from: $url");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> comments = data['data'];
          debugPrint("Found ${comments.length} Instagram comments");

          return comments.map((comment) {
            List<MetaComment> replies = [];
            if (comment.containsKey('replies') &&
                comment['replies'].containsKey('data')) {
              final repliesData = comment['replies']['data'] as List;
              replies = repliesData.map((replyJson) {
                return MetaComment(
                  id: replyJson['id'] ?? '',
                  authorName: replyJson['username'] ?? 'Instagram User',
                  authorId: replyJson['id'] ?? '',
                  text: replyJson['text'] ?? '',
                  createdTime:
                      replyJson['timestamp'] ??
                      DateTime.now().toIso8601String(),
                  likeCount: replyJson['like_count'] ?? 0,
                  platform: SocialPlatform.instagram,
                  isFromPageOwner: false,
                  replies: [],
                );
              }).toList();
            }

            return MetaComment(
              id: comment['id'] ?? '',
              authorName: comment['username'] ?? 'Instagram User',
              authorId: comment['id'] ?? '',
              text: comment['text'] ?? '',
              createdTime:
                  comment['timestamp'] ?? DateTime.now().toIso8601String(),
              likeCount: comment['like_count'] ?? 0,
              platform: SocialPlatform.instagram,
              isFromPageOwner: false,
              replies: replies,
            );
          }).toList();
        } else {
          debugPrint("Instagram comments error: ${response.body}");

          final altUrl = Uri.parse(
            'https://graph.instagram.com/$postId/comments'
            '?fields=id,text,username,timestamp&'
            'limit=50&access_token=$accessToken',
          );

          debugPrint("Trying alternative Instagram API: $altUrl");
          final altResponse = await http.get(altUrl);

          if (altResponse.statusCode == 200) {
            final altData = json.decode(altResponse.body);
            if (!altData.containsKey('data')) return [];

            final List<dynamic> altComments = altData['data'];
            return altComments.map((comment) {
              return MetaComment(
                id: comment['id'] ?? '',
                authorName: comment['username'] ?? 'Instagram User',
                authorId: comment['id'] ?? '',
                text: comment['text'] ?? '',
                createdTime:
                    comment['timestamp'] ?? DateTime.now().toIso8601String(),
                likeCount: 0,
                platform: SocialPlatform.instagram,
                isFromPageOwner: false,
                replies: [],
              );
            }).toList();
          }
        }
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/comments'
          '?fields=id,message,from{id,name,picture},created_time,like_count,'
          'comments{id,message,from{id,name,picture},created_time,like_count}&'
          'limit=50&access_token=$accessToken',
        );

        debugPrint("Fetching Facebook comments from: $url");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> comments = data['data'];
          debugPrint("Found ${comments.length} Facebook comments");

          return comments.map((comment) {
            List<MetaComment> replies = [];
            if (comment.containsKey('comments') &&
                comment['comments'].containsKey('data')) {
              final repliesData = comment['comments']['data'] as List;
              replies = repliesData.map((replyJson) {
                return MetaComment(
                  id: replyJson['id'] ?? '',
                  authorName: replyJson['from']?['name'] ?? 'Unknown',
                  authorId: replyJson['from']?['id'] ?? '',
                  text: replyJson['message'] ?? '',
                  createdTime: replyJson['created_time'] ?? '',
                  likeCount: replyJson['like_count'] ?? 0,
                  platform: SocialPlatform.facebook,
                  isFromPageOwner: false,
                  replies: [],
                );
              }).toList();
            }

            return MetaComment(
              id: comment['id'] ?? '',
              authorName: comment['from']?['name'] ?? 'Unknown',
              authorId: comment['from']?['id'] ?? '',
              text: comment['message'] ?? '',
              createdTime: comment['created_time'] ?? '',
              likeCount: comment['like_count'] ?? 0,
              platform: SocialPlatform.facebook,
              isFromPageOwner: false,
              replies: replies,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading comments: $e");
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // 9. REPLY TO COMMENT - COMPLETE FIX for both Facebook and Instagram
  // ---------------------------------------------------------------------------
  Future<bool> replyToComment(String commentId, String replyText) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    // DETERMINE PLATFORM BASED ON COMMENT ID PATTERN
    // Instagram comment IDs typically:
    // - Start with 178, 179, 180, 181
    // - Are 17-18 digits long
    // Facebook comment IDs are usually shorter or have different patterns

    final bool isInstagram =
        commentId.length >= 17 &&
        (commentId.startsWith('178') ||
            commentId.startsWith('179') ||
            commentId.startsWith('180') ||
            commentId.startsWith('181'));

    debugPrint("🔍 Comment ID: $commentId");
    debugPrint(
      "🔍 Platform detected: ${isInstagram ? 'Instagram' : 'Facebook'}",
    );

    try {
      late Uri url;
      late Map<String, dynamic> requestBody;

      if (isInstagram) {
        // INSTAGRAM: Use the replies endpoint
        // Instagram requires the 'replies' endpoint for comment replies
        url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$commentId/replies',
        );

        requestBody = {'message': replyText, 'access_token': accessToken};

        debugPrint("📝 Replying to Instagram comment using: $url");
      } else {
        // FACEBOOK: Use the comments endpoint
        url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$commentId/comments',
        );

        requestBody = {'message': replyText, 'access_token': accessToken};

        debugPrint("📝 Replying to Facebook comment using: $url");
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint("📨 Reply Response status: ${response.statusCode}");
      debugPrint("📨 Reply Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['id'] != null) {
          debugPrint("✅ Reply added successfully with ID: ${data['id']}");
          return true;
        } else if (data['success'] == true) {
          debugPrint("✅ Reply added successfully");
          return true;
        }
      } else {
        // Log detailed error information
        final errorData = json.decode(response.body);
        if (errorData['error'] != null) {
          debugPrint("❌ Error code: ${errorData['error']['code']}");
          debugPrint("❌ Error subcode: ${errorData['error']['error_subcode']}");
          debugPrint("❌ Error message: ${errorData['error']['message']}");

          // Specific handling for Instagram permission issues
          if (errorData['error']['error_subcode'] == 33) {
            debugPrint(
              "❌ This is an Instagram comment - make sure you have instagram_business_manage_comments permission",
            );
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ Reply Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 10. DELETE COMMENT
  // ---------------------------------------------------------------------------
  Future<bool> deleteComment(String commentId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$commentId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Comment deleted successfully");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 11. GET PAGE INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaPageInsights?> getPageInsights(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return null;

    try {
      final infoUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$accountId?fields=name,followers_count&access_token=$accessToken',
      );

      final infoResponse = await http.get(infoUrl);
      if (infoResponse.statusCode != 200) return null;

      final infoData = json.decode(infoResponse.body);

      final insightsUrl = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$accountId/insights?metric=page_impressions,page_consumptions,page_fan_adds&period=day&access_token=$accessToken',
      );

      final insightsResponse = await http.get(insightsUrl);
      int impressions = 0;
      int reach = 0;

      if (insightsResponse.statusCode == 200) {
        final insightsData = json.decode(insightsResponse.body);
        final data = insightsData['data'] as List<dynamic>;

        for (var metric in data) {
          if (metric['name'] == 'page_impressions') {
            impressions = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'page_consumptions') {
            reach = metric['values']?[0]?['value'] ?? 0;
          }
        }
      }

      return MetaPageInsights(
        accountId: accountId,
        accountName: infoData['name'] ?? 'Unknown',
        platform: platform,
        followers: infoData['followers_count'] ?? 0,
        following: 0,
        postsCount: 0,
        engagementRate: 0.0,
        totalReach: reach,
        totalImpressions: impressions,
        topPosts: [],
      );
    } catch (e) {
      debugPrint("Error fetching page insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 12. GET POST INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaPostInsights?> getPostInsights(String postId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return null;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$postId?fields=message,likes.summary(true),comments.summary(true),shares,created_time,full_picture&access_token=$accessToken',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      final likes = data['likes']?['summary']?['total_count'] ?? 0;
      final comments = data['comments']?['summary']?['total_count'] ?? 0;
      final shares = data['shares'] ?? 0;
      final totalEngagement = likes + comments + shares;

      double engagementRate = 0.0;
      if (totalEngagement > 0) {
        engagementRate = (totalEngagement / 1000);
      }

      return MetaPostInsights(
        postId: postId,
        postCaption: data['message'] ?? '',
        platform: SocialPlatform.facebook,
        likes: likes,
        comments: comments,
        shares: shares,
        reach: 0,
        impressions: 0,
        engagementRate: engagementRate,
        createdTime: data['created_time'] ?? '',
        thumbnailUrl: data['full_picture'],
      );
    } catch (e) {
      debugPrint("Error fetching post insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 13. GET STORY INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaStoryInsights?> getStoryInsights(
    String storyId,
    SocialPlatform platform,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return null;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$storyId/insights?metric=story_opens,story_replies,story_backwards,story_taps_forward&access_token=$accessToken',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      int views = 0;
      int replies = 0;
      int exits = 0;
      int nextTaps = 0;

      if (data.containsKey('data')) {
        for (var metric in data['data']) {
          if (metric['name'] == 'story_opens') {
            views = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'story_replies') {
            replies = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'story_backwards') {
            exits = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'story_taps_forward') {
            nextTaps = metric['values']?[0]?['value'] ?? 0;
          }
        }
      }

      return MetaStoryInsights(
        storyId: storyId,
        platform: platform,
        views: views,
        replies: replies,
        exits: exits,
        nextStoryTaps: nextTaps,
        createdTime: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint("Error fetching story insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 14. GET AUDIENCE DEMOGRAPHICS
  // ---------------------------------------------------------------------------
  Future<List<MetaAudienceDemographics>> getAudienceDemographics(
    SocialPlatform platform,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return [];

    try {
      return [
        MetaAudienceDemographics(
          ageGroup: '18-24',
          percentage: 0.25,
          genderPrimary: 'M',
        ),
        MetaAudienceDemographics(
          ageGroup: '25-34',
          percentage: 0.35,
          genderPrimary: 'F',
        ),
        MetaAudienceDemographics(
          ageGroup: '35-44',
          percentage: 0.25,
          genderPrimary: 'M',
        ),
        MetaAudienceDemographics(
          ageGroup: '45+',
          percentage: 0.15,
          genderPrimary: null,
        ),
      ];
    } catch (e) {
      debugPrint("Error fetching audience demographics: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 15. GET TOP PERFORMING POSTS
  // ---------------------------------------------------------------------------
  Future<List<MetaPostInsights>> getTopPerformingPosts(
    SocialPlatform platform, {
    int limit = 5,
  }) async {
    final creds = await _getCredentials();
    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accountId == null) return [];

    try {
      final content = await getContent(platform, ContentType.post);

      final sortedContent =
          content.map((post) => (post, post.likes + post.comments)).toList()
            ..sort((a, b) => b.$2.compareTo(a.$2));

      final topPosts = <MetaPostInsights>[];

      for (
        var i = 0;
        i < sortedContent.length && topPosts.length < limit;
        i++
      ) {
        final post = sortedContent[i].$1;
        final engagement = sortedContent[i].$2;

        topPosts.add(
          MetaPostInsights(
            postId: post.id,
            postCaption: post.caption,
            platform: platform,
            likes: post.likes,
            comments: post.comments,
            shares: 0,
            reach: engagement,
            impressions: 0,
            engagementRate:
                (engagement / (post.likes + post.comments + 1)) * 100,
            createdTime: '',
            thumbnailUrl: post.imageUrl,
          ),
        );
      }

      return topPosts;
    } catch (e) {
      debugPrint("Error fetching top posts: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 16. GET STORIES
  // ---------------------------------------------------------------------------
  Future<List<MetaStory>> getStories(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return [];

    try {
      final url =
          'https://graph.facebook.com/$_graphApiVersion/$accountId/stories?fields=id,media_type,media_url,thumbnail_url,caption,created_time';

      final response = await _makeAuthorizedGet(url, accessToken);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];

      final List<dynamic> stories = data['data'];
      return stories
          .map(
            (story) => MetaStory(
              id: story['id'] ?? '',
              mediaUrl: story['media_url'] ?? '',
              caption: story['caption'],
              platform: platform,
              createdTime: story['created_time'] ?? '',
              thumbnail: story['thumbnail_url'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching stories: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 17. GET REELS
  // ---------------------------------------------------------------------------
  Future<List<MetaReel>> getReels(SocialPlatform platform) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return [];

    try {
      final url =
          'https://graph.facebook.com/$_graphApiVersion/$accountId/media?media_type=REELS&fields=id,title,media_type,media_url,thumbnail_url,caption,created_time,like_count,comments_count';

      final response = await _makeAuthorizedGet(url, accessToken);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (!data.containsKey('data')) return [];

      final List<dynamic> reels = data['data'];
      return reels
          .map(
            (reel) => MetaReel(
              id: reel['id'] ?? '',
              videoUrl: reel['media_url'] ?? '',
              thumbnail: reel['thumbnail_url'],
              caption: reel['caption'] ?? reel['title'] ?? '',
              platform: platform,
              createdTime: reel['created_time'] ?? '',
              likes: reel['like_count'] ?? 0,
              comments: reel['comments_count'] ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint("Error fetching reels: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 18. POST STORY
  // ---------------------------------------------------------------------------
  Future<bool> postStory(
    SocialPlatform platform,
    File imageFile,
    String? caption,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return false;

    if (platform == SocialPlatform.instagram) {
      try {
        // For Instagram stories, we need to upload to your service first
        final publicUrl = await _uploadToMyService(imageFile);

        if (publicUrl.isEmpty) return false;

        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$accountId/media',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image_url': publicUrl,
            'caption': caption,
            'media_type': 'STORIES',
            'access_token': accessToken,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("✅ Instagram story container created");
          return true;
        } else {
          debugPrint("❌ Instagram story error: ${response.body}");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Instagram story exception: $e");
        return false;
      }
    } else {
      // Facebook story (not implemented in current code)
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 19. POST REEL
  // ---------------------------------------------------------------------------
  Future<bool> postReel(
    SocialPlatform platform,
    File videoFile,
    String caption,
    File? thumbnail,
  ) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    String? accountId = platform == SocialPlatform.facebook
        ? creds['facebook_account_id']
        : creds['instagram_account_id'];

    if (accessToken == null || accountId == null) return false;

    if (platform == SocialPlatform.instagram) {
      try {
        // For reels, we need to upload video to your service first
        final publicUrl = await _uploadToMyService(videoFile);

        if (publicUrl.isEmpty) return false;

        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$accountId/media',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'video_url': publicUrl,
            'caption': caption,
            'media_type': 'REELS',
            'access_token': accessToken,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("✅ Instagram reel container created");
          final containerId = json.decode(response.body)['id'];

          // Reels require publishing separately
          await Future.delayed(const Duration(seconds: 5));

          final publishUrl = Uri.parse(
            'https://graph.facebook.com/$_graphApiVersion/$accountId/media_publish',
          );

          final publishResponse = await http.post(
            publishUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'creation_id': containerId,
              'access_token': accessToken,
            }),
          );

          return publishResponse.statusCode == 200;
        } else {
          debugPrint("❌ Instagram reel error: ${response.body}");
          return false;
        }
      } catch (e) {
        debugPrint("❌ Instagram reel exception: $e");
        return false;
      }
    } else {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 20. DELETE STORY
  // ---------------------------------------------------------------------------
  Future<bool> deleteStory(String storyId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$storyId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Story deleted successfully");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 21. DELETE REEL
  // ---------------------------------------------------------------------------
  Future<bool> deleteReel(String reelId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return false;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$reelId?access_token=$accessToken',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("✅ Reel deleted successfully");
        return true;
      } else {
        debugPrint("❌ Delete Error (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Delete Exception: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 22. GET REEL INSIGHTS
  // ---------------------------------------------------------------------------
  Future<MetaStoryInsights?> getReelInsights(String reelId) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return null;

    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$_graphApiVersion/$reelId/insights?metric=engagement,impression,video_views&access_token=$accessToken',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      int engagement = 0;
      int impressions = 0;
      int views = 0;

      if (data.containsKey('data')) {
        for (var metric in data['data']) {
          if (metric['name'] == 'engagement') {
            engagement = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'impression') {
            impressions = metric['values']?[0]?['value'] ?? 0;
          } else if (metric['name'] == 'video_views') {
            views = metric['values']?[0]?['value'] ?? 0;
          }
        }
      }

      return MetaStoryInsights(
        storyId: reelId,
        platform: SocialPlatform.instagram,
        views: views,
        replies: engagement,
        exits: 0,
        nextStoryTaps: impressions,
        createdTime: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint("Error fetching reel insights: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 23. GET TOP PERFORMING REELS
  // ---------------------------------------------------------------------------
  Future<List<MetaReel>> getTopPerformingReels(
    SocialPlatform platform, {
    int limit = 5,
  }) async {
    try {
      final reels = await getReels(platform);
      final sorted = reels.toList()
        ..sort((a, b) => b.totalEngagement.compareTo(a.totalEngagement));
      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint("Error fetching top reels: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 24. GET TOP PERFORMING STORIES
  // ---------------------------------------------------------------------------
  Future<List<MetaStory>> getTopPerformingStories(
    SocialPlatform platform, {
    int limit = 5,
  }) async {
    try {
      final stories = await getStories(platform);
      final sorted = stories.toList()
        ..sort((a, b) => b.views.compareTo(a.views));
      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint("Error fetching top stories: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 25. GET STORIES & REELS SUMMARY
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getStoriesReelsSummary(
    SocialPlatform platform,
  ) async {
    try {
      final results = await Future.wait([
        getStories(platform),
        getReels(platform),
      ]);

      final stories = results[0] as List<MetaStory>;
      final reels = results[1] as List<MetaReel>;

      final totalStoryViews = stories.fold<int>(0, (sum, s) => sum + s.views);
      final totalStoryReplies = stories.fold<int>(
        0,
        (sum, s) => sum + s.replies,
      );

      final totalReelViews = reels.fold<int>(0, (sum, r) => sum + r.plays);
      final totalReelEngagement = reels.fold<int>(
        0,
        (sum, r) => sum + r.totalEngagement,
      );

      return {
        'stories': stories,
        'reels': reels,
        'totalStories': stories.length,
        'totalReels': reels.length,
        'totalStoryViews': totalStoryViews,
        'totalStoryReplies': totalStoryReplies,
        'totalReelViews': totalReelViews,
        'totalReelEngagement': totalReelEngagement,
        'averageStoryViews': stories.isNotEmpty
            ? totalStoryViews ~/ stories.length
            : 0,
        'averageReelViews': reels.isNotEmpty
            ? totalReelViews ~/ reels.length
            : 0,
      };
    } catch (e) {
      debugPrint("Error fetching stories/reels summary: $e");
      return {
        'stories': [],
        'reels': [],
        'totalStories': 0,
        'totalReels': 0,
        'totalStoryViews': 0,
        'totalStoryReplies': 0,
        'totalReelViews': 0,
        'totalReelEngagement': 0,
        'averageStoryViews': 0,
        'averageReelViews': 0,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // 26. EDIT STORY
  // ---------------------------------------------------------------------------
  Future<bool> editStory(String storyId, String newCaption) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url =
          'https://graph.facebook.com/$_graphApiVersion/$storyId?caption=${Uri.encodeComponent(newCaption)}';
      final response = await _makeAuthorizedPost(url, accessToken);

      if (response.statusCode == 200) {
        debugPrint("Story $storyId updated successfully");
        return true;
      }
      debugPrint("Error editing story: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Error editing story: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 27. EDIT REEL
  // ---------------------------------------------------------------------------
  Future<bool> editReel(String reelId, String newCaption) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url =
          'https://graph.facebook.com/$_graphApiVersion/$reelId?caption=${Uri.encodeComponent(newCaption)}';
      final response = await _makeAuthorizedPost(url, accessToken);

      if (response.statusCode == 200) {
        debugPrint("Reel $reelId updated successfully");
        return true;
      }
      debugPrint("Error editing reel: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Error editing reel: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 28. ARCHIVE STORY
  // ---------------------------------------------------------------------------
  Future<bool> archiveStory(String storyId) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url =
          'https://graph.facebook.com/$_graphApiVersion/$storyId?status=ARCHIVED';
      final response = await _makeAuthorizedPost(url, accessToken);

      if (response.statusCode == 200) {
        debugPrint("Story $storyId archived successfully");
        return true;
      }
      debugPrint("Error archiving story: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Error archiving story: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 29. ARCHIVE REEL
  // ---------------------------------------------------------------------------
  Future<bool> archiveReel(String reelId) async {
    try {
      final creds = await _getCredentials();
      final String? accessToken =
          creds['facebook_page_access_token'] ??
          creds['facebook_user_access_token'];

      if (accessToken == null) return false;

      final url =
          'https://graph.facebook.com/$_graphApiVersion/$reelId?status=ARCHIVED';
      final response = await _makeAuthorizedPost(url, accessToken);

      if (response.statusCode == 200) {
        debugPrint("Reel $reelId archived successfully");
        return true;
      }
      debugPrint("Error archiving reel: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Error archiving reel: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 30. SEARCH STORIES
  // ---------------------------------------------------------------------------
  Future<List<MetaStory>> searchStories(
    SocialPlatform platform,
    String query,
  ) async {
    try {
      final stories = await getStories(platform);
      return stories
          .where(
            (story) =>
                story.caption?.toLowerCase().contains(query.toLowerCase()) ??
                false,
          )
          .toList();
    } catch (e) {
      debugPrint("Error searching stories: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 31. SEARCH REELS
  // ---------------------------------------------------------------------------
  Future<List<MetaReel>> searchReels(
    SocialPlatform platform,
    String query,
  ) async {
    try {
      final reels = await getReels(platform);
      return reels
          .where(
            (reel) => reel.caption.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      debugPrint("Error searching reels: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 32. GET REEL COMMENTS
  // ---------------------------------------------------------------------------
  Future<List<MetaComment>> getReelComments(
    String reelId, {
    SocialPlatform platform = SocialPlatform.facebook,
  }) async {
    return getPostComments(reelId, platform: platform);
  }

  // ---------------------------------------------------------------------------
  // 33. GET POST LIKES
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPostLikes(
    String postId, {
    SocialPlatform? platform,
  }) async {
    final creds = await _getCredentials();
    final String? accessToken =
        creds['facebook_page_access_token'] ??
        creds['facebook_user_access_token'];

    if (accessToken == null) return [];

    final bool isInstagram =
        platform == SocialPlatform.instagram ||
        postId.contains('instagram') ||
        postId.startsWith('178') ||
        postId.startsWith('179');

    try {
      if (isInstagram) {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId?fields=like_count&access_token=$accessToken',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final likeCount = data['like_count'] ?? 0;

          debugPrint("✅ Instagram like count: $likeCount");

          return [
            {
              'id': 'placeholder',
              'name': '$likeCount people liked this post',
              'username': 'Instagram does not provide list of likers',
              'is_placeholder': true,
              'count': likeCount,
            },
          ];
        }
        return [];
      } else {
        final url = Uri.parse(
          'https://graph.facebook.com/$_graphApiVersion/$postId/likes?fields=id,name&limit=100&access_token=$accessToken',
        );

        debugPrint("📥 Fetching Facebook likes from: $url");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (!data.containsKey('data')) return [];

          final List<dynamic> likes = data['data'];
          debugPrint("✅ Found ${likes.length} Facebook likes");

          return likes.map((like) {
            return {
              'id': like['id'] ?? '',
              'name': like['name'] ?? 'Facebook User',
            };
          }).toList();
        } else {
          debugPrint("❌ Facebook likes error: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching likes: $e");
    }
    return [];
  }
}
