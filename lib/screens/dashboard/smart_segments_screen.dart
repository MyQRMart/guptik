import 'package:flutter/material.dart';

class SmartSegmentsScreen extends StatefulWidget {
  const SmartSegmentsScreen({super.key});

  @override
  State<SmartSegmentsScreen> createState() => _SmartSegmentsScreenState();
}

class _SmartSegmentsScreenState extends State<SmartSegmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Smart segments data - starts empty
  final List<Map<String, dynamic>> _segments = [];

  List<Map<String, dynamic>> get _filteredSegments {
    if (_searchController.text.isEmpty) return _segments;
    
    return _segments.where((segment) {
      return segment['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
             segment['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Smart Segments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSegmentDialog(),
            tooltip: 'Create New Segment',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF17A2B8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Total Segments', _segments.length.toString(), Icons.group),
                _buildStatCard('Active Segments', _segments.where((s) => s['is_active'] == true).length.toString(), Icons.check_circle),
                _buildStatCard('Total Contacts', _segments.fold(0, (sum, segment) => sum + (segment['contact_count'] as int)).toString(), Icons.people),
              ],
            ),
          ),
          
          // Search Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search smart segments...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF17A2B8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF17A2B8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
                ),
              ),
            ),
          ),
          
          // Segments List
          Expanded(
            child: _filteredSegments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_work_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'No smart segments yet'
                              : 'No segments found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Create smart segments to automatically group contacts based on criteria'
                              : 'Try adjusting your search criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateSegmentDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Segment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17A2B8),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSegments.length,
                    itemBuilder: (context, index) {
                      final segment = _filteredSegments[index];
                      return _buildSegmentCard(segment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(Map<String, dynamic> segment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group_work,
                    color: const Color(0xFF17A2B8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              segment['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17A2B8),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: segment['is_active'] == true ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              segment['is_active'] == true ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${segment['contact_count']} contacts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (segment['description']?.isNotEmpty == true) ...[
              Text(
                segment['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Criteria Display
            if (segment['criteria']?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Segment Criteria:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...((segment['criteria'] as List).map((criteria) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${criteria['field']} ${criteria['operator']} ${criteria['value']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${segment['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Last Updated: ${segment['last_refresh']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _refreshSegment(segment['id']),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewSegmentContacts(segment),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editSegment(segment),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteSegment(segment['id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSegmentDialog({Map<String, dynamic>? editingSegment}) {
    final nameController = TextEditingController(text: editingSegment?['name'] ?? '');
    final descriptionController = TextEditingController(text: editingSegment?['description'] ?? '');
    bool isActive = editingSegment?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editingSegment != null ? 'Edit Smart Segment' : 'Create New Smart Segment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Segment Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Active Segment'),
                  subtitle: const Text('Automatically update contacts based on criteria'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segment Criteria:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add criteria to automatically include contacts in this segment. This is a preview - full criteria builder coming soon!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  this.setState(() {
                    if (editingSegment != null) {
                      final index = _segments.indexWhere((segment) => segment['id'] == editingSegment['id']);
                      if (index != -1) {
                        _segments[index] = {
                          ..._segments[index],
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'is_active': isActive,
                          'last_refresh': DateTime.now().toString().split(' ')[0],
                        };
                      }
                    } else {
                      _segments.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'is_active': isActive,
                        'contact_count': 0,
                        'created_date': DateTime.now().toString().split(' ')[0],
                        'last_refresh': DateTime.now().toString().split(' ')[0],
                        'criteria': [], // Will be populated when criteria builder is implemented
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editingSegment != null 
                          ? 'Segment updated successfully' 
                          : 'Segment created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
              ),
              child: Text(editingSegment != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshSegment(String id) {
    setState(() {
      final index = _segments.indexWhere((segment) => segment['id'] == id);
      if (index != -1) {
        _segments[index]['last_refresh'] = DateTime.now().toString().split(' ')[0];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segment refreshed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewSegmentContacts(Map<String, dynamic> segment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View contacts in "${segment['name']}" - Coming soon!'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
    );
  }

  void _editSegment(Map<String, dynamic> segment) {
    _showCreateSegmentDialog(editingSegment: segment);
  }

  void _deleteSegment(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Smart Segment'),
        content: const Text('Are you sure you want to delete this smart segment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _segments.removeWhere((segment) => segment['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Segment deleted successfully'),
                  backgroundColor: Colors.green,
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