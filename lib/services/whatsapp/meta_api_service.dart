import 'dart:convert';
import 'dart:io';
import 'package:guptik/models/whatsapp/template_model.dart';
import 'package:http/http.dart' as http;

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

  // --- AUTOMATED MEDIA UPLOAD ---
  Future<String> uploadMediaToMeta(File mediaFile, String format) async {
    final int fileLength = await mediaFile.length();

    // Determine MIME type
    String mimeType = 'application/octet-stream';
    if (format == 'IMAGE') mimeType = 'image/jpeg';
    if (format == 'VIDEO') mimeType = 'video/mp4';
    if (format == 'DOCUMENT') mimeType = 'application/pdf';

    // Step 1: Initialize Upload Session
    final sessionUrl = Uri.parse(
      '$baseUrl/$appId/uploads?file_length=$fileLength&file_type=$mimeType',
    );
    final sessionRes = await http.post(
      sessionUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (sessionRes.statusCode != 200) {
      throw Exception('Session Error: ${sessionRes.body}');
    }

    final sessionData = json.decode(sessionRes.body);
    final String sessionId = sessionData['id'];

    // Step 2: Upload File Bytes
    final uploadUrl = Uri.parse('$baseUrl/$sessionId');
    final fileBytes = await mediaFile.readAsBytes();

    final uploadRes = await http.post(
      uploadUrl,
      headers: {'Authorization': 'OAuth $accessToken', 'file_offset': '0'},
      body: fileBytes,
    );

    if (uploadRes.statusCode != 200) {
      throw Exception('Upload Error: ${uploadRes.body}');
    }

    final uploadData = json.decode(uploadRes.body);
    return uploadData['h']; // Returns the generated header handle
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

    if (footerText.isNotEmpty) {
      components.add({'type': 'FOOTER', 'text': footerText});
    }

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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(response.body);
    }
  }

  Future<bool> sendTemplateMessage({
    required String targetPhoneNumber,
    required String templateName,
    required String languageCode,
    String? headerMediaType,
    String? mediaLink,
    List<String> bodyVariables = const [],
  }) async {
    final url = Uri.parse('$baseUrl/$phoneNumberId/messages');
    final cleanPhone = targetPhoneNumber
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '');

    List<Map<String, dynamic>> components = [];

    if (headerMediaType != null &&
        headerMediaType != 'NONE' &&
        mediaLink != null) {
      components.add({
        "type": "header",
        "parameters": [
          {
            "type": headerMediaType.toLowerCase(),
            headerMediaType.toLowerCase(): {"link": mediaLink},
          },
        ],
      });
    }

    if (bodyVariables.isNotEmpty) {
      List<Map<String, dynamic>> bodyParams = bodyVariables.map((val) {
        return {"type": "text", "text": val};
      }).toList();

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
      return true;
    } else {
      throw Exception(response.body);
    }
  }
}
