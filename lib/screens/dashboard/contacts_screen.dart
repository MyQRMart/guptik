import 'package:flutter/material.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  // Contacts data - starts empty, will be populated from database
  final List<Map<String, dynamic>> _contacts = [];

  List<String> get _filters => ['All', 'Recent', 'Favorites', 'Tagged', 'Untagged'];

  List<Map<String, dynamic>> get _filteredContacts {
    var filtered = _contacts.where((contact) {
      final matchesSearch = _searchController.text.isEmpty ||
          contact['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          contact['phone'].toString().contains(_searchController.text) ||
          (contact['email']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      
      final matchesFilter = _selectedFilter == 'All' || 
          (_selectedFilter == 'Tagged' && (contact['tags'] as List).isNotEmpty) ||
          (_selectedFilter == 'Untagged' && (contact['tags'] as List).isEmpty) ||
          (_selectedFilter == 'Favorites' && contact['is_favorite'] == true) ||
          (_selectedFilter == 'Recent' && contact['last_interaction'] != null);
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by name
    filtered.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Contacts',
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
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddContactDialog(),
            tooltip: 'Add New Contact',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _showImportDialog();
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'bulk_actions':
                  _showBulkActionsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Import Contacts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export Contacts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_actions',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Bulk Actions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                _buildStatCard('Total Contacts', _contacts.length.toString(), Icons.people),
                _buildStatCard('Tagged', _contacts.where((c) => (c['tags'] as List).isNotEmpty).length.toString(), Icons.local_offer),
                _buildStatCard('Favorites', _contacts.where((c) => c['is_favorite'] == true).length.toString(), Icons.favorite),
              ],
            ),
          ),
          
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search contacts by name, phone, or email...',
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
                const SizedBox(height: 12),
                
                // Filter Row
                Row(
                  children: [
                    const Text(
                      'Filter: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                selectedColor: const Color(0xFF17A2B8).withValues(alpha: 0.2),
                                checkmarkColor: const Color(0xFF17A2B8),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contacts List
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contacts_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty && _selectedFilter == 'All' 
                              ? 'No contacts yet'
                              : 'No contacts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty && _selectedFilter == 'All'
                              ? 'Add your first contact to get started'
                              : 'Try adjusting your search or filter criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_searchController.text.isEmpty && _selectedFilter == 'All') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddContactDialog(),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Contact'),
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
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactCard(contact);
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

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final tags = contact['tags'] as List<String>;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF17A2B8),
          child: Text(
            contact['name'].toString().substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (contact['is_favorite'] == true)
              const Icon(Icons.favorite, color: Colors.red, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact['phone'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            if (contact['email']?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                contact['email'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF17A2B8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editContact(contact);
                break;
              case 'delete':
                _deleteContact(contact['id']);
                break;
              case 'favorite':
                _toggleFavorite(contact['id']);
                break;
              case 'message':
                _sendMessage(contact);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'message',
              child: ListTile(
                leading: Icon(Icons.message),
                title: Text('Send Message'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'favorite',
              child: ListTile(
                leading: Icon(contact['is_favorite'] == true ? Icons.favorite : Icons.favorite_border),
                title: Text(contact['is_favorite'] == true ? 'Remove from Favorites' : 'Add to Favorites'),
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
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'tags': <String>[],
                    'is_favorite': false,
                    'created_date': DateTime.now().toString().split(' ')[0],
                    'last_interaction': null,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  void _editContact(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit contact functionality - Coming soon!'),
        backgroundColor: Color(0xFF17A2B8),
      ),
    );
  }

  void _deleteContact(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _contacts.removeWhere((contact) => contact['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact deleted successfully'),
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

  void _toggleFavorite(String id) {
    setState(() {
      final index = _contacts.indexWhere((contact) => contact['id'] == id);
      if (index != -1) {
        _contacts[index]['is_favorite'] = !(_contacts[index]['is_favorite'] ?? false);
      }
    });
  }

  void _sendMessage(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send message to ${contact['name']} - Coming soon!'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Contacts'),
        content: const Text('Choose how you want to import contacts:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import from CSV - Coming soon!'),
                  backgroundColor: Color(0xFF17A2B8),
                ),
              );
            },
            child: const Text('From CSV'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Contacts'),
        content: Text('Export ${_contacts.length} contacts to CSV file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export to CSV - Coming soon!'),
                  backgroundColor: Color(0xFF17A2B8),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: const Text('Select bulk action to perform:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bulk actions - Coming soon!'),
                  backgroundColor: Color(0xFF17A2B8),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}