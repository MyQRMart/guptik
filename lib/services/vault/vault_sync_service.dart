import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class VaultSyncService {
  // 1. Get the Desktop URL from Supabase
  Future<String?> getDesktopUrl() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint("User not logged in");
        return null;
      }

      final response = await supabase
          .from('desktop_devices')
          .select('public_url')
          .eq('user_id', userId)
          .not('public_url', 'is', null)
          .limit(1)
          .maybeSingle();

      if (response != null && response['public_url'] != null) {
        String url = response['public_url'];

        // FIX: Check if it's a local IP address (starts with a number)
        if (!url.startsWith('http')) {
          if (url.startsWith(RegExp(r'[0-9]'))) {
            url = 'http://$url'; // Local network MUST use http
          } else {
            url = 'https://$url'; // External domains (like ngrok) use https
          }
        }

        if (url.endsWith('/')) url = url.substring(0, url.length - 1);

        return url;
      }
    } catch (e) {
      debugPrint("Error fetching desktop URL: $e");
    }
    return null;
  }

  // 2. Upload a single file to the Gateway
  Future<bool> uploadFile(File file, String baseUrl) async {
    try {
      // KEEP the encodeComponent for the URL route so the HTTP request doesn't crash
      final urlEncodedName = Uri.encodeComponent(path.basename(file.path));
      final url = Uri.parse('$baseUrl/vault/upload/$urlEncodedName');

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint("File is empty, aborting.");
        return false;
      }

      debugPrint("Syncing to: $url (Size: $fileSize bytes)");

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/octet-stream';
      request.bodyBytes = await file.readAsBytes();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint("Upload Success: ${response.body}");
        return true;
      } else {
        debugPrint("Upload Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
      return false;
    }
  }

  // 3. Check if Gateway is Online
  Future<bool> isGatewayOnline(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
