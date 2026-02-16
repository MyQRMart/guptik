import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacebookAndInstagramScreen extends StatefulWidget {
  const FacebookAndInstagramScreen({super.key});

  @override
  State<FacebookAndInstagramScreen> createState() => _FacebookAndInstagramScreenState();
}

class _FacebookAndInstagramScreenState extends State<FacebookAndInstagramScreen> {
  final List<Map<String, dynamic>> _accounts = [];

  final TextEditingController _instagramTokenController = TextEditingController();
  final TextEditingController _instagramAccountIdController = TextEditingController();
  final TextEditingController _facebookTokenController = TextEditingController();
  final TextEditingController _facebookAccountIdController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _instagramTokenController.dispose();
    _instagramAccountIdController.dispose();
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
        // UPDATED: Check for 'facebook_user_access_token' instead of 'facebook_access_token'
        bool hasData = response['instagram_access_token'] != null || 
                       response['instagram_account_id'] != null ||
                       response['facebook_user_access_token'] != null || 
                       response['facebook_account_id'] != null;

        if (hasData) {
          setState(() {
            _accounts.clear();
            _accounts.add({
              'id': response['id'],
              'instagram_token': response['instagram_access_token'],
              'instagram_account_id': response['instagram_account_id'],
              // UPDATED KEY:
              'facebook_token': response['facebook_user_access_token'], 
              'facebook_account_id': response['facebook_account_id'],
            });

            _instagramTokenController.text = response['instagram_access_token'] ?? '';
            _instagramAccountIdController.text = response['instagram_account_id'] ?? '';
            // UPDATED KEY:
            _facebookTokenController.text = response['facebook_user_access_token'] ?? '';
            _facebookAccountIdController.text = response['facebook_account_id'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. SAVE LOGIC ---
  Future<void> _saveSettingsToSupabase() async {
    try {
      Navigator.pop(context); 
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'user_id': user.id,
        'instagram_access_token': _instagramTokenController.text.isEmpty ? null : _instagramTokenController.text,
        'instagram_account_id': _instagramAccountIdController.text.isEmpty ? null : _instagramAccountIdController.text,
        // UPDATED COLUMN NAME:
        'facebook_user_access_token': _facebookTokenController.text.isEmpty ? null : _facebookTokenController.text,
        'facebook_account_id': _facebookAccountIdController.text.isEmpty ? null : _facebookAccountIdController.text,
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
          'instagram_token': response['instagram_access_token'],
          'instagram_account_id': response['instagram_account_id'],
          // UPDATED KEY:
          'facebook_token': response['facebook_user_access_token'],
          'facebook_account_id': response['facebook_account_id'],
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
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
            'instagram_access_token': null,
            'instagram_account_id': null,
            // UPDATED COLUMN NAME:
            'facebook_user_access_token': null,
            'facebook_account_id': null,
          })
          .eq('id', accountId);

      setState(() {
        _accounts.clear(); 
        _instagramTokenController.clear();
        _instagramAccountIdController.clear();
        _facebookTokenController.clear();
        _facebookAccountIdController.clear();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  foregroundColor: Colors.white),
              child: const Text("Connect Accounts"),
            )
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
            
            if (account['instagram_token'] != null || account['instagram_account_id'] != null) ...[
                const Text("Instagram", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                _buildInfoRow("Account ID", account['instagram_account_id'] ?? 'Not Set'),
                _buildInfoRow("Token", maskToken(account['instagram_token'])),
                const SizedBox(height: 12),
            ],
            
            if (account['facebook_token'] != null || account['facebook_account_id'] != null) ...[
                const Text("Facebook", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                _buildInfoRow("Account ID", account['facebook_account_id'] ?? 'Not Set'),
                _buildInfoRow("Token", maskToken(account['facebook_token'])),
            ]
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
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          if (value != 'Not Set')
            InkWell(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            )
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
              const Text("Instagram", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 10),
              TextField(
                controller: _instagramTokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token', 
                  border: OutlineInputBorder(), 
                  isDense: true,
                  prefixIcon: Icon(Icons.key, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _instagramAccountIdController,
                decoration: const InputDecoration(
                  labelText: 'Account ID', 
                  border: OutlineInputBorder(), 
                  isDense: true,
                  prefixIcon: Icon(Icons.numbers, size: 18),
                ),
              ),
              const Divider(height: 30),
              const Text("Facebook", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 10),
              TextField(
                controller: _facebookTokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token', 
                  border: OutlineInputBorder(), 
                  isDense: true,
                  prefixIcon: Icon(Icons.key, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _facebookAccountIdController,
                decoration: const InputDecoration(
                  labelText: 'Account ID', 
                  border: OutlineInputBorder(), 
                  isDense: true,
                  prefixIcon: Icon(Icons.numbers, size: 18),
                ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}