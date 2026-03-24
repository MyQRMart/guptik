import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS — Set your Meta App ID here. Never put App Secret in client code.
// ─────────────────────────────────────────────────────────────────────────────
const String kMetaAppId = '1647936262889799';
const String kGraphVersion = 'v19.0';

class FacebookAndInstagramScreen extends StatefulWidget {
  const FacebookAndInstagramScreen({super.key});

  @override
  State<FacebookAndInstagramScreen> createState() =>
      _FacebookAndInstagramScreenState();
}

class _FacebookAndInstagramScreenState
    extends State<FacebookAndInstagramScreen> {
  final List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. LOAD SAVED SETTINGS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadSavedKeys() async {
    try {
      setState(() => _isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        bool hasData =
            response['facebook_user_access_token'] != null ||
            response['facebook_account_id'] != null;

        if (hasData) {
          setState(() {
            _accounts.clear();
            _accounts.add({
              'id': response['id'],
              'facebook_token': response['facebook_user_access_token'],
              'facebook_account_id': response['facebook_account_id'],
              'page_token': response['facebook_page_access_token'],
              'instagram_account_id': response['instagram_account_id'],
              'business_id': response['meta_business_account_id'],
              'business_name': response['meta_business_name'],
              'wa_phone_number_id': response['meta_wa_phone_number_id'],
              'mobile_number': response['mobile_number'],
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SAVE ALL SETTINGS TO SUPABASE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _saveSettingsToSupabase() async {
    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // NOTE: instagram_access_token = page token because Instagram Business
      // Graph API authenticates using the Page Access Token, not a separate
      // Instagram-specific token. This is correct Meta API design.
      final data = {
        'user_id': user.id,
        'meta_app_id': kMetaAppId,

        // Facebook User
        'facebook_user_access_token': _userToken,
        'facebook_account_id': _fbAccountId,

        // Facebook Page (selected)
        'facebook_page_access_token': _selectedPageToken,

        // Instagram (uses the same Page token — this is correct per Meta docs)
        'instagram_access_token': _selectedPageToken,
        'instagram_account_id': _selectedIgAccountId,

        // Meta Business
        'meta_business_account_id': _selectedBusinessId,
        'meta_business_name': _selectedBusinessName,

        // WhatsApp
        'whatsapp_access_token': _userToken, // User token works for WABA mgmt
        'meta_wa_phone_number_id': _whatsappPhoneNumberId,
        'mobile_number': _whatsappPhoneNumber,

        // NOTE: instagram_app_secret should NEVER be stored client-side.
        // Store it only in n8n / backend environment variables.
        // instagram_app_id is the same as meta_app_id, so no separate field needed.
      };

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      setState(() {
        _accounts.clear();
        _accounts.add({
          'id': response['id'],
          'facebook_token': response['facebook_user_access_token'],
          'facebook_account_id': response['facebook_account_id'],
          'page_token': response['facebook_page_access_token'],
          'instagram_account_id': response['instagram_account_id'],
          'business_id': response['meta_business_account_id'],
          'business_name': response['meta_business_name'],
          'wa_phone_number_id': response['meta_wa_phone_number_id'],
          'mobile_number': response['mobile_number'],
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All accounts saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CLEAR SETTINGS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _clearSocialSettings(int index) async {
    try {
      final accountId = _accounts[index]['id'];
      if (accountId == null) return;

      setState(() => _isLoading = true);

      await Supabase.instance.client
          .from('user_api_settings')
          .update({
            'facebook_user_access_token': null,
            'facebook_account_id': null,
            'facebook_page_access_token': null,
            'instagram_account_id': null,
            'instagram_access_token': null,
          })
          .eq('id', accountId);

      if (!mounted) return;
      setState(() {
        _accounts.clear();
        _userToken = null;
        _fbAccountId = null;
        _selectedPageToken = null;
        _selectedIgAccountId = null;
        _selectedBusinessId = null;
        _selectedBusinessName = null;
        _whatsappPhoneNumberId = null;
        _whatsappPhoneNumber = null;
        _pages = [];
        _businesses = [];
        _wabaPhoneNumbers = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing settings: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. MAIN FACEBOOK LOGIN + ALL GRAPH API CALLS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleFacebookLogin() async {
    try {
      setState(() => _isLoading = true);

      final LoginResult result = await FacebookAuth.instance.login(
        loginBehavior: LoginBehavior.webOnly,
        permissions: [
          'email',
          'public_profile',
          'pages_show_list',
          'instagram_basic',
          'pages_read_engagement',
          'business_management',
          'instagram_branded_content_brand',
          'instagram_branded_content_creator',
          'instagram_content_publish',
          'instagram_manage_comments',
          'instagram_manage_insights',
          'instagram_manage_messages',
          'manage_fundraisers',
          'pages_manage_engagement',
          'pages_manage_metadata',
          'pages_manage_posts',
          'pages_messaging',
          'pages_read_user_content',
          'pages_utility_messaging',
          'paid_marketing_messages',
          'publish_video',
          'read_insights',
          'whatsapp_business_manage_events',
          'whatsapp_business_management',
          'whatsapp_business_messaging',
          'catalog_management',
          'instagram_manage_upcoming_events',
          'manage_app_solution',
          'instagram_manage_contents',
          'instagram_creator_marketplace_discovery',
          'instagram_branded_content_ads_brand',
        ],
      );

      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          debugPrint("User cancelled login.");
        } else {
          _showSnack('Login Error: ${result.message}', isError: true);
        }
        return;
      }

      final userToken = result.accessToken!.tokenString;
      final userData = await FacebookAuth.instance.getUserData();

        _facebookTokenController.text = userToken;
        _facebookAccountIdController.text = userData['id'];
        _fetchedFbName = userData['name'];

        // 2. Automatically Fetch Page Tokens and Instagram ID from Graph API
        try {
          final url = Uri.parse(
            'https://graph.facebook.com/v19.0/me/accounts?fields=access_token,name,instagram_business_account&access_token=$userToken',
          );

          final graphResponse = await http.get(url);

          if (graphResponse.statusCode == 200) {
            final data = jsonDecode(graphResponse.body);

            if (data['data'] != null && data['data'].isNotEmpty) {
              // Grabbing the first page linked to the account for simplicity
              final pageData = data['data'][0];
              _fetchedPageToken = pageData['access_token'];

              if (pageData['instagram_business_account'] != null) {
                _fetchedInstagramAccountId =
                    pageData['instagram_business_account']['id'];
              }
            }
          }
        } catch (apiError) {
          debugPrint("Graph API Fetch Error: $apiError");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connected as $_fetchedFbName! Click Save to confirm.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint("User cancelled the login.");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Error: ${result.message}')),
          );
        }
      }
    } catch (e) {
      debugPrint("An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Social Media Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_accounts.isEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showConfigDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Facebook & Instagram',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your Meta Business, Pages, WhatsApp & Instagram.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  if (_accounts.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) =>
                          _buildAccountCard(_accounts[index], index),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No social accounts connected.',
                style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showConfigDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
                foregroundColor: Colors.white,
              ),
              child: const Text("Connect Accounts"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Configuration",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: _showConfigDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _clearSocialSettings(index),
                  ),
                ]),
              ],
            ),
            const Divider(),

            if (account['facebook_token'] != null) ...[
              const Text(
                "Facebook User",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              _buildInfoRow(
                "Account ID",
                account['facebook_account_id'] ?? 'Not Set',
              ),
              _buildInfoRow("Token", maskToken(account['facebook_token'])),
              const SizedBox(height: 12),
            ],

            if (account['page_token'] != null) ...[
              _sectionHeader('Facebook Page', Colors.orange),
              _buildInfoRow("Page Token", _maskToken(account['page_token'])),
              const SizedBox(height: 12),
            ],

            if (account['instagram_account_id'] != null) ...[
              _sectionHeader('Instagram', Colors.pink),
              _buildInfoRow("IG Account ID", account['instagram_account_id']),
              const SizedBox(height: 12),
            ],

            if (account['business_id'] != null) ...[
              _sectionHeader('Meta Business', const Color(0xFF0082FB)),
              _buildInfoRow("Business ID", account['business_id']),
              _buildInfoRow("Business Name", account['business_name'] ?? '—'),
              const SizedBox(height: 12),
            ],

            if (account['wa_phone_number_id'] != null) ...[
              _sectionHeader('WhatsApp', Colors.green),
              _buildInfoRow("Phone Number ID", account['wa_phone_number_id']),
              _buildInfoRow("Number", account['mobile_number'] ?? '—'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (value != '—' && value != 'Not Set')
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
