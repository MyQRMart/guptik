import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:guptik/services/whatsapp/wa_template_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class WhatsAppApiService {
  final SupabaseService _supabase = SupabaseService();

  String? _accessToken;
  String? _businessAccountId;
  String? _phoneNumberId;
  String? _appId;

  Future<void> _initCredentials() async {
    try {
      final credentials = await _supabase.getWhatsAppCredentials();
      _accessToken = credentials['accessToken'];
      _phoneNumberId = credentials['phoneNumberId'];
      _businessAccountId = credentials['businessAccountId'];
      _appId = credentials['appId'];

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception(
          'WhatsApp access token not found. Please configure in Settings tab.',
        );
      }

      debugPrint('✅ WhatsApp credentials loaded for user');
    } catch (e) {
      debugPrint('❌ Failed to load WhatsApp credentials: $e');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_accessToken == null) {
      await _initCredentials();
    }
  }

  // ========== MEDIA UPLOAD FOR SENDING MESSAGES ==========
  Future<String> uploadMediaForMessage(
    File file,
    String messagingProduct,
  ) async {
    await _ensureInitialized();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://graph.facebook.com/v23.0/$_phoneNumberId/media'),
    );
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.fields['messaging_product'] = messagingProduct;
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['id'];
    } else {
      throw Exception('Media upload failed: $responseBody');
    }
  }

  // ========== RESUMABLE UPLOAD FOR TEMPLATE HEADERS ==========
  Future<String> createUploadSession({
    required String fileName,
    required int fileLength,
    required String fileType,
  }) async {
    await _ensureInitialized();

    final url = Uri.parse('https://graph.facebook.com/v23.0/$_appId/uploads');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'file_name': fileName,
        'file_length': fileLength,
        'file_type': fileType,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception('Create upload session failed: ${response.body}');
    }
  }

  Future<String> uploadFileToSession(String sessionId, File file) async {
    await _ensureInitialized();

    final url = Uri.parse('https://graph.facebook.com/v23.0/$sessionId');
    final fileBytes = await file.readAsBytes();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'file_offset': '0',
        'Content-Type': 'application/octet-stream',
      },
      body: fileBytes,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['h'];
    } else {
      throw Exception('File upload to session failed: ${response.body}');
    }
  }

  Future<String> uploadImageForTemplateHeader(File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final fileLength = await imageFile.length();
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    debugPrint('📤 Creating upload session for image: $fileName');
    final sessionId = await createUploadSession(
      fileName: fileName,
      fileLength: fileLength,
      fileType: mimeType,
    );

    debugPrint('📤 Uploading image to session: $sessionId');
    final handle = await uploadFileToSession(sessionId, imageFile);

    debugPrint('✅ Got image handle: $handle');
    return handle;
  }

  Future<String> uploadVideoForTemplateHeader(File videoFile) async {
    final fileName = videoFile.path.split('/').last;
    final fileLength = await videoFile.length();
    final mimeType = lookupMimeType(videoFile.path) ?? 'video/mp4';

    debugPrint('📤 Creating upload session for video: $fileName');
    final sessionId = await createUploadSession(
      fileName: fileName,
      fileLength: fileLength,
      fileType: mimeType,
    );

    debugPrint('📤 Uploading video to session: $sessionId');
    final handle = await uploadFileToSession(sessionId, videoFile);

    debugPrint('✅ Got video handle: $handle');
    return handle;
  }

  Future<String> uploadDocumentForTemplateHeader(File documentFile) async {
    final fileName = documentFile.path.split('/').last;
    final fileLength = await documentFile.length();
    final mimeType = lookupMimeType(documentFile.path) ?? 'application/pdf';

    debugPrint('📤 Creating upload session for document: $fileName');
    final sessionId = await createUploadSession(
      fileName: fileName,
      fileLength: fileLength,
      fileType: mimeType,
    );

    debugPrint('📤 Uploading document to session: $sessionId');
    final handle = await uploadFileToSession(sessionId, documentFile);

    debugPrint('✅ Got document handle: $handle');
    return handle;
  }

  // ========== FETCH TEMPLATES FROM WHATSAPP ==========
  Future<List<Map<String, dynamic>>> getTemplates() async {
    await _ensureInitialized();

    final url = Uri.parse(
      'https://graph.facebook.com/v23.0/$_businessAccountId/message_templates',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to fetch templates: ${response.body}');
    }
  }

  // ========== CREATE TEMPLATE ==========
  Future<Map<String, dynamic>> createTemplate(
    Map<String, dynamic> templateData,
  ) async {
    await _ensureInitialized();

    final url = Uri.parse(
      'https://graph.facebook.com/v23.0/$_businessAccountId/message_templates',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(templateData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Template creation failed: ${response.body}');
    }
  }

  // ========== DELETE TEMPLATE ==========
  Future<void> deleteTemplate(String templateId) async {
    await _ensureInitialized();

    final url = Uri.parse('https://graph.facebook.com/v23.0/$templateId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.body}');
    }
  }

  // ========== FETCH TEMPLATE STATUS ==========
  Future<Map<String, dynamic>> getTemplateStatus(String templateId) async {
    await _ensureInitialized();

    final url = Uri.parse('https://graph.facebook.com/v23.0/$templateId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch template status: ${response.body}');
    }
  }

  // ========== SEND TEMPLATE MESSAGE ==========
  Future<void> sendTemplateMessage({
    required String to,
    required String templateName,
    required String languageCode,
    required List<Map<String, dynamic>> components,
  }) async {
    await _ensureInitialized();

    final body = {
      'messaging_product': 'whatsapp',
      'to': to,
      'type': 'template',
      'template': {
        'name': templateName,
        'language': {'code': languageCode},
        'components': components,
      },
    };
    final url = Uri.parse(
      'https://graph.facebook.com/v23.0/$_phoneNumberId/messages',
    );
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Send failed: ${response.body}');
    }
  }

  // ========== SEND TEMPLATE MESSAGE WITH MEDIA ==========
  Future<void> sendTemplateMessageWithMedia({
    required String to,
    required String templateName,
    required String languageCode,
    String? headerMediaType,
    String? mediaId,
    String? mediaLink,
    List<String> bodyVariables = const [],
  }) async {
    List<Map<String, dynamic>> components = [];

    if (headerMediaType != null && (mediaId != null || mediaLink != null)) {
      Map<String, dynamic> mediaObj = {};
      if (mediaId != null && mediaId.isNotEmpty) {
        mediaObj = {"id": mediaId};
      } else if (mediaLink != null && mediaLink.isNotEmpty) {
        mediaObj = {"link": mediaLink};
      }

      components.add({
        "type": "header",
        "parameters": [
          {
            "type": headerMediaType.toLowerCase(),
            headerMediaType.toLowerCase(): mediaObj,
          },
        ],
      });
    }

    if (bodyVariables.isNotEmpty) {
      List<Map<String, dynamic>> bodyParams = bodyVariables
          .map((val) => {"type": "text", "text": val})
          .toList();
      components.add({"type": "body", "parameters": bodyParams});
    }

    await sendTemplateMessage(
      to: to,
      templateName: templateName,
      languageCode: languageCode,
      components: components,
    );
  }
}
