import 'package:flutter/material.dart';

class ContactTagsScreen extends StatefulWidget {
  const ContactTagsScreen({super.key});

  @override
  State<ContactTagsScreen> createState() => _ContactTagsScreenState();
}

class _ContactTagsScreenState extends State<ContactTagsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Tags data - starts empty
  final List<Map<String, dynamic>> _tags = [];

  List<Map<String, dynamic>> get _filteredTags {
    if (_searchController.text.isEmpty) return _tags;
    
    return _tags.where((tag) {
      return tag['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
             tag['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Contact Tags',
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
            onPressed: () => _showCreateTagDialog(),
            tooltip: 'Create New Tag',
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
                _buildStatCard('Total Tags', _tags.length.toString(), Icons.local_offer),
                _buildStatCard('Tagged Contacts', _tags.fold(0, (sum, tag) => sum + (tag['contact_count'] as int)).toString(), Icons.people),
                _buildStatCard('Most Used', _tags.isNotEmpty ? _tags.reduce((a, b) => (a['contact_count'] as int) > (b['contact_count'] as int) ? a : b)['contact_count'].toString() : '0', Icons.trending_up),
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
                hintText: 'Search tags...',
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
          
          // Tags Grid
          Expanded(
            child: _filteredTags.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'No tags created yet'
                              : 'No tags found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Create tags to organize and categorize contacts'
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
                            onPressed: () => _showCreateTagDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Tag'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17A2B8),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredTags.length,
                    itemBuilder: (context, index) {
                      final tag = _filteredTags[index];
                      return _buildTagCard(tag);
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

  Widget _buildTagCard(Map<String, dynamic> tag) {
    final color = Color(tag['color'] ?? 0xFF17A2B8);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editTag(tag);
                        break;
                      case 'delete':
                        _deleteTag(tag['id']);
                        break;
                      case 'view_contacts':
                        _viewTaggedContacts(tag);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_contacts',
                      child: ListTile(
                        leading: Icon(Icons.people),
                        title: Text('View Contacts'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tag['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            if (tag['description']?.isNotEmpty == true) ...[
              Text(
                tag['description'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${tag['contact_count']} contacts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTagDialog({Map<String, dynamic>? editingTag}) {
    final nameController = TextEditingController(text: editingTag?['name'] ?? '');
    final descriptionController = TextEditingController(text: editingTag?['description'] ?? '');
    int selectedColor = editingTag?['color'] ?? 0xFF17A2B8;

    final colors = [
      0xFF17A2B8, // Default blue
      0xFFE74C3C, // Red
      0xFF2ECC71, // Green
      0xFFF39C12, // Orange
      0xFF9B59B6, // Purple
      0xFF1ABC9C, // Teal
      0xFF34495E, // Dark blue
      0xFFE67E22, // Orange
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editingTag != null ? 'Edit Tag' : 'Create New Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name *',
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
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Color:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
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
                    if (editingTag != null) {
                      final index = _tags.indexWhere((tag) => tag['id'] == editingTag['id']);
                      if (index != -1) {
                        _tags[index] = {
                          ..._tags[index],
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'color': selectedColor,
                          'updated_date': DateTime.now().toString().split(' ')[0],
                        };
                      }
                    } else {
                      _tags.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'color': selectedColor,
                        'contact_count': 0,
                        'created_date': DateTime.now().toString().split(' ')[0],
                        'updated_date': DateTime.now().toString().split(' ')[0],
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editingTag != null 
                          ? 'Tag updated successfully' 
                          : 'Tag created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
              ),
              child: Text(editingTag != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewTaggedContacts(Map<String, dynamic> tag) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View contacts with tag "${tag['name']}" - Coming soon!'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
    );
  }

  void _editTag(Map<String, dynamic> tag) {
    _showCreateTagDialog(editingTag: tag);
  }

  void _deleteTag(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: const Text('Are you sure you want to delete this tag? It will be removed from all contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tags.removeWhere((tag) => tag['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tag deleted successfully'),
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