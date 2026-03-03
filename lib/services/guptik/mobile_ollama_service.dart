import 'dart:convert';
import 'package:http/http.dart' as http;

class MobileOllamaService {
  final String tunnelUrl;

  MobileOllamaService({required this.tunnelUrl});

  // Get list of installed models from the desktop
  Future<List<String>> getInstalledModels() async {
    try {
      final url = Uri.parse('$tunnelUrl/api/tags');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['models'] != null) {
          return (data['models'] as List)
              .map<String>((m) => m['name'] as String)
              .toList();
        }
      } else {
        print("Failed to load models. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching models from tunnel: $e");
    }
    return [];
  }

  // Stream chat response through the tunnel
  Stream<String> generateChatStream({
    required String model,
    required List<Map<String, String>> history,
  }) async* {
    final url = Uri.parse('$tunnelUrl/api/chat');

    final body = jsonEncode({
      "model": model,
      "messages": history,
      "stream": true,
    });

    try {
      final request = http.Request('POST', url);
      request.body = body;

      // Headers are crucial so Cloudflare and Ollama know it's a JSON request
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();

      // THE FIX: We use LineSplitter() to make sure we process full JSON sentences,
      // not broken half-chunks of text!
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (var line in stream) {
        try {
          if (line.trim().isEmpty) continue; // Skip empty background pings

          final data = jsonDecode(line);

          if (data['message'] != null && data['message']['content'] != null) {
            yield data['message']['content']; // Send the word to the UI
          }

          if (data['done'] == true) {
            break; // Stop listening when Ollama is finished
          }
        } catch (e) {
          print("Error parsing this chunk: $line | Error: $e");
        }
      }
    } catch (e) {
      print("Network Error: $e");
      yield "\n[Error connecting to Desktop AI: Make sure the Cloudflare tunnel is running and Ollama is active.]";
    }
  }
}
