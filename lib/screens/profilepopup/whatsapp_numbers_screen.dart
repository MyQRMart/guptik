import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WhatsAppNumbersScreen extends StatefulWidget {
  const WhatsAppNumbersScreen({super.key});

  @override
  State<WhatsAppNumbersScreen> createState() => _WhatsAppNumbersScreenState();
}

class _WhatsAppNumbersScreenState extends State<WhatsAppNumbersScreen> {
  final List<Map<String, dynamic>> _numbers = [
    {
      'id': '1',
      'number': '+1 234 567 8900',
      'display_name': 'Main Business Line',
      'status': 'Active',
      'verified': true,
      'quality_rating': 'High',
      'messaging_limit': 'Tier 3',
      'last_used': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '2', 
      'number': '+1 234 567 8901',
      'display_name': 'Customer Support',
      'status': 'Active',
      'verified': true,
      'quality_rating': 'Medium',
      'messaging_limit': 'Tier 2',
      'last_used': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'WhatsApp Numbers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddNumberDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Manage WhatsApp Business Numbers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add, verify, and manage your WhatsApp Business phone numbers.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Numbers List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _numbers.length,
              itemBuilder: (context, index) {
                final number = _numbers[index];
                return _buildNumberCard(number);
              },
            ),
            
            const SizedBox(height: 30),
            
            // Add Number Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddNumberDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add New WhatsApp Number'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCard(Map<String, dynamic> number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        number['display_name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              number['number'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (number['verified'])
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(number['status']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    number['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetric('Quality Rating', number['quality_rating']),
                ),
                Expanded(
                  child: _buildMetric('Messaging Limit', number['messaging_limit']),
                ),
                Expanded(
                  child: _buildMetric('Last Used', _formatDate(number['last_used'])),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _copyNumber(number['number']),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: () => _editNumber(number),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _verifyNumber(number),
                  icon: const Icon(Icons.verified_user, size: 16),
                  label: Text(number['verified'] ? 'Re-verify' : 'Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Number copied to clipboard')),
    );
  }

  void _editNumber(Map<String, dynamic> number) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit WhatsApp Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: number['display_name']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Number updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _verifyNumber(Map<String, dynamic> number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify WhatsApp Number'),
        content: Text('Send verification code to ${number['number']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent')),
              );
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  void _showAddNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add WhatsApp Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixText: '+',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Number added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}