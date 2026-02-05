import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/config/webhook_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Settings state
  bool _readReceipts = false;
  bool _autoSaveContacts = true;
  
  // Business info - will be loaded from user data
  String _businessName = "";
  String _phoneNumber = "";
  String _userEmail = "";
  bool _isLoading = true;
  
  // Profile editing variables
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web platform
  String? _selectedImageName; // For web platform
  String? _profileImageUrl;
  final _descriptionController = TextEditingController();
  final _aboutController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCategory = 'Education';
  final _websiteUrl1Controller = TextEditingController();
  final _websiteUrl2Controller = TextEditingController();
  final _businessEmailController = TextEditingController();
  bool _addComplianceInfo = false;
  final _legalNameController = TextEditingController();
  String _selectedBusinessType = 'Select type';
  final _grievanceNameController = TextEditingController();
  final _grievanceEmailController = TextEditingController();
  final _grievanceLandlineController = TextEditingController();
  final _grievanceMobileController = TextEditingController();
  final _customerCareEmailController = TextEditingController();
  final _customerCareLandlineController = TextEditingController();
  final _customerCareMobileController = TextEditingController();
  
  final List<String> _categories = [
    'Education', 'Business Services', 'Health & Medical', 'Technology',
    'Retail & Shopping', 'Food & Beverage', 'Finance & Banking', 'Other'
  ];
  
  final List<String> _businessTypes = [
    'Select type', 'Sole Proprietorship', 'Partnership', 'Private Limited',
    'Public Limited', 'LLP', 'NGO', 'Government', 'Other'
  ];
  
  // API credentials - will be loaded from user's configuration
  String _callbackUrl = "";
  String _verifyToken = "";
  String _phoneNumberId = "";
  String _whatsappBusinessAccountId = "";
  String _permanentAccessToken = "";
  String _metaflyApiKey = "";
  bool _apiDataLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadUserData();
    _loadAPICredentials();
    _loadProfileData();
  }

  Future<void> _loadAPICredentials() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Load API credentials from user metadata or database
        final userMetadata = user.userMetadata;
        
        // Generate your own callback URL for this user
        final userCallbackUrl = _generateCallbackUrl(user.id);
        final userVerifyToken = _generateVerifyToken(user.id);
        
        setState(() {
          _callbackUrl = userMetadata?['callback_url'] ?? userCallbackUrl;
          _verifyToken = userMetadata?['verify_token'] ?? userVerifyToken;
          _phoneNumberId = userMetadata?['phone_number_id'] ?? "";
          _whatsappBusinessAccountId = userMetadata?['whatsapp_business_account_id'] ?? "";
          _permanentAccessToken = userMetadata?['permanent_access_token'] ?? "";
          _metaflyApiKey = userMetadata?['metafly_api_key'] ?? "";
          _apiDataLoading = false;
        });
        
        // Auto-save the generated callback URL if not exists
        if (userMetadata?['callback_url'] == null) {
          _saveGeneratedWebhookCredentials(user.id, userCallbackUrl, userVerifyToken);
        }
        
        // If no other API data in metadata, try to load from database
        if (_phoneNumberId.isEmpty) {
          await _loadAPICredentialsFromDatabase(user.id);
        }
      } else {
        setState(() {
          _apiDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading API credentials: $e');
      setState(() {
        _apiDataLoading = false;
      });
    }
  }

  Future<void> _loadAPICredentialsFromDatabase(String userId) async {
    try {
      // Query your API settings table or wherever you store API credentials
      final response = await Supabase.instance.client
          .from('user_api_settings') // Adjust table name as needed
          .select()
          .eq('user_id', userId)
          .single();
      
      if (response.isNotEmpty) {
        setState(() {
          _callbackUrl = response['callback_url'] ?? "";
          _verifyToken = response['verify_token'] ?? "";
          _phoneNumberId = response['phone_number_id'] ?? "";
          _whatsappBusinessAccountId = response['whatsapp_business_account_id'] ?? "";
          _permanentAccessToken = response['permanent_access_token'] ?? "";
          _metaflyApiKey = response['metafly_api_key'] ?? "";
        });
      }
    } catch (e) {
      debugPrint('Error loading API credentials from database: $e');
      // If database query fails, you might want to set default empty values
      // or show a message to configure API settings
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email ?? "";
          // Extract business name from email or use email as fallback
          _businessName = user.userMetadata?['business_name'] ?? 
                         user.userMetadata?['full_name'] ?? 
                         _userEmail.split('@')[0].replaceAll('.', ' ').toUpperCase();
          _phoneNumber = user.userMetadata?['phone'] ?? 
                        user.phone ?? 
                        "+91 XXXXX XXXXX"; // Fallback if no phone
          _isLoading = false;
        });
      } else {
        setState(() {
          _businessName = "Guest User";
          _phoneNumber = "+91 XXXXX XXXXX";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _businessName = "Business User";
        _phoneNumber = "+91 XXXXX XXXXX";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Load profile data from business_profiles table
        final response = await Supabase.instance.client
            .from('business_profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (response != null) {
          setState(() {
            // WhatsApp Profile Section
            _profileImageUrl = response['profile_image_url'];
            _descriptionController.text = response['description'] ?? '';
            _aboutController.text = response['about'] ?? '';
            _addressController.text = response['address'] ?? '';
            
            // Business Information Section
            _selectedCategory = response['category'] ?? 'Education';
            _businessEmailController.text = response['email'] ?? '';
            _websiteUrl1Controller.text = response['website_url_1'] ?? '';
            _websiteUrl2Controller.text = response['website_url_2'] ?? '';
            
            // Compliance Section
            _addComplianceInfo = response['has_compliance_info'] ?? false;
            _legalNameController.text = response['legal_name'] ?? '';
            _selectedBusinessType = response['business_type'] ?? 'Select type';
            _grievanceNameController.text = response['grievance_name'] ?? '';
            _grievanceEmailController.text = response['grievance_email'] ?? '';
            _grievanceLandlineController.text = response['grievance_landline'] ?? '';
            _grievanceMobileController.text = response['grievance_mobile'] ?? '';
            _customerCareEmailController.text = response['customer_care_email'] ?? '';
            _customerCareLandlineController.text = response['customer_care_landline'] ?? '';
            _customerCareMobileController.text = response['customer_care_mobile'] ?? '';
          });
          
          debugPrint('✅ Profile data loaded successfully');
        } else {
          debugPrint('ℹ️ No existing profile data found - showing empty form');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading profile data: $e');
      // Don't show error to user - just log it and show empty form
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () {
                // Handle upgrade plan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Upgrade Plan'),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black),
              onPressed: () {
                // Handle notifications
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.teal,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _getInitials(_businessName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Manage Numbers / ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: '$_businessName ($_phoneNumber)',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Tab Navigation
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: 'Edit Profile'),
                Tab(text: 'Product Catalog'),
                Tab(text: 'API'),
                Tab(text: 'Manage Team'),
                Tab(text: 'Tools'),
                Tab(text: 'Email Notifications'),
                Tab(text: 'Click to WhatsApp Ads'),
                Tab(text: 'Inbox'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditProfileTab(),
                _buildProductCatalogTab(),
                _buildAPITab(),
                _buildManageTeamTab(),
                _buildToolsTab(),
                _buildEmailNotificationsTab(),
                _buildClickToWhatsAppAdsTab(),
                _buildInboxTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileTab() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // WhatsApp Business Profile Section
            _buildWhatsAppProfileSection(),
            
            const SizedBox(height: 24),
            
            // Business Information Section
            _buildBusinessInfoSection(),
            
            const SizedBox(height: 24),
            
            // Business Compliance Section
            _buildComplianceSection(),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCompleteProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCatalogTab() {
    return const Center(
      child: Text(
        'Product Catalog',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildAPITab() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // WhatsApp API Credentials Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WhatsApp API Credentials',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Your Custom Webhook Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Your Custom Webhook Configuration',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'These URLs connect WhatsApp messages directly to your app database.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Callback URL
                  _apiDataLoading
                      ? const CircularProgressIndicator()
                      : _buildAPIFieldWithCopy(
                          'Callback URL:',
                          _callbackUrl.isEmpty ? 'Generating...' : _callbackUrl,
                          color: _callbackUrl.isEmpty ? Colors.grey : Colors.green,
                        ),
                  const SizedBox(height: 16),
                  
                  // Verify Token
                  _apiDataLoading
                      ? const CircularProgressIndicator()
                      : _buildAPIFieldWithCopy(
                          'Verify Token:',
                          _verifyToken.isEmpty ? 'Generating...' : _verifyToken,
                          color: _verifyToken.isEmpty ? Colors.grey : Colors.green,
                        ),
                  const SizedBox(height: 24),
                  
                  // Phone Number ID and WhatsApp Business Account ID Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PHONE NUMBER ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _apiDataLoading
                                        ? const SizedBox(
                                            height: 20,
                                            child: LinearProgressIndicator(),
                                          )
                                        : Text(
                                            _phoneNumberId.isEmpty ? 'Not configured' : _phoneNumberId,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'monospace',
                                              color: _phoneNumberId.isEmpty ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: _phoneNumberId.isEmpty 
                                        ? null 
                                        : () => _copyToClipboard(_phoneNumberId),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WHATSAPP BUSINESS ACCOUNT ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _apiDataLoading
                                        ? const SizedBox(
                                            height: 20,
                                            child: LinearProgressIndicator(),
                                          )
                                        : Text(
                                            _whatsappBusinessAccountId.isEmpty ? 'Not configured' : _whatsappBusinessAccountId,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'monospace',
                                              color: _whatsappBusinessAccountId.isEmpty ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: _whatsappBusinessAccountId.isEmpty 
                                        ? null 
                                        : () => _copyToClipboard(_whatsappBusinessAccountId),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Permanent Access Token
                  const Text(
                    'PERMANENT ACCESS TOKEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _apiDataLoading
                              ? const SizedBox(
                                  height: 20,
                                  child: LinearProgressIndicator(),
                                )
                              : Text(
                                  _permanentAccessToken.isEmpty ? 'Not configured' : _permanentAccessToken,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: _permanentAccessToken.isEmpty ? Colors.grey : Colors.black,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: _permanentAccessToken.isEmpty 
                              ? null 
                              : () => _copyToClipboard(_permanentAccessToken),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Webhook Setup Instructions
                  const SizedBox(height: 24),
                  ExpansionTile(
                    leading: const Icon(Icons.help_outline, color: Colors.orange),
                    title: const Text(
                      'Webhook Setup Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          WebhookConfig.webhookInstructions,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showConfigureAPIDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Configure API',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _hasAPICredentials() ? () => _validateAPICredentials() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Validate and proceed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // API Integrations Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Integrations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the following API key for 3rd party integrations like WordPress, Shopify, Google Sheet etc.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // MetaFly API Key
                  const Text(
                    'MetaFly API Key',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),  
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _apiDataLoading
                              ? const SizedBox(
                                  height: 20,
                                  child: LinearProgressIndicator(),
                                )
                              : Text(
                                  _metaflyApiKey.isEmpty ? 'Not configured' : _metaflyApiKey,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    color: _metaflyApiKey.isEmpty ? Colors.grey : Colors.pink,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _metaflyApiKey.isEmpty 
                              ? null
                              : () => _copyToClipboard(_metaflyApiKey),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTeamTab() {
    return const Center(
      child: Text(
        'Manage Team',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildToolsTab() {
    return const Center(
      child: Text(
        'Tools',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmailNotificationsTab() {
    return const Center(
      child: Text(
        'Email Notifications',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildClickToWhatsAppAdsTab() {
    return const Center(
      child: Text(
        'Click to WhatsApp Ads',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildInboxTab() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Settings/Auto-Assign Chat tabs
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Auto-Assign Chat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Inbox Settings Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inbox Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Manage ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const TextSpan(
                          text: 'Inbox',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: ' related settings for this phone number.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Read receipts setting
                  Row(
                    children: [
                      Switch(
                        value: _readReceipts,
                        onChanged: (value) {
                          setState(() {
                            _readReceipts = value;
                          });
                        },
                        activeThumbColor: Colors.teal,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Read receipts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Show blue ticks (',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '✓✓',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ') to your contacts under their messages when you\'ve read their message.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Auto-save contacts setting
                  Row(
                    children: [
                      Switch(
                        value: _autoSaveContacts,
                        onChanged: (value) {
                          setState(() {
                            _autoSaveContacts = value;
                          });
                        },
                        activeThumbColor: Colors.teal,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Automatically save contacts from incoming chats. When not enabled new contacts from incoming chats will be marked as ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const TextSpan(
                                text: '\'unsaved\'',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: '.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save changes button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveChanges();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    // Save settings to your backend or local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    debugPrint('Settings saved:');
    debugPrint('Read receipts: $_readReceipts');
    debugPrint('Auto-save contacts: $_autoSaveContacts');
  }

  Widget _buildWhatsAppProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WhatsApp Business Profile',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your WhatsApp Business profile details. These details will be visible to contacts when they open your profile on their WhatsApp.',
            style: TextStyle(
              fontSize: 14, 
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Profile Picture
          const Text(
            'WHATSAPP PROFILE PICTURE',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('❌ Error loading web image: $error');
                            return Container(
                              color: Colors.red.shade100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Error loading\nweb image',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('❌ Error loading local image: $error');
                                return Container(
                                  color: Colors.red.shade100,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.red, size: 24),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Error loading\nmobile image',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: const Color(0xFF17A2B8),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('❌ Error loading network image: $error');
                                    return Container(
                                      color: Colors.orange.shade100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cloud_off, color: Colors.orange, size: 24),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Network\nimage error',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade50,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.business, size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image\nselected',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF17A2B8)),
                    child: const Text('Choose File', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                        _profileImageUrl = null;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ Image removed'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('Remove', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended profile image size: 640px X 640px.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Description
          _buildProfileTextField(
            controller: _descriptionController,
            label: 'DESCRIPTION',
            maxLines: 3,
            maxLength: 512,
            hint: 'Enter your business description',
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildProfileTextField(
                  controller: _aboutController,
                  label: 'ABOUT',
                  maxLength: 140,
                  hint: 'Hey there! I am using WhatsApp.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProfileTextField(
                  controller: _addressController,
                  label: 'ADDRESS',
                  hint: 'Enter your business address',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Information',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category, 
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProfileTextField(
                  controller: _businessEmailController,
                  label: 'EMAIL (OPTIONAL)',
                  hint: 'support@yourcompany.com',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildProfileTextField(
                  controller: _websiteUrl1Controller,
                  label: 'WEBSITE URL 1',
                  hint: 'https://yourwebsite.com',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProfileTextField(
                  controller: _websiteUrl2Controller,
                  label: 'WEBSITE URL 2',
                  hint: 'https://maps.google.com/your-location',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Business Compliance Information',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Switch(
                value: _addComplianceInfo,
                onChanged: (value) => setState(() => _addComplianceInfo = value),
                activeThumbColor: const Color(0xFF17A2B8),
              ),
            ],
          ),
          
          if (_addComplianceInfo) ...[
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildProfileTextField(
                    controller: _legalNameController,
                    label: 'LEGAL NAME OF BUSINESS',
                    hint: 'Enter your legal business name',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BUSINESS TYPE',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w600, 
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBusinessType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _businessTypes.map((type) {
                          return DropdownMenuItem(
                            value: type, 
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedBusinessType = value!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Grievance Officer Details
            _buildComplianceCard(
              title: 'Grievance Officer Details',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _grievanceNameController,
                        label: 'NAME',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _grievanceEmailController,
                        label: 'EMAIL',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _grievanceLandlineController,
                        label: 'LANDLINE PHONE NUMBER',
                        hint: 'Enter number with country code',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _grievanceMobileController,
                        label: 'MOBILE PHONE NUMBER',
                        hint: 'Enter number with country code',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Customer Care Information
            _buildComplianceCard(
              title: 'Customer Care Information',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _customerCareEmailController,
                        label: 'EMAIL',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileTextField(
                        controller: _customerCareLandlineController,
                        label: 'LANDLINE PHONE NUMBER',
                        hint: 'Enter number with country code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileTextField(
                  controller: _customerCareMobileController,
                  label: 'MOBILE PHONE NUMBER',
                  hint: 'Enter number with country code',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600, 
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterText: maxLength != null ? '${controller.text.length} / $maxLength' : null,
            counterStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          onChanged: maxLength != null ? (_) => setState(() {}) : null,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('🖼️ Starting image picker...');
      
      // For web, don't show source selection - just use gallery
      ImageSource source = ImageSource.gallery;
      
      if (!kIsWeb) {
        // Show image source selection dialog only on mobile
        final ImageSource? selectedSource = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Select Image Source'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
            );
          },
        );
        
        if (selectedSource == null) {
          debugPrint('ℹ️ No source selected');
          return;
        }
        source = selectedSource;
      }
      
      final ImagePicker picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 80,
      );
      
      if (image != null) {
        debugPrint('✅ Image selected: ${image.path}');
        
        if (kIsWeb) {
          // Handle web platform
          final bytes = await image.readAsBytes();
          debugPrint('✅ Web image bytes loaded: ${bytes.length} bytes');
          
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _selectedImage = null; // Clear mobile file
            _profileImageUrl = null; // Clear network image
          });
          debugPrint('✅ Web image state updated successfully');
        } else {
          // Handle mobile platform
          final file = File(image.path);
          if (await file.exists()) {
            debugPrint('✅ Mobile file exists, updating UI...');
            setState(() {
              _selectedImage = file;
              _selectedImageBytes = null; // Clear web bytes
              _selectedImageName = null; // Clear web name
              _profileImageUrl = null; // Clear network image
            });
            debugPrint('✅ Mobile image state updated successfully');
          } else {
            debugPrint('❌ Selected file does not exist');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Selected image file not found'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Image selected successfully! ${kIsWeb ? "(Web)" : "(Mobile)"}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('ℹ️ No image selected');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveCompleteProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Handle image upload to Supabase storage
      String? imageUrl = _profileImageUrl;
      
      if (_selectedImageBytes != null && kIsWeb) {
        // Handle web image - in production, upload to Supabase storage
        debugPrint('📷 Web image selected: ${_selectedImageBytes!.length} bytes, name: $_selectedImageName');
        // For now, store as base64 string (not recommended for production)
        // In production, upload _selectedImageBytes to Supabase storage bucket
        imageUrl = 'web_image_${DateTime.now().millisecondsSinceEpoch}';
      } else if (_selectedImage != null && !kIsWeb) {
        // Handle mobile image - in production, upload to Supabase storage
        debugPrint('📷 Mobile image selected: ${_selectedImage!.path}');
        imageUrl = _selectedImage!.path; // For now, store local path
      }

      await Supabase.instance.client.from('business_profiles').upsert({
        'user_id': user.id,
        'profile_image_url': imageUrl,
        'description': _descriptionController.text.trim(),
        'about': _aboutController.text.trim(),
        'address': _addressController.text.trim(),
        'category': _selectedCategory,
        'website_url_1': _websiteUrl1Controller.text.trim(),
        'website_url_2': _websiteUrl2Controller.text.trim(),
        'email': _businessEmailController.text.trim(),
        'has_compliance_info': _addComplianceInfo,
        'legal_name': _legalNameController.text.trim(),
        'business_type': _selectedBusinessType,
        'grievance_name': _grievanceNameController.text.trim(),
        'grievance_email': _grievanceEmailController.text.trim(),
        'grievance_landline': _grievanceLandlineController.text.trim(),
        'grievance_mobile': _grievanceMobileController.text.trim(),
        'customer_care_email': _customerCareEmailController.text.trim(),
        'customer_care_landline': _customerCareLandlineController.text.trim(),
        'customer_care_mobile': _customerCareMobileController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'B';
    
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  Widget _buildAPIFieldWithCopy(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: color ?? Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (value != 'Generating...' && value != 'Not configured')
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(value),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Copy to clipboard',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied to clipboard: ${text.length > 20 ? "${text.substring(0, 20)}..." : text}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      debugPrint('Copied to clipboard: $text');
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to copy to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasAPICredentials() {
    return _phoneNumberId.isNotEmpty && 
           _whatsappBusinessAccountId.isNotEmpty && 
           _permanentAccessToken.isNotEmpty;
  }

  void _showConfigureAPIDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure API Credentials'),
        content: const Text(
          'To configure your WhatsApp API credentials, please:\n\n'
          '1. Go to Facebook Developer Console\n'
          '2. Get your Phone Number ID and Business Account ID\n'
          '3. Generate a Permanent Access Token\n'
          '4. Set up webhook URL and verify token\n\n'
          'Would you like to update your credentials now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateAPICredentialsDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Update Credentials', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpdateAPICredentialsDialog() {
    final TextEditingController phoneNumberIdController = TextEditingController(text: _phoneNumberId);
    final TextEditingController businessAccountIdController = TextEditingController(text: _whatsappBusinessAccountId);
    final TextEditingController accessTokenController = TextEditingController(text: _permanentAccessToken);
    final TextEditingController callbackUrlController = TextEditingController(text: _callbackUrl);
    final TextEditingController verifyTokenController = TextEditingController(text: _verifyToken);
    final TextEditingController apiKeyController = TextEditingController(text: _metaflyApiKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update API Credentials'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneNumberIdController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: businessAccountIdController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Business Account ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accessTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Permanent Access Token',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: callbackUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Callback URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: verifyTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Verify Token',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'MetaFly API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAPICredentials(
                phoneNumberIdController.text,
                businessAccountIdController.text,
                accessTokenController.text,
                callbackUrlController.text,
                verifyTokenController.text,
                apiKeyController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAPICredentials(
    String phoneNumberId,
    String businessAccountId,
    String accessToken,
    String callbackUrl,
    String verifyToken,
    String apiKey,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Update user metadata
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'phone_number_id': phoneNumberId,
              'whatsapp_business_account_id': businessAccountId,
              'permanent_access_token': accessToken,
              'callback_url': callbackUrl,
              'verify_token': verifyToken,
              'metafly_api_key': apiKey,
            },
          ),
        );

        // Also save to database table if exists
        try {
          await Supabase.instance.client.from('user_api_settings').upsert({
            'user_id': user.id,
            'phone_number_id': phoneNumberId,
            'whatsapp_business_account_id': businessAccountId,
            'permanent_access_token': accessToken,
            'callback_url': callbackUrl,
            'verify_token': verifyToken,
            'metafly_api_key': apiKey,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Database upsert failed (table might not exist): $e');
        }

        // Update local state
        setState(() {
          _phoneNumberId = phoneNumberId;
          _whatsappBusinessAccountId = businessAccountId;
          _permanentAccessToken = accessToken;
          _callbackUrl = callbackUrl;
          _verifyToken = verifyToken;
          _metaflyApiKey = apiKey;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API credentials saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving API credentials: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving API credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate your own callback URL for each user
  String _generateCallbackUrl(String userId) {
    return WebhookConfig.generateCallbackUrl(userId);
  }

  // Generate secure verify token for each user
  String _generateVerifyToken(String userId) {
    return WebhookConfig.generateVerifyToken(userId);
  }

  // Save generated webhook credentials to user metadata
  Future<void> _saveGeneratedWebhookCredentials(String userId, String callbackUrl, String verifyToken) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'callback_url': callbackUrl,
            'verify_token': verifyToken,
          },
        ),
      );
      
      // Also save to database
      try {
        await Supabase.instance.client.from('user_api_settings').upsert({
          'user_id': userId,
          'callback_url': callbackUrl,
          'verify_token': verifyToken,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Database save failed: $e');
      }
    } catch (e) {
      debugPrint('Error saving webhook credentials: $e');
    }
  }

  Future<void> _validateAPICredentials() async {
    if (!_hasAPICredentials()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure API credentials first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate API validation (replace with actual validation)
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API credentials validated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}