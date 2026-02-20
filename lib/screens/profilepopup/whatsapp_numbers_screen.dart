import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsAppNumbersScreen extends StatefulWidget {
  const WhatsAppNumbersScreen({super.key});

  @override
  State<WhatsAppNumbersScreen> createState() => _WhatsAppNumbersScreenState();
}

class _WhatsAppNumbersScreenState extends State<WhatsAppNumbersScreen> {
  final List<Map<String, dynamic>> _accounts = [];

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _phoneIdController = TextEditingController();
  final TextEditingController _businessIdController = TextEditingController();
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _phoneIdController.dispose();
    _businessIdController.dispose();
    _appIdController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedKeys() async {
    try {
      setState(() => _isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _accounts.clear();
          for (var item in response) {
            _accounts.add({
              'id': item['id'],
              'token': item['whatsapp_access_token'],
              'phone_id': item['meta_wa_phone_number_id'],
              'business_id': item['meta_business_account_id'],
              'app_id': item['meta_app_id'],
              'mobile_number': item['mobile_number'],
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAccountToSupabase() async {
    if (_tokenController.text.isEmpty ||
        _phoneIdController.text.isEmpty ||
        _businessIdController.text.isEmpty ||
        _appIdController.text.isEmpty) {
      return;
    }

    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'user_id': user.id,
        'whatsapp_access_token': _tokenController.text,
        'meta_wa_phone_number_id': _phoneIdController.text,
        'meta_business_account_id': _businessIdController.text,
        'meta_app_id': _appIdController.text,
        'mobile_number': _mobileNumberController.text,
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
          'token': _tokenController.text,
          'phone_id': _phoneIdController.text,
          'business_id': _businessIdController.text,
          'app_id': _appIdController.text,
          'mobile_number': _mobileNumberController.text,
        });
      });

      _tokenController.clear();
      _phoneIdController.clear();
      _businessIdController.clear();
      _appIdController.clear();
      _mobileNumberController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account settings saved successfully')),
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

  Future<void> _deleteAccount(int index) async {
    try {
      final accountId = _accounts[index]['id'];
      if (accountId == null) return;

      await Supabase.instance.client
          .from('user_api_settings')
          .delete()
          .eq('id', accountId);

      setState(() {
        _accounts.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Trust me Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_accounts.isEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddAccountDialog,
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
                    'WhatsApp Business Configuration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your Meta API keys.',
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
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No API keys configured.',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddAccountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
                foregroundColor: Colors.white,
              ),
              child: const Text("Configure Now"),
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteAccount(index),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow("App ID", account['app_id'] ?? ''),
            _buildInfoRow("Phone ID", account['phone_id'] ?? ''),
            _buildInfoRow("Business ID", account['business_id'] ?? ''),
            _buildInfoRow("Mobile", account['mobile_number'] ?? 'Not provided'),
            _buildInfoRow(
              "Token",
              "••••••••${(account['token'] ?? '').toString().characters.takeLast(4)}",
            ),
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
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure WhatsApp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Access Token',
                  border: OutlineInputBorder(),
                  hintText: 'EAAG...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _appIdController,
                decoration: const InputDecoration(
                  labelText: 'Meta App ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneIdController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number ID (Meta)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _businessIdController,
                decoration: const InputDecoration(
                  labelText: 'Business Account ID (Meta)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileNumberController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
            onPressed: _addAccountToSupabase,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
