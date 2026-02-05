import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guptik/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';


class WhatsAppWebhookService {
  static final WhatsAppWebhookService _instance = WhatsAppWebhookService._internal();
  factory WhatsAppWebhookService() => _instance;
  WhatsAppWebhookService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Process incoming webhook from WhatsApp Business API
  Future<Map<String, dynamic>> processWebhook(Map<String, dynamic> webhookData, [String? rawBody, String? signature]) async {
    try {
      if (kDebugMode) {
        debugPrint('ðŸ“¨ Received WhatsApp webhook: ${json.encode(webhookData)}');
      }

      // Verify webhook signature (Facebook requires this)
      if (!_verifyWebhookSignature(rawBody, signature)) {
        throw Exception('Invalid webhook signature');
      }

      // Process different types of webhook events
      final entry = webhookData['entry'] as List?;
      if (entry == null || entry.isEmpty) {
        return {'status': 'no_data', 'message': 'No entry data'};
      }

      final results = <Map<String, dynamic>>[];
      
      for (final entryItem in entry) {
        final changes = entryItem['changes'] as List?;
        if (changes != null) {
          for (final change in changes) {
            final result = await _processWebhookChange(change);
            results.add(result);
          }
        }
      }

      return {
        'status': 'success',
        'processed_events': results.length,
        'results': results
      };

    } catch (e) {
      if (kDebugMode) {
        debugPrint('âŒ Webhook processing error: $e');
      }
      return {
        'status': 'error',
        'message': e.toString()
      };
    }
  }

  // Process individual webhook change event
  Future<Map<String, dynamic>> _processWebhookChange(Map<String, dynamic> change) async {
    final field = change['field'] as String?;
    final value = change['value'] as Map<String, dynamic>?;

    if (value == null) {
      return {'status': 'skipped', 'reason': 'no_value'};
    }

    switch (field) {
      case 'messages':
        return await _processMessages(value);
      case 'message_template_status_update':
        return await _processTemplateStatusUpdate(value);
      case 'account_alerts':
        return await _processAccountAlerts(value);
      case 'business_capability_update':
        return await _processBusinessCapabilityUpdate(value);
      default:
        return {'status': 'unknown_field', 'field': field};
    }
  }

