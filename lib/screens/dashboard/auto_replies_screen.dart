import 'package:flutter/material.dart';

class AutoRepliesScreen extends StatefulWidget {
  const AutoRepliesScreen({super.key});

  @override
  State<AutoRepliesScreen> createState() => _AutoRepliesScreenState();
}

class _AutoRepliesScreenState extends State<AutoRepliesScreen> {
  final List<Map<String, dynamic>> _autoReplies = [
    {
      'id': '1',
      'name': 'Business Hours Response',
      'trigger': 'After business hours',
      'keywords': ['any message'],
      'response': 'Thanks for contacting us! We\'re currently closed. Our business hours are Monday-Friday 9AM-6PM. We\'ll respond during our next business hours.',
      'status': 'Active',
      'matches': 234,
      'last_used': DateTime.now().subtract(const Duration(hours: 14)),
    },
    {
      'id': '2',
      'name': 'Greeting Response',
      'trigger': 'Keywords',
      'keywords': ['hello', 'hi', 'hey', 'good morning', 'good afternoon'],
      'response': 'Hello! 👋 Welcome to our WhatsApp Business. How can I help you today?',
      'status': 'Active',
      'matches': 567,
      'last_used': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    {
      'id': '3',
      'name': 'Pricing Inquiry',
      'trigger': 'Keywords',
      'keywords': ['price', 'cost', 'pricing', 'how much', 'rate'],
      'response': 'Thanks for your interest in our pricing! Here are our current plans:\n\n💼 Starter: \$29/month\n🚀 Pro: \$79/month\n🏢 Enterprise: \$199/month\n\nWould you like more details about any specific plan?',
      'status': 'Active',
      'matches': 89,
      'last_used': DateTime.now().subtract(const Duration(hours: 3)),
    },
    {
      'id': '4',
      'name': 'Support Request',
      'trigger': 'Keywords',
      'keywords': ['help', 'support', 'problem', 'issue', 'bug'],
      'response': 'I\'m sorry to hear you\'re having an issue. Our support team will help you right away!\n\nPlease describe your problem and we\'ll get back to you within 2 hours during business hours.',
      'status': 'Paused',
      'matches': 145,
      'last_used': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Paused'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Auto-Replies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createAutoReply,
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
              'Automated Responses',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up automatic replies to common customer inquiries and after-hours messages.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Rules',
                    _autoReplies.where((r) => r['status'] == 'Active').length.toString(),
                    Icons.play_arrow,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Matches',
                    _autoReplies.fold(0, (sum, r) => sum + (r['matches'] as int)).toString(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Filter and Create Button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filters.map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _createAutoReply,
                  icon: const Icon(Icons.add),
                  label: const Text('New Rule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A2B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Auto-Reply Rules
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredReplies.length,
              itemBuilder: (context, index) {
                return _buildAutoReplyCard(_filteredReplies[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredReplies {
    if (_selectedFilter == 'All') return _autoReplies;
    return _autoReplies.where((reply) => reply['status'] == _selectedFilter).toList();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReplyCard(Map<String, dynamic> reply) {
    final isActive = reply['status'] == 'Active';
    
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
                  child: Text(
                    reply['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    reply['status'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Trigger Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Trigger: ${reply['trigger']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  if (reply['keywords'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: (reply['keywords'] as List<String>).map((keyword) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          keyword,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Response Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply['response'],
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Stats
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${reply['matches']} matches',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Last used: ${_formatTime(reply['last_used'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                  onPressed: () => _editAutoReply(reply),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleAutoReply(reply),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(isActive ? 'Pause' : 'Activate'),
                ),
                TextButton.icon(
                  onPressed: () => _testAutoReply(reply),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Test'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteAutoReply(reply),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _createAutoReply() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Auto-Reply Rule'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Rule Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Keywords (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Auto-Reply Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
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
                const SnackBar(content: Text('Auto-reply rule created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editAutoReply(Map<String, dynamic> reply) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${reply['name']}')),
    );
  }

  void _toggleAutoReply(Map<String, dynamic> reply) {
    setState(() {
      reply['status'] = reply['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reply['name']} ${reply['status'].toLowerCase()}'),
      ),
    );
  }

  void _testAutoReply(Map<String, dynamic> reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Auto-Reply'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Testing: ${reply['name']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(reply['response']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test message sent to your number')),
              );
            },
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
  }

  void _deleteAutoReply(Map<String, dynamic> reply) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Auto-Reply'),
        content: Text('Are you sure you want to delete "${reply['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _autoReplies.remove(reply);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-reply rule deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}