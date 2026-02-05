import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:guptik/config/domain_config.dart';
import 'package:guptik/services/profilepopup_service/deep_link_navigator.dart';


class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize deep link handling
  Future<void> initialize({
    required Function(Uri) onLinkReceived,
  }) async {
    try {
      // Skip initialization on web platform
      if (kIsWeb) {
        if (kDebugMode) {
          print('Deep links not supported on web platform');
        }
        return;
      }

      // Check for initial link when app is launched
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        onLinkReceived(initialLink);
      }

      // Listen for incoming links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        onLinkReceived,
        onError: (err) {
          if (kDebugMode) {
            print('Deep link error: $err');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize deep links: $e');
      }
    }
  }

  // Handle incoming deep links
  void handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('Received deep link: $uri');
    }

    // Parse the URL and navigate accordingly
    final String path = uri.path;
    final Map<String, String> queryParams = uri.queryParameters;

    switch (path) {
      case '/templates':
        _navigateToTemplates(queryParams);
        break;
      case '/template':
        _navigateToTemplate(queryParams);
        break;
      case '/whatsapp':
        _navigateToWhatsApp(queryParams);
        break;
      case '/dashboard':
        _navigateToDashboard(queryParams);
        break;
      case '/auth':
        _handleAuth(queryParams);
        break;
      default:
        _navigateToHome();
    }
  }

  void _navigateToTemplates(Map<String, String> params) {
    DeepLinkNavigator.navigateToTemplates(params: params);
    if (kDebugMode) {
      print('Navigating to templates with params: $params');
    }
  }

  void _navigateToTemplate(Map<String, String> params) {
    final String? templateId = params['id'];
    if (templateId != null) {
      DeepLinkNavigator.navigateToTemplate(templateId: templateId);
      if (kDebugMode) {
        print('Navigating to template: $templateId');
      }
    }
  }

  void _navigateToWhatsApp(Map<String, String> params) {
    DeepLinkNavigator.navigateToWhatsApp(params: params);
    if (kDebugMode) {
      print('Navigating to WhatsApp with params: $params');
    }
  }

  void _navigateToDashboard(Map<String, String> params) {
    DeepLinkNavigator.navigateToDashboard(params: params);
    if (kDebugMode) {
      print('Navigating to dashboard with params: $params');
    }
  }

  void _handleAuth(Map<String, String> params) {
    DeepLinkNavigator.handleAuthCallback(params: params);
    if (kDebugMode) {
      print('Handling auth callback with params: $params');
    }
  }

  void _navigateToHome() {
    DeepLinkNavigator.navigateToHome();
    if (kDebugMode) {
      print('Navigating to home');
    }
  }

  // Generate shareable links
  String generateTemplateLink(String templateId, {String? domain}) {
    final String baseUrl = domain ?? DomainConfig.domain;
    return 'https://$baseUrl/template?id=$templateId';
  }

  String generateWhatsAppLink({String? phone, String? message, String? domain}) {
    final String baseUrl = domain ?? DomainConfig.domain;
    final Map<String, String> params = {};
    
    if (phone != null) params['phone'] = phone;
    if (message != null) params['message'] = message;
    
    final String queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return 'https://$baseUrl/whatsapp${queryString.isNotEmpty ? '?$queryString' : ''}';
  }

  String generateDashboardLink({String? domain}) {
    final String baseUrl = domain ?? DomainConfig.domain;
    return 'https://$baseUrl/dashboard';
  }

  // Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}