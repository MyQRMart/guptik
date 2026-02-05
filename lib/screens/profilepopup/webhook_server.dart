import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:guptik/services/profilepopup_service/whatsapp_webhook_service.dart';

class WebhookServer {
  static final WebhookServer _instance = WebhookServer._internal();
  factory WebhookServer() => _instance;
  WebhookServer._internal();

  HttpServer? _server;
  final WhatsAppWebhookService _webhookService = WhatsAppWebhookService();

  // Start webhook server (for local development/testing)
  Future<void> startWebhookServer({int port = 8080}) async {
    if (_server != null) {
      if (kDebugMode) {
        print('🌐 Webhook server already running');
      }
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      
      if (kDebugMode) {
        print('🚀 Webhook server started on port $port');
        print('📡 Webhook URL: http://localhost:$port/webhooks/whatsapp');
      }

      await for (HttpRequest request in _server!) {
        _handleRequest(request);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting webhook server: $e');
      }
    }
  }

  // Handle incoming HTTP requests
  void _handleRequest(HttpRequest request) async {
    try {
      // Set CORS headers for web
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      final uri = request.uri;
      
      if (uri.path == '/webhooks/whatsapp') {
        await _handleWhatsAppWebhook(request);
      } else if (uri.path == '/health') {
        await _handleHealthCheck(request);
      } else {
        request.response.statusCode = 404;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling request: $e');
      }
      request.response.statusCode = 500;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  // Handle WhatsApp webhook requests
  Future<void> _handleWhatsAppWebhook(HttpRequest request) async {
    try {
      if (request.method == 'GET') {
        // Webhook verification (Facebook requirement)
        await _handleWebhookVerification(request);
      } else if (request.method == 'POST') {
        // Webhook event processing
        await _handleWebhookEvent(request);
      } else {
        request.response.statusCode = 405;
        request.response.write('Method Not Allowed');
        await request.response.close();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WhatsApp webhook error: $e');
      }
      request.response.statusCode = 500;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  // Handle webhook verification (GET request)
  Future<void> _handleWebhookVerification(HttpRequest request) async {
    final params = request.uri.queryParameters;
    final mode = params['hub.mode'];
    final token = params['hub.verify_token'];
    final challenge = params['hub.challenge'];

    if (kDebugMode) {
      print('🔍 Webhook verification: mode=$mode, token=$token');
    }

    try {
      if (mode != null && token != null && challenge != null) {
        final verificationResult = WhatsAppWebhookService.verifyWebhook(mode, token, challenge);
        
        request.response.statusCode = 200;
        request.response.write(verificationResult);
        
        if (kDebugMode) {
          print('✅ Webhook verification successful');
        }
      } else {
        request.response.statusCode = 400;
        request.response.write('Bad Request: Missing parameters');
      }
    } catch (e) {
      request.response.statusCode = 403;
      request.response.write('Forbidden: Invalid verification');
      
      if (kDebugMode) {
        print('❌ Webhook verification failed: $e');
      }
    }

    await request.response.close();
  }

  // Handle webhook events (POST request)
  Future<void> _handleWebhookEvent(HttpRequest request) async {
    try {
      // Read request body
      final bodyBytes = await request.fold<List<int>>(<int>[], (prev, chunk) => prev..addAll(chunk));
      final bodyString = utf8.decode(bodyBytes);
      final webhookData = json.decode(bodyString) as Map<String, dynamic>;

      if (kDebugMode) {
        print('📨 Received webhook event: ${webhookData.keys}');
      }

      // Extract signature header for verification
      final signature = request.headers.value('x-hub-signature-256') ?? request.headers.value('x-hub-signature');

      // Process webhook with our service
      final result = await _webhookService.processWebhook(webhookData, bodyString, signature);

      // Log the webhook event
      await _logWebhookEvent(webhookData, result);

      // Send response
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(result));

      if (kDebugMode) {
        print('✅ Webhook processed: ${result['status']}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Webhook processing error: $e');
      }
      
      request.response.statusCode = 500;
      request.response.write(json.encode({
        'status': 'error',
        'message': e.toString()
      }));
    }

    await request.response.close();
  }

  // Handle health check requests
  Future<void> _handleHealthCheck(HttpRequest request) async {
    final healthData = {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'Meta Fly Webhook Server',
      'version': '1.0.0'
    };

    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode(healthData));
    await request.response.close();
  }

  // Log webhook events for monitoring
  Future<void> _logWebhookEvent(Map<String, dynamic> payload, Map<String, dynamic> result) async {
    try {
      // This would normally save to database
      // For now, just log to console in debug mode
      if (kDebugMode) {
        print('📊 Webhook Log:');
        print('  - Type: ${_extractWebhookType(payload)}');
        print('  - Status: ${result['status']}');
        print('  - Events: ${result['processed_events'] ?? 0}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging webhook: $e');
      }
    }
  }

  // Extract webhook type from payload
  String _extractWebhookType(Map<String, dynamic> payload) {
    try {
      final entry = payload['entry'] as List?;
      if (entry != null && entry.isNotEmpty) {
        final changes = entry.first['changes'] as List?;
        if (changes != null && changes.isNotEmpty) {
          return changes.first['field'] ?? 'unknown';
        }
      }
      return 'unknown';
    } catch (e) {
      return 'error';
    }
  }

  // Stop webhook server
  Future<void> stopWebhookServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      
      if (kDebugMode) {
        print('🛑 Webhook server stopped');
      }
    }
  }

  // Get webhook server status
  bool get isRunning => _server != null;
  
  // Get webhook URL for configuration
  String getWebhookUrl({String? domain, int port = 8080}) {
    if (domain != null) {
      return 'https://$domain/webhooks/whatsapp';
    }
    return 'http://localhost:$port/webhooks/whatsapp';
  }
}