import 'package:flutter/material.dart';
import 'package:guptik/screens/dashboard/message_templates_screen.dart';
import 'package:guptik/screens/home/home_screen.dart';
import 'package:guptik/screens/profilepopup/whatsapp_web_screen.dart';

class DeepLinkNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void navigateToTemplates({Map<String, String>? params}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MessageTemplatesScreen(),
        ),
      );
    }
  }

  static void navigateToTemplate({required String templateId}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Navigate to template edit screen with the specific template
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MessageTemplatesScreen(),
          // You can pass the templateId to filter or highlight specific template
        ),
      );
    }
  }

  static void navigateToWhatsApp({Map<String, String>? params}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WhatsAppWebScreen(),
        ),
      );
    }
  }

  static void navigateToDashboard({Map<String, String>? params}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  static void navigateToHome() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  static void handleAuthCallback({Map<String, String>? params}) {
    if (params == null) return;

    final String? token = params['token'];
    final String? error = params['error'];

    if (token != null) {
      // Handle successful authentication
      // You might want to store the token or refresh the UI
      navigateToDashboard();
    } else if (error != null) {
      // Handle authentication error
      // Show error message or navigate to login
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}