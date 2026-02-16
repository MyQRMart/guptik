import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _callbackUrlController = TextEditingController();
  final _verifyTokenController = TextEditingController();
  
  bool _isLoading = false;
  bool _isValidating = false;
  bool _showAccessToken = false;
  String? _metaflyApiKey;
  
  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _callbackUrlController.dispose();
    _verifyTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedKeys() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load saved API keys from user metadata or a separate table
      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _callbackUrlController.text = response['callback_url'] ?? 'https://app.metafly.com/webhooks';
          _verifyTokenController.text = response['verify_token'] ?? 'meta-fly';
          _metaflyApiKey = response['metafly_api_key'];
        });
      } else {
        // Set default values for new users
        setState(() {
          _callbackUrlController.text = 'https://app.metafly.com/webhooks';
          _verifyTokenController.text = 'meta-fly';
        });
      }
    } catch (e) {
      // Table might not exist yet, that's okay
    }
  }

  Future<void> _saveApiKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate MetaFly API key if not exists
      if (_metaflyApiKey == null || _metaflyApiKey!.isEmpty) {
        _metaflyApiKey = _generateMetaFlyApiKey();
      }

      // Save API keys to database
      await Supabase.instance.client.from('user_api_settings').upsert({
        'user_id': user.id,
        'callback_url': _callbackUrlController.text.trim(),
        'verify_token': _verifyTokenController.text.trim(),
        'metafly_api_key': _metaflyApiKey,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API keys saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving keys: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateMetaFlyApiKey() {
    // Generate a random API key similar to the format shown in the web interface
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(26, (index) => chars[random.hashCode % chars.length]).join();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ API key copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isValidating = true);

    try {
      // Validate all required fields
      if (_callbackUrlController.text.trim().isEmpty || _verifyTokenController.text.trim().isEmpty) {
        throw Exception('Please fill all required fields');
      }

      // Save the configuration first
      await _saveApiKeys();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuration validated and saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Validation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Configuration', style: TextStyle(color: Colors.white)),
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
        child: Form(
          key: _formKey,
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
                          Icon(Icons.api, color: const Color(0xFF17A2B8), size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'WhatsApp Business API Setup',
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
                        'Configure your WhatsApp Business API credentials to start sending messages through MetaFly.',
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

                      // Webhook Configuration Section
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Icon(Icons.webhook, color: const Color(0xFF17A2B8), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Webhook Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Callback URL
                      _buildApiKeyField(
                        controller: _callbackUrlController,
                        label: 'Callback URL',
                        hint: 'https://app.metafly.com/webhooks/...',
                        icon: Icons.link,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Callback URL is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Verify Token
                      _buildApiKeyField(
                        controller: _verifyTokenController,
                        label: 'Verify Token',
                        hint: 'meta-fly',
                        icon: Icons.verified,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Verify Token is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Action Button (Validate and proceed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isValidating) ? null : _validateAndProceed,
                          icon: (_isLoading || _isValidating)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text((_isLoading || _isValidating) ? 'Validating...' : 'Validate and proceed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17A2B8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    
                  
                
              

              const SizedBox(height: 24),

              // API Integrations Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API Integrations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the following API key for 3rd party integrations like WordPress, Shopify, Google Sheet etc.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MetaFly.com API Key',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        _metaflyApiKey ?? 'API key will be generated after saving configuration',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: _metaflyApiKey != null ? Colors.pink : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                                      onPressed: _metaflyApiKey != null ? () => _copyToClipboard(_metaflyApiKey!) : null,
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      tooltip: 'Copy',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions Card
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
                            'How to get your API keys',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Go to Facebook Developers Console\n'
                        '2. Select your WhatsApp Business app\n'
                        '3. Get Access Token from App Dashboard\n'
                        '4. Get Phone Number ID from WhatsApp > Phone Numbers\n'
                        '5. Get Business Account ID from Business Settings',
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
      ),
    );
  }

  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF17A2B8)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 API Setup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To get your WhatsApp Business API credentials:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('🌐 Visit: developers.facebook.com'),
              SizedBox(height: 8),
              Text('📱 Create or select your WhatsApp Business app'),
              SizedBox(height: 8),
              Text('🔑 Generate Access Token in App Dashboard'),
              SizedBox(height: 8),
              Text('📞 Get Phone Number ID from WhatsApp section'),
              SizedBox(height: 8),
              Text('🏢 Get Business Account ID from Settings'),
              SizedBox(height: 12),
              Text(
                'Need help? Contact our support team!',
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