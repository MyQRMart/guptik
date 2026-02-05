import 'package:flutter/material.dart';

class ContactListsScreen extends StatefulWidget {
  const ContactListsScreen({super.key});

  @override
  State<ContactListsScreen> createState() => _ContactListsScreenState();
}

class _ContactListsScreenState extends State<ContactListsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Contact lists data - starts empty
  final List<Map<String, dynamic>> _contactLists = [];

  List<Map<String, dynamic>> get _filteredLists {
    if (_searchController.text.isEmpty) return _contactLists;
    
    return _contactLists.where((list) {
      return list['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
             list['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Contact Lists',
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
            onPressed: () => _showCreateListDialog(),
            tooltip: 'Create New List',
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
                _buildStatCard('Total Lists', _contactLists.length.toString(), Icons.list),
                _buildStatCard('Total Contacts', _contactLists.fold(0, (sum, list) => sum + (list['contact_count'] as int)).toString(), Icons.people),
                _buildStatCard('Active Lists', _contactLists.where((list) => list['is_active'] == true).length.toString(), Icons.check_circle),
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
                hintText: 'Search contact lists...',
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
          
          // Lists Grid/List
          Expanded(
            child: _filteredLists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty 
                              ? 'No contact lists yet'
                              : 'No lists found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Create your first contact list to organize contacts'
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
                            onPressed: () => _showCreateListDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First List'),
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
                    itemCount: _filteredLists.length,
                    itemBuilder: (context, index) {
                      final list = _filteredLists[index];
                      return _buildListCard(list);
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

  Widget _buildListCard(Map<String, dynamic> list) {
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
                    Icons.list,
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
                              list['name'],
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
                              color: list['is_active'] == true ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              list['is_active'] == true ? 'Active' : 'Inactive',
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
                        '${list['contact_count']} contacts',
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
            if (list['description']?.isNotEmpty == true) ...[
              Text(
                list['description'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${list['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated: ${list['updated_date']}',
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
                  onPressed: () => _viewListContacts(list),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editList(list),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteList(list['id']),
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

  void _showCreateListDialog({Map<String, dynamic>? editingList}) {
    final nameController = TextEditingController(text: editingList?['name'] ?? '');
    final descriptionController = TextEditingController(text: editingList?['description'] ?? '');
    bool isActive = editingList?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editingList != null ? 'Edit List' : 'Create New List'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'List Name *',
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
                  title: const Text('Active List'),
                  subtitle: const Text('Active lists can receive new contacts'),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value ?? true),
                  contentPadding: EdgeInsets.zero,
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
                    if (editingList != null) {
                      final index = _contactLists.indexWhere((list) => list['id'] == editingList['id']);
                      if (index != -1) {
                        _contactLists[index] = {
                          ..._contactLists[index],
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'is_active': isActive,
                          'updated_date': DateTime.now().toString().split(' ')[0],
                        };
                      }
                    } else {
                      _contactLists.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'is_active': isActive,
                        'contact_count': 0,
                        'created_date': DateTime.now().toString().split(' ')[0],
                        'updated_date': DateTime.now().toString().split(' ')[0],
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(editingList != null 
                          ? 'List updated successfully' 
                          : 'List created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
              ),
              child: Text(editingList != null ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewListContacts(Map<String, dynamic> list) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View contacts in "${list['name']}" - Coming soon!'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
    );
  }

  void _editList(Map<String, dynamic> list) {
    _showCreateListDialog(editingList: list);
  }

  void _deleteList(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _contactLists.removeWhere((list) => list['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('List deleted successfully'),
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