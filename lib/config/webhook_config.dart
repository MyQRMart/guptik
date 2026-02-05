class WebhookConfig {
  // Replace this with your actual domain where you'll host the webhook server
  static const String domain = "https://yourapp.com";
  
  // Webhook endpoint path
  static const String webhookPath = "/webhooks";
  
  // Base token for verify token generation
  static const String baseVerifyToken = "your-app-webhook";
  
  // Generate callback URL for user
  static String generateCallbackUrl(String userId) {
    return "$domain$webhookPath/$userId";
  }
  
  // Generate verify token for user
  static String generateVerifyToken(String userId) {
    return "$baseVerifyToken-${userId.substring(0, 8)}";
  }
  
  // Instructions for webhook setup
  static const String webhookInstructions = '''
WEBHOOK SETUP INSTRUCTIONS:

1. Use the Callback URL in your WhatsApp Business API configuration
2. Use the Verify Token when setting up the webhook
3. Messages will be sent directly to your app's database
4. No need to rely on third-party webhook services

BACKEND REQUIREMENTS:
- Set up a server at your domain to handle webhook requests
- Implement POST endpoint: /webhooks/{userId}
- Implement GET endpoint for verification: /webhooks/{userId}
- Connect to your PostgreSQL database for message storage
''';
}