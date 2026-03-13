import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http; // ADDED for Graph API calls

class FacebookAndInstagramScreen extends StatefulWidget {
  const FacebookAndInstagramScreen({super.key});

  @override
  State<FacebookAndInstagramScreen> createState() =>
      _FacebookAndInstagramScreenState();
}

class _FacebookAndInstagramScreenState
    extends State<FacebookAndInstagramScreen> {
  final List<Map<String, dynamic>> _accounts = [];

  final TextEditingController _facebookTokenController =
      TextEditingController();
  final TextEditingController _facebookAccountIdController =
      TextEditingController();

  // Hidden state variables for the extra data we fetch automatically
  String? _fetchedPageToken;
  String? _fetchedInstagramAccountId;
  String? _fetchedFbName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _facebookTokenController.dispose();
    _facebookAccountIdController.dispose();
    super.dispose();
  }

  // --- 1. LOAD LOGIC ---
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
            });

            _facebookTokenController.text =
                response['facebook_user_access_token'] ?? '';
            _facebookAccountIdController.text =
                response['facebook_account_id'] ?? '';

            _fetchedPageToken = response['facebook_page_access_token'];
            _fetchedInstagramAccountId = response['instagram_account_id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. SAVE LOGIC (Upgraded for new columns) ---
  Future<void> _saveSettingsToSupabase() async {
    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Mapping exactly to your Supabase schema
      final data = {
        'user_id': user.id,
        'facebook_user_access_token': _facebookTokenController.text.isEmpty
            ? null
            : _facebookTokenController.text,
        'facebook_account_id': _facebookAccountIdController.text.isEmpty
            ? null
            : _facebookAccountIdController.text,
        'facebook_page_access_token': _fetchedPageToken,
        'instagram_account_id': _fetchedInstagramAccountId,
        // Because Instagram uses the Page/User token for Graph API:
        'instagram_access_token':
            _fetchedPageToken ?? _facebookTokenController.text,
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
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Accounts Saved Successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. CLEAR LOGIC ---
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
        _facebookTokenController.clear();
        _facebookAccountIdController.clear();
        _fetchedPageToken = null;
        _fetchedInstagramAccountId = null;
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

  // --- 4. ADVANCED FACEBOOK LOGIN LOGIC ---
  Future<void> _handleFacebookLogin() async {
    try {
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
        ],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final userToken = accessToken.tokenString;

        // 1. Get User Profile ID
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
                    'Manage your Graph API access tokens and Account IDs.',
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
                      itemBuilder: (context, index) {
                        return _buildAccountCard(_accounts[index], index);
                      },
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
            Text(
              'No social accounts connected.',
              style: TextStyle(color: Colors.grey[500]),
            ),
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
    String maskToken(String? token) {
      if (token == null || token.isEmpty) return "Not Set";
      if (token.length <= 4) return "****";
      return "••••••••${token.characters.takeLast(4)}";
    }

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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _showConfigDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _clearSocialSettings(index),
                    ),
                  ],
                ),
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
              const Text(
                "Facebook Page",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              _buildInfoRow("Page Token", maskToken(account['page_token'])),
              const SizedBox(height: 12),
            ],

            if (account['instagram_account_id'] != null) ...[
              const Text(
                "Instagram",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              _buildInfoRow(
                "IG Account ID",
                account['instagram_account_id'] ?? 'Not Set',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (value != 'Not Set')
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Accounts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleFacebookLogin,
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text("Auto-Connect Meta Suite"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "This will securely fetch your User Token, Page Token, and Instagram ID.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveSettingsToSupabase,
            child: const Text('Save to Database'),
          ),
        ],
      ),
    );
  }
}
