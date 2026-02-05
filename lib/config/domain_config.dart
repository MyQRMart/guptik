class DomainConfig {
  // 🔧 CHANGE THIS TO YOUR ACTUAL SUBDOMAIN
  static const String domain = 'your-subdomain.example.com';
  
  // Example: 'wanotifier.yourcompany.com'
  // Example: 'app.yourdomain.com'
  // Example: 'notifier.mybusiness.com'
  
  // Generated URLs will use this domain
  static String get baseUrl => 'https://$domain';
  
  // Template link: https://your-domain.com/template?id=123
  static String templateUrl(String templateId) => '$baseUrl/template?id=$templateId';
  
  // Dashboard link: https://your-domain.com/dashboard
  static String get dashboardUrl => '$baseUrl/dashboard';
  
  // WhatsApp link: https://your-domain.com/whatsapp?phone=123&message=Hello
  static String whatsappUrl({String? phone, String? message}) {
    final params = <String>[];
    if (phone != null) params.add('phone=${Uri.encodeComponent(phone)}');
    if (message != null) params.add('message=${Uri.encodeComponent(message)}');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/whatsapp$query';
  }
}