  // Process incoming messages and message status updates
  Future<Map<String, dynamic>> _processMessages(Map<String, dynamic> value) async {
    try {
      // Process incoming messages
      final messages = value['messages'] as List?;
      if (messages != null) {
        for (final message in messages) {
          await _storeIncomingMessage(message);
        }
      }

      // Process message status updates
      final statuses = value['statuses'] as List?;
      if (statuses != null) {
        for (final status in statuses) {
          await _updateMessageStatus(status);
        }
      }

      return {
        'status': 'success',
        'incoming_messages': messages?.length ?? 0,
        'status_updates': statuses?.length ?? 0
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Store incoming message from customer
  Future<void> _storeIncomingMessage(Map<String, dynamic> message) async {
    try {
      final messageId = message['id'] as String;
      final from = message['from'] as String;
      final timestamp = message['timestamp'] as String;
      final type = message['type'] as String;

      // Extract message content based on type
      String content = '';
      Map<String, dynamic>? mediaInfo;

      switch (type) {
        case 'text':
          content = message['text']?['body'] ?? '';
          break;
        case 'image':
          content = message['image']?['caption'] ?? '[Image]';
          mediaInfo = message['image'];
          break;
        case 'video':
          content = message['video']?['caption'] ?? '[Video]';
          mediaInfo = message['video'];
          break;
        case 'audio':
          content = '[Audio Message]';
          mediaInfo = message['audio'];
          break;
        case 'document':
          content = message['document']?['filename'] ?? '[Document]';
          mediaInfo = message['document'];
          break;
        case 'location':
          final location = message['location'];
          content = 'Location: ${location?['latitude']}, ${location?['longitude']}';
          break;
        case 'contacts':
          content = '[Contact Shared]';
          break;
        default:
          content = '[${type.toUpperCase()}]';
      }

      // Store in conversations table (you may need to create this)
      await _supabase.from('conversations').upsert({
        'phone_number': from,
        'last_message': content,
        'last_message_time': DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp) * 1000
        ).toIso8601String(),
        'is_unread': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Store individual message
      await _supabase.from('messages').insert({
        'message_id': messageId,
        'phone_number': from,
        'content': content,
        'message_type': type,
        'direction': 'incoming',
        'status': 'received',
        'timestamp': DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp) * 1000
        ).toIso8601String(),
        'media_info': mediaInfo != null ? json.encode(mediaInfo) : null,
        'raw_data': json.encode(message),
      });

      if (kDebugMode) {
        debugPrint('âœ… Stored incoming message from $from: $content');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('âŒ Error storing incoming message: $e');
      }
    }
  }

  // Update message delivery status
  Future<void> _updateMessageStatus(Map<String, dynamic> status) async {
    try {
      final messageId = status['id'] as String;
      final statusValue = status['status'] as String;
      final timestamp = status['timestamp'] as String;
      // final recipientId = status['recipient_id'] as String?; // Available if needed

      await _supabase.from('messages').update({
        'status': statusValue,
        'status_timestamp': DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp) * 1000
        ).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('message_id', messageId);

      if (kDebugMode) {
        debugPrint('âœ… Updated message $messageId status to $statusValue');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('âŒ Error updating message status: $e');
      }
    }
  }

  // Process template status updates (approved, rejected, etc.)
  Future<Map<String, dynamic>> _processTemplateStatusUpdate(Map<String, dynamic> value) async {
    try {
      // final templateId = value['message_template_id'] as String?; // Available if needed
      final templateName = value['message_template_name'] as String?;
      final status = value['event'] as String?;
      final reason = value['reason'] as String?;

      if (templateName != null && status != null) {
        // Update template status in database
        await _supabase.from('message_templates').update({
          'status': _mapTemplateStatus(status),
          'rejection_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('name', templateName);

        if (kDebugMode) {
          debugPrint('âœ… Updated template $templateName status to $status');
        }
      }

      return {
        'status': 'success',
        'template_name': templateName,
        'new_status': status,
        'reason': reason
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Process account alerts
  Future<Map<String, dynamic>> _processAccountAlerts(Map<String, dynamic> value) async {
    try {
      final alertType = value['alert_type'] as String?;
      final severity = value['severity'] as String?;
      final message = value['message'] as String?;

      // Store alert for admin review
      await _supabase.from('account_alerts').insert({
        'alert_type': alertType,
        'severity': severity,
        'message': message,
        'raw_data': json.encode(value),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('âš ï¸ Account alert: $alertType - $message');
      }

      return {
        'status': 'success',
        'alert_type': alertType,
        'severity': severity
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Process business capability updates
  Future<Map<String, dynamic>> _processBusinessCapabilityUpdate(Map<String, dynamic> value) async {
    try {
      final capabilities = value['capabilities'] as List?;
      
      if (kDebugMode) {
        debugPrint('ðŸ¢ Business capability update: $capabilities');
      }

      return {
        'status': 'success',
        'capabilities': capabilities
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Verify webhook signature (Facebook security requirement)
  /// 
  /// This method verifies the HMAC-SHA256 signature sent by Facebook in the 
  /// 'x-hub-signature-256' header to ensure the webhook payload is authentic.
  /// 
  /// To enable signature verification:
  /// 1. Get your App Secret from the Facebook App Dashboard
  /// 2. Update AppConfig.whatsappAppSecret in lib/config/app_config.dart
  /// 3. Ensure your webhook endpoint uses HTTPS in production
  /// 
  /// Returns true if signature is valid or verification is disabled (debug mode)
  bool _verifyWebhookSignature(String? rawBody, String? signature) {
    // Skip verification in debug mode or if signature is missing
    if (kDebugMode || signature == null || rawBody == null) {
      if (kDebugMode) {
        debugPrint('âš ï¸ Webhook signature verification skipped in debug mode');
      }
      return true;
    }

    try {
      // Get app secret from configuration
      const String appSecret = AppConfig.whatsappAppSecret;
      
      // Check if app secret is configured
      if (appSecret == 'TEST_APP_SECRET_123' || appSecret.isEmpty) {
        if (kDebugMode) {
          debugPrint('âš ï¸ WhatsApp app secret not configured - signature verification disabled');
        }
        return true; // Allow in development when not configured
      }
      
      // Remove 'sha256=' or 'sha1=' prefix from signature
      String cleanSignature = signature;
      if (signature.startsWith('sha256=')) {
        cleanSignature = signature.substring(7);
      } else if (signature.startsWith('sha1=')) {
        cleanSignature = signature.substring(5);
      }

      // Create HMAC-SHA256 hash of the raw body using app secret
      final key = utf8.encode(appSecret);
      final bodyBytes = utf8.encode(rawBody);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bodyBytes);
      final expectedSignature = digest.toString();

      // Compare signatures (constant-time comparison to prevent timing attacks)
      if (expectedSignature.length != cleanSignature.length) {
        return false;
      }

      int result = 0;
      for (int i = 0; i < expectedSignature.length; i++) {
        result |= expectedSignature.codeUnitAt(i) ^ cleanSignature.codeUnitAt(i);
      }

      final isValid = result == 0;
      
      if (!isValid && kDebugMode) {
        debugPrint('âŒ Webhook signature verification failed');
        debugPrint('Expected: $expectedSignature');
        debugPrint('Received: $cleanSignature');
      }

      return isValid;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('âŒ Error verifying webhook signature: $e');
      }
      return false;
    }
  }

  // Map WhatsApp template status to our internal status
  String _mapTemplateStatus(String whatsappStatus) {
    switch (whatsappStatus) {
      case 'APPROVED':
        return 'APPROVED';
      case 'REJECTED':
        return 'REJECTED';
      case 'PENDING':
        return 'PENDING';
      case 'PAUSED':
        return 'PAUSED';
      default:
        return 'UNKNOWN';
    }
  }

  // Webhook verification for initial setup (GET request)
  static String verifyWebhook(String mode, String token, String challenge) {
    const String verifyToken = 'YOUR_VERIFY_TOKEN_HERE'; // Set this in your config
    
    if (mode == 'subscribe' && token == verifyToken) {
      return challenge;
    }
    
    throw Exception('Invalid webhook verification');
  }
}