import 'package:flutter/foundation.dart';

class WebDeepLinkHandler {
  static void initialize() {
    if (kIsWeb) {
      // Handle web URL parameters
      _handleWebURL();
    }
  }

  static void _handleWebURL() {
    try {
      // Get current URL from browser
      final String currentUrl = Uri.base.toString();
      final Uri uri = Uri.parse(currentUrl);
      
      if (kDebugMode) {
        print('Web URL: $currentUrl');
      }

      // Handle specific paths for web
      final String path = uri.path;
      final Map<String, String> queryParams = uri.queryParameters;

      switch (path) {
        case '/template':
          _handleWebTemplate(queryParams);
          break;
        case '/templates':
          _handleWebTemplates();
          break;
        case '/whatsapp':
          _handleWebWhatsApp(queryParams);
          break;
        case '/dashboard':
          _handleWebDashboard();
          break;
        default:
          if (kDebugMode) {
            print('Web: No specific handler for path: $path');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Web deep link handling error: $e');
      }
    }
  }

  static void _handleWebTemplate(Map<String, String> params) {
    final String? templateId = params['id'];
    if (templateId != null) {
      if (kDebugMode) {
        print('Web: Opening template $templateId');
      }
      // You can store this in a state management solution
      // or use it when the app initializes
    }
  }

  static void _handleWebTemplates() {
    if (kDebugMode) {
      print('Web: Opening templates list');
    }
  }

  static void _handleWebWhatsApp(Map<String, String> params) {
    if (kDebugMode) {
      print('Web: Opening WhatsApp with params: $params');
    }
  }

  static void _handleWebDashboard() {
    if (kDebugMode) {
      print('Web: Opening dashboard');
    }
  }

  // Generate web-friendly URLs
  static String generateWebURL(String path, {Map<String, String>? params}) {
    final Uri baseUri = Uri.base;
    final String query = params?.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&') ?? '';
    
    return '${baseUri.origin}$path${query.isNotEmpty ? '?$query' : ''}';
  }
}