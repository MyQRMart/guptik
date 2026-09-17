import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:guptik/services/mediaplayer/node_url.dart';

class VaultSyncService {
  Future<String?> getDesktopUrl() => NodeUrl.resolveMine();

  Future<bool> uploadFile(File file, String baseUrl) async {
    try {
      final urlEncodedName = Uri.encodeComponent(path.basename(file.path));
      final url = Uri.parse('$baseUrl/vault/upload/$urlEncodedName');

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('File is empty, aborting.');
        return false;
      }

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/octet-stream';
      request.bodyBytes = await file.readAsBytes();

      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) return true;
      debugPrint('Upload Failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Sync Error: $e');
      return false;
    }
  }

  Future<bool> isGatewayOnline(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
