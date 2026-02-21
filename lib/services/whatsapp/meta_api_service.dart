import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // REQUIRED FOR MEDIA TYPE
import 'package:guptik/models/whatsapp/template_model.dart'; // Adjust path if needed

class MetaApiService {
  final String accessToken;
  final String businessAccountId;
  final String phoneNumberId;
  final String appId;
  final String baseUrl = 'https://graph.facebook.com/v19.0';

  MetaApiService({
    required this.accessToken,
    required this.businessAccountId,
    required this.phoneNumberId,
    required this.appId,
  });

  // --- AUTOMATED MEDIA UPLOAD (FOR TEMPLATE CREATION) ---
  Future<String> uploadMediaToMeta(File mediaFile, String format) async {
    final int fileLength = await mediaFile.length();

    String mimeType = 'application/octet-stream';
    if (format == 'IMAGE') mimeType = 'image/jpeg';
    if (format == 'VIDEO') mimeType = 'video/mp4';
    if (format == 'DOCUMENT') mimeType = 'application/pdf';

    final sessionUrl = Uri.parse(
      '$baseUrl/$appId/uploads?file_length=$fileLength&file_type=$mimeType',
    );
    final sessionRes = await http.post(
      sessionUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (sessionRes.statusCode != 200)
      throw Exception('Session Error: ${sessionRes.body}');

    final sessionData = json.decode(sessionRes.body);
    final String sessionId = sessionData['id'];

    final uploadUrl = Uri.parse('$baseUrl/$sessionId');
    final fileBytes = await mediaFile.readAsBytes();

    final uploadRes = await http.post(
      uploadUrl,
      headers: {'Authorization': 'OAuth $accessToken', 'file_offset': '0'},
      body: fileBytes,
    );

    if (uploadRes.statusCode != 200)
      throw Exception('Upload Error: ${uploadRes.body}');

    final uploadData = json.decode(uploadRes.body);
    return uploadData['h'];
  }

  // --- UPLOAD MEDIA FOR SENDING A MESSAGE ---
  Future<String> uploadMediaForMessage(File mediaFile, String format) async {
    final url = Uri.parse('$baseUrl/$phoneNumberId/media');

    // Label the file correctly so Meta doesn't reject it as 'application/octet-stream'
    MediaType contentType = MediaType('application', 'octet-stream');
    if (format == 'IMAGE') {
      contentType = MediaType('image', 'jpeg');
    } else if (format == 'VIDEO') {
      contentType = MediaType('video', 'mp4');
    } else if (format == 'DOCUMENT') {
      contentType = MediaType('application', 'pdf');
    }

    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['messaging_product'] = 'whatsapp'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          contentType: contentType, // THIS FIXES THE ERROR
        ),
      );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody)['id']; // Returns the Media ID
    } else {
      throw Exception('Media upload failed: $responseBody');
    }
  }

  Future<List<WhatsAppTemplate>> fetchTemplates() async {
    final url = Uri.parse('$baseUrl/$businessAccountId/message_templates');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> templateData = data['data'] ?? [];
      return templateData
          .map((json) => WhatsAppTemplate.fromJson(json))
          .toList();
    } else {
      throw Exception(response.body);
    }
  }

  Future<bool> createTemplate({
    required String name,
    required String category,
    required String language,
    required String headerFormat,
    required String headerText,
    required String headerHandle,
    required String bodyText,
    required String footerText,
    required List<String> bodyVariableExamples,
  }) async {
    final formattedName = name.trim().toLowerCase().replaceAll(' ', '_');
    final url = Uri.parse('$baseUrl/$businessAccountId/message_templates');

    List<Map<String, dynamic>> components = [];

    if (headerFormat != 'NONE') {
      Map<String, dynamic> header = {'type': 'HEADER', 'format': headerFormat};
      if (headerFormat == 'TEXT') {
        header['text'] = headerText;
      } else {
        header['example'] = {
          'header_handle': [headerHandle],
        };
      }
      components.add(header);
    }

    Map<String, dynamic> body = {'type': 'BODY', 'text': bodyText};
    if (bodyVariableExamples.isNotEmpty) {
      body['example'] = {
        'body_text': [bodyVariableExamples],
      };
    }
    components.add(body);

    if (footerText.isNotEmpty)
      components.add({'type': 'FOOTER', 'text': footerText});

    final payload = {
      "name": formattedName,
      "category": category,
      "language": language,
      "components": components,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw Exception(response.body);
  }

  Future<bool> sendTemplateMessage({
    required String targetPhoneNumber,
    required String templateName,
    required String languageCode,
    String? headerMediaType,
    String? mediaLink,
    String? mediaId,
    List<String> bodyVariables = const [],
  }) async {
    final url = Uri.parse('$baseUrl/$phoneNumberId/messages');
    final cleanPhone = targetPhoneNumber
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');

    List<Map<String, dynamic>> components = [];

    if (headerMediaType != null && headerMediaType != 'NONE') {
      Map<String, dynamic> mediaObj = {};

      // Use the Media ID if we uploaded a file, otherwise use the URL link
      if (mediaId != null && mediaId.isNotEmpty) {
        mediaObj = {"id": mediaId};
      } else if (mediaLink != null && mediaLink.isNotEmpty) {
        mediaObj = {"link": mediaLink};
      }

      if (mediaObj.isNotEmpty) {
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
    }

    if (bodyVariables.isNotEmpty) {
      List<Map<String, dynamic>> bodyParams = bodyVariables
          .map((val) => {"type": "text", "text": val})
          .toList();
      components.add({"type": "body", "parameters": bodyParams});
    }

    final payload = {
      "messaging_product": "whatsapp",
      "to": cleanPhone,
      "type": "template",
      "template": {
        "name": templateName,
        "language": {"code": languageCode},
        if (components.isNotEmpty) "components": components,
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      // Optionally log the response for debugging
      try {
        final respJson = json.decode(response.body);
        if (respJson['messages'] != null) {
          // Message sent successfully, log message IDs
          debugPrint(
            'WhatsApp API: Message sent. IDs: \\${respJson['messages']}',
          );
        } else {
          debugPrint(
            'WhatsApp API: Success response but no messages field: \\${response.body}',
          );
        }
      } catch (e) {
        debugPrint(
          'WhatsApp API: Success but response not JSON: \\${response.body}',
        );
      }
      return true;
    } else {
      // Log detailed error info
      debugPrint('WhatsApp API ERROR: Status: \\${response.statusCode}');
      debugPrint('Request URL: $url');
      debugPrint(
        'Request Headers: \\${{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'}}',
      );
      debugPrint('Request Body: \\${json.encode(payload)}');
      debugPrint('Response Body: \\${response.body}');
      throw Exception(
        'WhatsApp API Error: Status: \\${response.statusCode}, Body: \\${response.body}',
      );
    }
  }
}
