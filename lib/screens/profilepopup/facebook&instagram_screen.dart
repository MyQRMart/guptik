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

  // ── All data fetched during the login flow ──
  String? _userToken;
  String? _fbAccountId;
  String? _fbName;

  // Selected page & Instagram
  String? _selectedPageToken;
  String? _selectedPageId;
  String? _selectedPageName;
  String? _selectedIgAccountId;

  // Selected Business
  String? _selectedBusinessId;
  String? _selectedBusinessName;

  // WhatsApp
  String? _whatsappPhoneNumberId;
  String? _whatsappPhoneNumber; // The actual mobile number e.g. +91XXXXXXXXXX
  String? _selectedWabaId;

  // Raw lists for letting the user pick (if multiple)
  List<Map<String, dynamic>> _pages = [];
  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _wabaPhoneNumbers = [];

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
        final hasData =
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
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your Facebook account first.'),
        ),
      );
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
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
            'instagram_access_token': null,
            'instagram_account_id': null,
            'meta_business_account_id': null,
            'meta_business_name': null,
            'whatsapp_access_token': null,
            'meta_wa_phone_number_id': null,
            'mobile_number': null,
            'meta_app_id': null,
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
      ).showSnackBar(SnackBar(content: Text('Error removing: $e')));
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

      setState(() {
        _userToken = userToken;
        _fbAccountId = userData['id'];
        _fbName = userData['name'];
      });

      // ── GRAPH API CALL 1: Pages + Linked Instagram Accounts ──────────────
      await _fetchPagesAndInstagram(userToken);

      // ── GRAPH API CALL 2: Businesses ──────────────────────────────────────
      await _fetchBusinesses(userToken);

      // ── GRAPH API CALLS 3 & 4: WhatsApp Business → Phone Numbers ─────────
      if (_businesses.isNotEmpty) {
        await _fetchWhatsAppNumbers(userToken, _businesses.first['id']);
      }

      if (mounted) {
        _showSnack(
          '✅ Connected as $_fbName! Review selections and tap Save.',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint("Login error: $e");
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API CALL 1: /me/accounts — Pages + linked Instagram
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchPagesAndInstagram(String userToken) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/me/accounts'
        '?fields=id,name,access_token,instagram_business_account'
        '&access_token=$userToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Pages API error: ${res.body}');
        return;
      }
      final data = jsonDecode(res.body);
      final List pages = data['data'] ?? [];

      setState(() {
        _pages = pages
            .map<Map<String, dynamic>>(
              (p) => {
                'id': p['id'],
                'name': p['name'],
                'access_token': p['access_token'],
                'instagram_business_account':
                    p['instagram_business_account']?['id'],
              },
            )
            .toList();

        // Auto-select first page that has an Instagram account; fallback to first page
        final pageWithIg = _pages.firstWhere(
          (p) => p['instagram_business_account'] != null,
          orElse: () => _pages.isNotEmpty ? _pages.first : {},
        );

        if (pageWithIg.isNotEmpty) {
          _selectedPageToken = pageWithIg['access_token'];
          _selectedPageId = pageWithIg['id'];
          _selectedPageName = pageWithIg['name'];
          _selectedIgAccountId = pageWithIg['instagram_business_account'];
        }
      });

      debugPrint('✅ Pages fetched: ${_pages.length}');
    } catch (e) {
      debugPrint('Error fetching pages: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API CALL 2: /me/businesses — Business Accounts
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchBusinesses(String userToken) async {
    try {
      final url = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/me/businesses'
        '?fields=id,name'
        '&access_token=$userToken',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) {
        debugPrint('Businesses API error: ${res.body}');
        return;
      }
      final data = jsonDecode(res.body);
      final List biz = data['data'] ?? [];

      setState(() {
        _businesses = biz
            .map<Map<String, dynamic>>(
              (b) => {'id': b['id'], 'name': b['name']},
            )
            .toList();

        if (_businesses.isNotEmpty) {
          _selectedBusinessId = _businesses.first['id'];
          _selectedBusinessName = _businesses.first['name'];
        }
      });

      debugPrint('✅ Businesses fetched: ${_businesses.length}');
    } catch (e) {
      debugPrint('Error fetching businesses: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GRAPH API CALL 3+4: WABA → Phone Numbers
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _fetchWhatsAppNumbers(
    String userToken,
    String businessId,
  ) async {
    try {
      // Step A: Get WhatsApp Business Accounts under this Business
      final wabaUrl = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$businessId/owned_whatsapp_business_accounts'
        '?fields=id,name'
        '&access_token=$userToken',
      );
      final wabaRes = await http.get(wabaUrl);
      if (wabaRes.statusCode != 200) {
        debugPrint('WABA API error: ${wabaRes.body}');
        return;
      }
      final wabaData = jsonDecode(wabaRes.body);
      final List wabas = wabaData['data'] ?? [];

      if (wabas.isEmpty) {
        debugPrint('No WABA found for business $businessId');
        return;
      }

      final wabaId = wabas.first['id'];
      setState(() => _selectedWabaId = wabaId);

      // Step B: Get Phone Numbers under this WABA
      final phoneUrl = Uri.parse(
        'https://graph.facebook.com/$kGraphVersion/$wabaId/phone_numbers'
        '?fields=id,display_phone_number,verified_name'
        '&access_token=$userToken',
      );
      final phoneRes = await http.get(phoneUrl);
      if (phoneRes.statusCode != 200) {
        debugPrint('Phone Numbers API error: ${phoneRes.body}');
        return;
      }
      final phoneData = jsonDecode(phoneRes.body);
      final List phones = phoneData['data'] ?? [];

      setState(() {
        _wabaPhoneNumbers = phones
            .map<Map<String, dynamic>>(
              (p) => {
                'id': p['id'], // This is meta_wa_phone_number_id
                'display_phone_number':
                    p['display_phone_number'], // This is mobile_number
                'verified_name': p['verified_name'],
              },
            )
            .toList();

        if (_wabaPhoneNumbers.isNotEmpty) {
          _whatsappPhoneNumberId = _wabaPhoneNumbers.first['id'];
          _whatsappPhoneNumber =
              _wabaPhoneNumbers.first['display_phone_number'];
        }
      });

      debugPrint(
        '✅ WhatsApp phone numbers fetched: ${_wabaPhoneNumbers.length}',
      );
    } catch (e) {
      debugPrint('Error fetching WhatsApp numbers: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return "Not Set";
    if (token.length <= 8) return "****";
    return "••••••••${token.substring(token.length - 6)}";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOG — Shows login button + selection dropdowns if multiple options
  // ─────────────────────────────────────────────────────────────────────────
  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Connect Meta Suite'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _handleFacebookLogin();
                      setDialogState(() {}); // Refresh dialog UI after login
                    },
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: Text(
                      _userToken == null
                          ? "Login with Facebook"
                          : "Re-Login (${_fbName ?? ''})",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const Text('Fetching your Meta data...'),
                ],

                // ── Page Selector ──────────────────────────────────────────
                if (_pages.length > 1) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Facebook Page:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPageId,
                    items: _pages.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(
                          '${p['name']} (${p['instagram_business_account'] != null ? '✅IG' : '❌IG'})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        final page = _pages.firstWhere((p) => p['id'] == val);
                        _selectedPageId = page['id'];
                        _selectedPageName = page['name'];
                        _selectedPageToken = page['access_token'];
                        _selectedIgAccountId =
                            page['instagram_business_account'];
                      });
                    },
                  ),
                ],

                // ── Business Selector ──────────────────────────────────────
                if (_businesses.length > 1) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Business Account:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBusinessId,
                    items: _businesses.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['id'],
                        child: Text(b['name'], overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setDialogState(() => _selectedBusinessId = val);
                      // Re-fetch WhatsApp numbers for the newly selected business
                      if (_userToken != null && val != null) {
                        await _fetchWhatsAppNumbers(_userToken!, val);
                        setDialogState(() {});
                      }
                    },
                  ),
                ],

                // ── WhatsApp Phone Number Selector ─────────────────────────
                if (_wabaPhoneNumbers.length > 1) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select WhatsApp Number:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _whatsappPhoneNumberId,
                    items: _wabaPhoneNumbers.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['display_phone_number']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        final phone = _wabaPhoneNumbers.firstWhere(
                          (p) => p['id'] == val,
                        );
                        _whatsappPhoneNumberId = phone['id'];
                        _whatsappPhoneNumber = phone['display_phone_number'];
                      });
                    },
                  ),
                ],

                // ── Summary after login ────────────────────────────────────
                if (_userToken != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  _summaryRow('FB User', _fbName ?? '—'),
                  _summaryRow('Page', _selectedPageName ?? '—'),
                  _summaryRow('IG Account ID', _selectedIgAccountId ?? 'None'),
                  _summaryRow('Business', _selectedBusinessName ?? '—'),
                  _summaryRow('WA Number', _whatsappPhoneNumber ?? 'None'),
                ],

                const SizedBox(height: 8),
                const Text(
                  '⚠️ App Secret is NEVER stored here — keep it in your n8n/backend env only.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
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
              onPressed: _userToken != null ? _saveSettingsToSupabase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save All to Database'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
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
              _sectionHeader('Facebook User', Colors.blue),
              _buildInfoRow(
                "Account ID",
                account['facebook_account_id'] ?? '—',
              ),
              _buildInfoRow("Token", _maskToken(account['facebook_token'])),
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
