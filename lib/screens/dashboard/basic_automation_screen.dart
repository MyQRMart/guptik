import 'package:flutter/material.dart';

class BasicAutomationScreen extends StatefulWidget {
  const BasicAutomationScreen({super.key});

  @override
  State<BasicAutomationScreen> createState() => _BasicAutomationScreenState();
}

class _BasicAutomationScreenState extends State<BasicAutomationScreen> {
  final List<Map<String, dynamic>> _automations = [
    {
      'id': '1',
      'name': 'Welcome New Customers',
      'description': 'Send welcome message when new customer joins',
      'trigger': 'New Contact Added',
      'status': 'Active',
      'last_triggered': DateTime.now().subtract(const Duration(hours: 2)),
      'executions': 45,
    },
    {
      'id': '2',
      'name': 'Order Confirmation',
      'description': 'Send confirmation when order is placed',
      'trigger': 'Webhook: Order Created',
      'status': 'Active',
      'last_triggered': DateTime.now().subtract(const Duration(minutes: 30)),
      'executions': 123,
    },
    {
      'id': '3',
      'name': 'Follow-up Reminder',
      'description': 'Send follow-up after 3 days of inactivity',
      'trigger': 'Time-based: 3 days',
      'status': 'Paused',
      'last_triggered': DateTime.now().subtract(const Duration(days: 1)),
      'executions': 67,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Basic Automation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createAutomation,
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
              'Automate Your WhatsApp Business',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create simple automation rules to respond to customer actions and events automatically.',
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
                    'Active Automations',
                    _automations.where((a) => a['status'] == 'Active').length.toString(),
                    Icons.play_arrow,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Executions',
                    _automations.fold(0, (sum, a) => sum + (a['executions'] as int)).toString(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Automation Templates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Popular Templates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _viewAllTemplates(),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTemplateGrid(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Existing Automations
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Your Automations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _createAutomation,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create New'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17A2B8),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _automations.length,
                      itemBuilder: (context, index) {
                        return _buildAutomationCard(_automations[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildTemplateGrid() {
    final templates = [
      {'name': 'Welcome Series', 'icon': Icons.waving_hand, 'color': Colors.blue},
      {'name': 'Order Updates', 'icon': Icons.shopping_cart, 'color': Colors.green},
      {'name': 'Appointment Reminders', 'icon': Icons.schedule, 'color': Colors.orange},
      {'name': 'Feedback Collection', 'icon': Icons.star, 'color': Colors.purple},
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

  Widget _buildAutomationCard(Map<String, dynamic> automation) {
    final isActive = automation['status'] == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        automation['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        automation['description'],
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
                    color: isActive ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    automation['status'],
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
            
            Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Trigger: ${automation['trigger']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
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
                      '${automation['executions']} executions',
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
                      'Last: ${_formatTime(automation['last_triggered'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _editAutomation(automation),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleAutomation(automation),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(isActive ? 'Pause' : 'Resume'),
                ),
                TextButton.icon(
                  onPressed: () => _viewAnalytics(automation),
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

  void _createAutomation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Automation'),
        content: const Text('Open automation builder to create a new workflow?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening automation builder...')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using template: $templateName')),
    );
  }

  void _viewAllTemplates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening template gallery...')),
    );
  }

  void _editAutomation(Map<String, dynamic> automation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${automation['name']}')),
    );
  }

  void _toggleAutomation(Map<String, dynamic> automation) {
    setState(() {
      automation['status'] = automation['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${automation['name']} ${automation['status'].toLowerCase()}'),
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> automation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing analytics for ${automation['name']}')),
    );
  }
}