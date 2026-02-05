import 'package:flutter/material.dart';

class BotsScreen extends StatefulWidget {
  const BotsScreen({super.key});

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> {
  final List<Map<String, dynamic>> _bots = [
    {
      'id': '1',
      'name': 'Customer Support Bot',
      'description': 'Handles common support inquiries and escalates complex issues',
      'status': 'Active',
      'conversations': 156,
      'resolution_rate': 78.5,
      'created_date': DateTime.now().subtract(const Duration(days: 15)),
      'last_interaction': DateTime.now().subtract(const Duration(minutes: 45)),
      'triggers': ['help', 'support', 'problem', 'issue'],
    },
    {
      'id': '2',
      'name': 'Product Catalog Bot',
      'description': 'Shows product information, prices, and availability',
      'status': 'Active',
      'conversations': 89,
      'resolution_rate': 92.1,
      'created_date': DateTime.now().subtract(const Duration(days: 8)),
      'last_interaction': DateTime.now().subtract(const Duration(hours: 2)),
      'triggers': ['catalog', 'products', 'price', 'buy'],
    },
    {
      'id': '3',
      'name': 'Order Tracking Bot',
      'description': 'Provides order status and tracking information',
      'status': 'Paused',
      'conversations': 234,
      'resolution_rate': 85.3,
      'created_date': DateTime.now().subtract(const Duration(days: 30)),
      'last_interaction': DateTime.now().subtract(const Duration(days: 3)),
      'triggers': ['order', 'tracking', 'delivery', 'status'],
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Paused', 'Training'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chatbots',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createBot,
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
              'AI-Powered Chatbots',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create intelligent chatbots to handle customer inquiries automatically and provide instant support.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Active Bots',
                            _bots.where((b) => b['status'] == 'Active').length.toString(),
                            Icons.smart_toy,
                            Colors.green,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Conversations',
                            _bots.fold(0, (sum, b) => sum + (b['conversations'] as int)).toString(),
                            Icons.chat,
                            Colors.blue,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Avg Resolution',
                            '${(_bots.fold(0.0, (sum, b) => sum + b['resolution_rate']) / _bots.length).toStringAsFixed(1)}%',
                            Icons.check_circle,
                            Colors.teal,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Total Bots',
                            _bots.length.toString(),
                            Icons.psychology,
                            Colors.purple,
                          )),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        'Active Bots',
                        _bots.where((b) => b['status'] == 'Active').length.toString(),
                        Icons.smart_toy,
                        Colors.green,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Conversations',
                        _bots.fold(0, (sum, b) => sum + (b['conversations'] as int)).toString(),
                        Icons.chat,
                        Colors.blue,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Avg Resolution',
                        '${(_bots.fold(0.0, (sum, b) => sum + b['resolution_rate']) / _bots.length).toStringAsFixed(1)}%',
                        Icons.check_circle,
                        Colors.teal,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Total Bots',
                        _bots.length.toString(),
                        Icons.psychology,
                        Colors.purple,
                      )),
                    ],
                  );
                }
              },
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
                  onPressed: _createBot,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Bot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A2B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Bot Templates (Quick Start)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bot Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBotTemplates(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Existing Bots
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredBots.length,
              itemBuilder: (context, index) {
                return _buildBotCard(_filteredBots[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredBots {
    if (_selectedFilter == 'All') return _bots;
    return _bots.where((bot) => bot['status'] == _selectedFilter).toList();
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
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotTemplates() {
    final templates = [
      {'name': 'Customer Support', 'icon': Icons.support_agent, 'color': Colors.blue},
      {'name': 'E-commerce', 'icon': Icons.shopping_cart, 'color': Colors.green},
      {'name': 'Lead Generation', 'icon': Icons.trending_up, 'color': Colors.orange},
      {'name': 'FAQ Assistant', 'icon': Icons.help, 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          child: InkWell(
            onTap: () => _useTemplate(template['name'] as String),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    template['icon'] as IconData,
                    color: template['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotCard(Map<String, dynamic> bot) {
    final isActive = bot['status'] == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bot['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bot['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bot['status']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    bot['status'],
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
                  child: _buildMetric(
                    'Conversations',
                    bot['conversations'].toString(),
                    Icons.chat,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Resolution Rate',
                    '${bot['resolution_rate']}%',
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Last Active',
                    _formatTime(bot['last_interaction']),
                    Icons.access_time,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Trigger Keywords
            if (bot['triggers'].isNotEmpty) ...[
              Text(
                'Trigger Keywords:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (bot['triggers'] as List<String>).map((trigger) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trigger,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _editBot(bot),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _testBot(bot),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Test'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleBot(bot),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(isActive ? 'Pause' : 'Activate'),
                ),
                TextButton.icon(
                  onPressed: () => _viewAnalytics(bot),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'training':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  void _createBot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bot builder...')),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creating bot from $templateName template')),
    );
  }

  void _editBot(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${bot['name']}')),
    );
  }

  void _testBot(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting test conversation with ${bot['name']}')),
    );
  }

  void _toggleBot(Map<String, dynamic> bot) {
    setState(() {
      bot['status'] = bot['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${bot['name']} ${bot['status'].toLowerCase()}'),
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing analytics for ${bot['name']}')),
    );
  }
}