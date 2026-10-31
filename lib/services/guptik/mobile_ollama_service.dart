import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guptik/services/node/node_http.dart';

class MobileOllamaService {
  final String tunnelUrl;

  MobileOllamaService({required this.tunnelUrl});

  /// 🚀 Fetch active AI settings synced from desktop
  Future<Map<String, dynamic>> fetchDesktopAiConfig() async {
    try {
      final response = await nodeHttp.get(Uri.parse('$tunnelUrl/api/ai-config'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Could not sync config from desktop: $e");
    }
    return {};
  }

  /// 🚀 Push mobile AI settings back to desktop (Two-Way Sync)
  Future<bool> updateDesktopAiConfig({
    required String provider,
    required String model,
    required String apiKey,
    required String endpointUrl,
  }) async {
    try {
      final response = await nodeHttp.post(
        Uri.parse('$tunnelUrl/api/ai-config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'endpoint_url': endpointUrl,
          'model_name': model,
          'api_key': apiKey,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Could not update desktop config: $e");
      return false;
    }
  }

  /// 🚀 DYNAMICALLY fetch list of available models based on selected provider
  Future<List<String>> getInstalledModels(String provider, {String apiKey = ''}) async {
    List<String> defaultModels = [];
    
    switch (provider) {
      case 'OpenRouter':
        defaultModels = ['meta-llama/llama-3-8b-instruct', 'google/gemini-flash-1.5', 'anthropic/claude-3.5-sonnet', 'deepseek/deepseek-chat'];
        break;
      case 'OpenAI':
        defaultModels = ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'];
        break;
      case 'Anthropic':
        defaultModels = ['claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'];
        break;
      case 'Gemini':
        defaultModels = ['gemini-1.5-flash', 'gemini-1.5-pro'];
        break;
      case 'DeepSeek':
        defaultModels = ['deepseek-chat', 'deepseek-coder'];
        break;
      default:
        defaultModels = ['meta-llama/llama-3-8b-instruct'];
    }

    if (provider == 'OpenRouter') {
      try {
        final response = await nodeHttp.get(
          Uri.parse('https://openrouter.ai/api/v1/models'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] != null && data['data'] is List) {
            List<String> liveModels = [];
            for (var model in data['data']) {
              if (model['id'] != null) {
                liveModels.add(model['id'].toString());
              }
            }
            if (liveModels.isNotEmpty) {
              return liveModels;
            }
          }
        }
      } catch (e) {
        print("Failed to fetch live OpenRouter models: $e");
      }
    }

    return defaultModels;
  }

  String _getDefaultEndpoint(String provider) {
    switch (provider) {
      case 'OpenAI':
        return 'https://api.openai.com/v1/chat/completions';
      case 'DeepSeek':
        return 'https://api.deepseek.com/chat/completions';
      case 'Anthropic':
        return 'https://api.anthropic.com/v1/messages';
      case 'Gemini':
        return 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';
      case 'OpenRouter':
      default:
        return 'https://openrouter.ai/api/v1/chat/completions';
    }
  }

  /// 🚀 Stream a chat reply through the node's agent route.
  /// The node holds the provider key and calls the model; the phone never sees the key.
  /// `provider`, `apiKey` and `endpointUrl` are kept for call-site compatibility and ignored.
  Stream<String> generateChatStream({
    required String provider,
    required String model,
    required List<Map<String, String>> history,
    String apiKey = '',
    String endpointUrl = '',
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse('$tunnelUrl/api/agent/chat'))
        ..headers.addAll({'Content-Type': 'application/json', 'Accept': 'text/event-stream'})
        ..body = jsonEncode({'model': model, 'messages': history});

      final streamedResponse = await nodeHttp.send(request);
      if (streamedResponse.statusCode == 401 || streamedResponse.statusCode == 403) {
        yield "\n[Error]: This phone isn't paired with your node yet. Pair it from the desktop app's Settings to use AI.";
        return;
      }
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield "\n[Node Error ${streamedResponse.statusCode}]: $errorBody";
        return;
      }

      final lines = streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final payload = trimmed.substring(5).trim();
        if (payload == '[DONE]') break;
        try {
          final data = jsonDecode(payload);
          if (data['delta'] != null) {
            yield data['delta'].toString();
          } else if (data['error'] != null) {
            yield "\n[AI Error]: ${data['error']}";
          }
        } catch (_) {
          // Ignore bad chunk parses
        }
      }
    } catch (e) {
      yield "\n[Error connecting to your node: $e]";
    }
  }

}