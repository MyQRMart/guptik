import 'package:flutter/material.dart';

class FlowsScreen extends StatefulWidget {
  const FlowsScreen({super.key});

  @override
  State<FlowsScreen> createState() => _FlowsScreenState();
}

class _FlowsScreenState extends State<FlowsScreen> {
  final List<Map<String, dynamic>> _flows = [
    {
      'id': '1',
      'name': 'Customer Support Flow',
      'description': 'Handle common customer support inquiries',
      'status': 'Active',
      'triggers': ['support', 'help', 'issue'],
      'steps': 5,
      'created_at': DateTime.now().subtract(const Duration(days: 7)),
      'responses': 234,
    },
    {
      'id': '2',
      'name': 'Product Inquiry Flow',
      'description': 'Guide customers through product selection',
      'status': 'Draft',
      'triggers': ['product', 'buy', 'purchase'],
      'steps': 8,
      'created_at': DateTime.now().subtract(const Duration(days: 3)),
      'responses': 0,
    },
    {
      'id': '3',
      'name': 'Appointment Booking Flow',
      'description': 'Schedule appointments with customers',
      'status': 'Active',
      'triggers': ['appointment', 'booking', 'schedule'],
      'steps': 6,
      'created_at': DateTime.now().subtract(const Duration(days: 14)),
      'responses': 156,
    },
  ];

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flows', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewFlow,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF17A2B8).withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree, color: const Color(0xFF17A2B8), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Conversation Flows',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17A2B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Design automated conversation flows to engage with your customers effectively. Create interactive experiences that guide customers through support, sales, and booking processes.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search flows...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: ['All', 'Active', 'Draft', 'Paused'].map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFilter = value!),
                ),
              ],
            ),
          ),

          // Flows List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getFilteredFlows().length,
              itemBuilder: (context, index) {
                final flow = _getFilteredFlows()[index];
                return _buildFlowCard(flow);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFlow,
        backgroundColor: const Color(0xFF17A2B8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFlows() {
    List<Map<String, dynamic>> filtered = _flows;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((flow) {
        return flow['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               flow['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((flow) => flow['status'] == _selectedFilter).toList();
    }

    return filtered;
  }

  Widget _buildFlowCard(Map<String, dynamic> flow) {
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
                        flow['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flow['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flow['status']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    flow['status'],
                    style: TextStyle(
                      color: _getStatusColor(flow['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Flow Stats
            Row(
              children: [
                Icon(Icons.linear_scale, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${flow['steps']} steps',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${flow['responses']} responses',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Triggers
            if (flow['triggers'] != null && flow['triggers'].isNotEmpty) ...[
              Text(
                'Triggers: ${flow['triggers'].join(', ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editFlow(flow),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF17A2B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testFlow(flow),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17A2B8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _duplicateFlow(flow),
                  icon: Icon(Icons.copy, color: Colors.grey[600]),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  onPressed: () => _deleteFlow(flow),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Draft':
        return Colors.orange;
      case 'Paused':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _createNewFlow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Flow'),
        content: const Text('Flow builder is coming soon! This will open a visual flow designer where you can create automated conversation flows with drag-and-drop components.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${flow['name']}'),
        content: const Text('Flow editor is coming soon! This will open the visual flow designer where you can modify your conversation flow structure.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _testFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test ${flow['name']}'),
        content: const Text('Flow testing simulator is coming soon! This will allow you to test your flow responses and see how customers will experience the conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _duplicateFlow(Map<String, dynamic> flow) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${flow['name']} duplicated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flow'),
        content: Text('Are you sure you want to delete "${flow['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flow deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}