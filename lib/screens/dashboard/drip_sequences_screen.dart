import 'package:flutter/material.dart';

class DripSequencesScreen extends StatefulWidget {
  const DripSequencesScreen({super.key});

  @override
  State<DripSequencesScreen> createState() => _DripSequencesScreenState();
}

class _DripSequencesScreenState extends State<DripSequencesScreen> {
  final List<Map<String, dynamic>> _sequences = [
    {
      'id': '1',
      'name': 'Welcome Series',
      'description': '5-message welcome sequence for new customers',
      'status': 'Active',
      'subscribers': 1234,
      'messages': [
        {'delay': 0, 'title': 'Welcome Message'},
        {'delay': 1, 'title': 'Getting Started Guide'},
        {'delay': 3, 'title': 'Feature Highlights'},
        {'delay': 7, 'title': 'Success Stories'},
        {'delay': 14, 'title': 'Feedback Request'},
      ],
      'open_rate': 78.5,
      'click_rate': 23.4,
      'created_date': DateTime.now().subtract(const Duration(days: 30)),
      'trigger': 'New subscriber',
    },
    {
      'id': '2',
      'name': 'Product Education',
      'description': '7-day educational series about product features',
      'status': 'Active',
      'subscribers': 867,
      'messages': [
        {'delay': 0, 'title': 'Introduction'},
        {'delay': 1, 'title': 'Basic Features'},
        {'delay': 2, 'title': 'Advanced Tips'},
        {'delay': 4, 'title': 'Best Practices'},
        {'delay': 6, 'title': 'Pro Tips'},
        {'delay': 8, 'title': 'Case Studies'},
        {'delay': 10, 'title': 'Next Steps'},
      ],
      'open_rate': 82.1,
      'click_rate': 31.7,
      'created_date': DateTime.now().subtract(const Duration(days: 15)),
      'trigger': 'Product signup',
    },
    {
      'id': '3',
      'name': 'Re-engagement Campaign',
      'description': 'Win back inactive customers with special offers',
      'status': 'Paused',
      'subscribers': 543,
      'messages': [
        {'delay': 0, 'title': 'We Miss You'},
        {'delay': 3, 'title': 'Special Offer'},
        {'delay': 7, 'title': 'Last Chance'},
      ],
      'open_rate': 45.3,
      'click_rate': 12.8,
      'created_date': DateTime.now().subtract(const Duration(days: 60)),
      'trigger': 'Inactive for 30 days',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Paused', 'Draft'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Drip Sequences',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createSequence,
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
              'Automated Message Sequences',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create timed message sequences to nurture leads, onboard customers, and drive engagement over time.',
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
                            'Active Sequences',
                            _sequences.where((s) => s['status'] == 'Active').length.toString(),
                            Icons.water_drop,
                            Colors.blue,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Total Subscribers',
                            _sequences.fold(0, (sum, s) => sum + (s['subscribers'] as int)).toString(),
                            Icons.people,
                            Colors.green,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                            'Avg Open Rate',
                            '${(_sequences.fold(0.0, (sum, s) => sum + s['open_rate']) / _sequences.length).toStringAsFixed(1)}%',
                            Icons.mark_email_read,
                            Colors.orange,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(
                            'Avg Click Rate',
                            '${(_sequences.fold(0.0, (sum, s) => sum + s['click_rate']) / _sequences.length).toStringAsFixed(1)}%',
                            Icons.touch_app,
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
                        'Active Sequences',
                        _sequences.where((s) => s['status'] == 'Active').length.toString(),
                        Icons.water_drop,
                        Colors.blue,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Total Subscribers',
                        _sequences.fold(0, (sum, s) => sum + (s['subscribers'] as int)).toString(),
                        Icons.people,
                        Colors.green,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Avg Open Rate',
                        '${(_sequences.fold(0.0, (sum, s) => sum + s['open_rate']) / _sequences.length).toStringAsFixed(1)}%',
                        Icons.mark_email_read,
                        Colors.orange,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard(
                        'Avg Click Rate',
                        '${(_sequences.fold(0.0, (sum, s) => sum + s['click_rate']) / _sequences.length).toStringAsFixed(1)}%',
                        Icons.touch_app,
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
                  onPressed: _createSequence,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Sequence'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A2B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Sequence Templates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sequence Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSequenceTemplates(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Existing Sequences
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredSequences.length,
              itemBuilder: (context, index) {
                return _buildSequenceCard(_filteredSequences[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSequences {
    if (_selectedFilter == 'All') return _sequences;
    return _sequences.where((seq) => seq['status'] == _selectedFilter).toList();
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
                fontSize: 20,
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

  Widget _buildSequenceTemplates() {
    final templates = [
      {'name': 'Welcome Series', 'icon': Icons.waving_hand, 'color': Colors.blue, 'messages': 5},
      {'name': 'Product Onboarding', 'icon': Icons.school, 'color': Colors.green, 'messages': 7},
      {'name': 'Sales Nurture', 'icon': Icons.trending_up, 'color': Colors.orange, 'messages': 6},
      {'name': 'Re-engagement', 'icon': Icons.refresh, 'color': Colors.purple, 'messages': 3},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        template['icon'] as IconData,
                        color: template['color'] as Color,
                        size: 24,
                      ),
                      const Spacer(),
                      Text(
                        '${template['messages']} msgs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSequenceCard(Map<String, dynamic> sequence) {
    final isActive = sequence['status'] == 'Active';
    final messages = sequence['messages'] as List<Map<String, dynamic>>;
    
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
                    Icons.water_drop,
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
                        sequence['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sequence['description'],
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
                    color: _getStatusColor(sequence['status']),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sequence['status'],
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
                    'Subscribers',
                    sequence['subscribers'].toString(),
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Messages',
                    messages.length.toString(),
                    Icons.message,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Open Rate',
                    '${sequence['open_rate']}%',
                    Icons.mark_email_read,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Click Rate',
                    '${sequence['click_rate']}%',
                    Icons.touch_app,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Message Timeline Preview
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
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Message Timeline:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...messages.take(3).map((msg) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Day ${msg['delay']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                      if (messages.length > 3)
                        Expanded(
                          child: Text(
                            '+${messages.length - 3} more',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Trigger Info
            Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Trigger: ${sequence['trigger']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  onPressed: () => _editSequence(sequence),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _duplicateSequence(sequence),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Duplicate'),
                ),
                TextButton.icon(
                  onPressed: () => _toggleSequence(sequence),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(isActive ? 'Pause' : 'Activate'),
                ),
                TextButton.icon(
                  onPressed: () => _viewAnalytics(sequence),
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
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _createSequence() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening sequence builder...')),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creating sequence from $templateName template')),
    );
  }

  void _editSequence(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing ${sequence['name']}')),
    );
  }

  void _duplicateSequence(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicating ${sequence['name']}')),
    );
  }

  void _toggleSequence(Map<String, dynamic> sequence) {
    setState(() {
      sequence['status'] = sequence['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sequence['name']} ${sequence['status'].toLowerCase()}'),
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing analytics for ${sequence['name']}')),
    );
  }
}