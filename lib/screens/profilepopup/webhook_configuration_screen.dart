import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/profilepopup/webhook_server.dart';


class WebhookConfigurationScreen extends StatefulWidget {
  const WebhookConfigurationScreen({super.key});

  @override
  State<WebhookConfigurationScreen> createState() => _WebhookConfigurationScreenState();
}

class _WebhookConfigurationScreenState extends State<WebhookConfigurationScreen> {
  final _domainController = TextEditingController();
  final _verifyTokenController = TextEditingController();
  final WebhookServer _webhookServer = WebhookServer();
  
  bool _isLocalServerRunning = false;
  String? _webhookUrl;
  
  @override
  void initState() {
    super.initState();
    _loadWebhookSettings();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _verifyTokenController.dispose();
    super.dispose();
  }

  void _loadWebhookSettings() {
    // Load saved webhook settings
    _domainController.text = 'your-domain.com'; // Load from config or database
    _verifyTokenController.text = 'YOUR_VERIFY_TOKEN_HERE';
    _updateWebhookUrl();
  }

  void _checkServerStatus() {
    setState(() {
      _isLocalServerRunning = _webhookServer.isRunning;
    });
  }

  void _updateWebhookUrl() {
    final domain = _domainController.text.trim();
    if (domain.isNotEmpty && domain != 'your-domain.com') {
      _webhookUrl = _webhookServer.getWebhookUrl(domain: domain);
    } else {
      _webhookUrl = _webhookServer.getWebhookUrl(); // localhost
    }
    setState(() {});
  }

  Future<void> _startLocalServer() async {
    try {
      await _webhookServer.startWebhookServer();
      setState(() {
        _isLocalServerRunning = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Local webhook server started on port 8080'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to start server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopLocalServer() async {
    try {
      await _webhookServer.stopWebhookServer();
      setState(() {
        _isLocalServerRunning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Local webhook server stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to stop server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyWebhookUrl() {
    if (_webhookUrl != null) {
      Clipboard.setData(ClipboardData(text: _webhookUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Webhook URL copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webhook Configuration', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.webhook, color: const Color(0xFF17A2B8), size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'WhatsApp Webhook Setup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF17A2B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure webhooks to receive real-time updates from WhatsApp Business API including message delivery status, incoming messages, and template approvals.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Webhook URL Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Webhook URL Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Domain Input
                    TextFormField(
                      controller: _domainController,
                      onChanged: (value) => _updateWebhookUrl(),
                      decoration: InputDecoration(
                        labelText: 'Your Domain',
                        hintText: 'example.com',
                        prefixIcon: const Icon(Icons.language, color: Color(0xFF17A2B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Verify Token Input
                    TextFormField(
                      controller: _verifyTokenController,
                      decoration: InputDecoration(
                        labelText: 'Verify Token',
                        hintText: 'Enter a secure verify token',
                        prefixIcon: const Icon(Icons.security, color: Color(0xFF17A2B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Generated Webhook URL
                    if (_webhookUrl != null) ...[
                      const Text(
                        'Generated Webhook URL:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _webhookUrl!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: _copyWebhookUrl,
                              tooltip: 'Copy URL',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Local Development Server
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          color: _isLocalServerRunning ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Local Development Server',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isLocalServerRunning ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isLocalServerRunning ? 'RUNNING' : 'STOPPED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'For testing webhooks locally during development. The server will run on http://localhost:8080',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLocalServerRunning ? null : _startLocalServer,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Server'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLocalServerRunning ? _stopLocalServer : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Server'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Setup Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'WhatsApp Configuration Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Go to Facebook Developers Console\n'
                      '2. Select your WhatsApp Business app\n'
                      '3. Navigate to WhatsApp > Configuration\n'
                      '4. Add the webhook URL above\n'
                      '5. Enter the verify token\n'
                      '6. Subscribe to webhook events:\n'
                      '   • messages\n'
                      '   • message_deliveries\n'
                      '   • message_reads\n'
                      '   • message_template_status_update',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Webhook Setup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What are webhooks?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Webhooks allow WhatsApp to send real-time notifications to your app when events occur, such as:'),
              SizedBox(height: 8),
              Text('• New messages from customers'),
              Text('• Message delivery confirmations'),
              Text('• Template approval status'),
              Text('• Account alerts'),
              SizedBox(height: 12),
              Text(
                'Setup Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. HTTPS endpoint (required for production)'),
              Text('2. Verify token for security'),
              Text('3. Facebook webhook configuration'),
              SizedBox(height: 12),
              Text(
                'For local testing, use ngrok or similar tunnel service to expose your localhost webhook to the internet.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}