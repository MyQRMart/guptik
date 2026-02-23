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

      // FIX 1: Ensure userId is not null before using it
      if (userId == null) {
        debugPrint("User not logged in");
        return null;
      }

      // Fetch the first active desktop device for this user
      final response = await supabase
          .from('desktop_devices')
          .select('public_url')
          .eq('user_id', userId) // Now safe because we checked for null above
          .not(
            'public_url',
            'is',
            null,
          ) // FIX 2: Correct way to filter "IS NOT NULL"
          .limit(1)
          .maybeSingle();

      if (response != null && response['public_url'] != null) {
        String url = response['public_url'];

        // Ensure it starts with https:// and doesn't end with /
        if (!url.startsWith('http')) url = 'https://$url';
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
      final filename = path.basename(file.path);
      final url = Uri.parse('$baseUrl/vault/upload/$filename');

      debugPrint("Syncing to: $url");

      final request = http.StreamedRequest('POST', url);

      request.headers['Content-Type'] = 'application/octet-stream';

      final fileSize = await file.length();
      request.contentLength = fileSize;

      // Pipe the file stream directly to the request
      file.openRead().listen(
        (chunk) => request.sink.add(chunk),
        onDone: () => request.sink.close(),
        onError: (e) => request.sink.addError(e),
        cancelOnError: true,
      );

      final response = await http.Response.fromStream(await request.send());

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
