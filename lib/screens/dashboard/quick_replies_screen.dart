import 'package:flutter/material.dart';

class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key});

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  
  // Quick replies data - starts empty, will be populated from database
  final List<Map<String, dynamic>> _quickReplies = [];

  List<String> get _categories {
    final categories = _quickReplies.map((reply) => reply['category'] as String).toSet().toList();
    categories.sort();
    // Provide default categories even when no replies exist
    final defaultCategories = ['Greetings', 'Information', 'Support', 'Orders', 'Other'];
    final allCategories = <String>{...categories, ...defaultCategories}.toList();
    allCategories.sort();
    return ['All', ...allCategories];
  }

  List<Map<String, dynamic>> get _filteredReplies {
    var filtered = _quickReplies.where((reply) {
      final matchesSearch = _searchController.text.isEmpty ||
          reply['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          reply['content'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || reply['category'] == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    // Sort by usage count (most used first)
    filtered.sort((a, b) => (b['usage_count'] as int).compareTo(a['usage_count'] as int));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Quick Replies',
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
            onPressed: () => _showCreateQuickReplyDialog(),
            tooltip: 'Create New Quick Reply',
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
                _buildStatCard('Total Replies', _quickReplies.length.toString(), Icons.reply),
                _buildStatCard('Categories', (_categories.length - 1).toString(), Icons.category), // -1 to exclude 'All'
                _buildStatCard('Most Used', _quickReplies.isNotEmpty ? _quickReplies.reduce((a, b) => (a['usage_count'] as int) > (b['usage_count'] as int) ? a : b)['usage_count'].toString() : '0', Icons.trending_up),
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
                    hintText: 'Search quick replies...',
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
                
                // Category Filter
                Row(
                  children: [
                    const Text(
                      'Category: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quick Replies List
          Expanded(
            child: _filteredReplies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reply_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty && _selectedCategory == 'All' 
                              ? 'No quick replies created yet'
                              : 'No quick replies found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty && _selectedCategory == 'All'
                              ? 'Create your first quick reply to get started'
                              : 'Try adjusting your search or filter criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_searchController.text.isEmpty && _selectedCategory == 'All') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateQuickReplyDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Quick Reply'),
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
                    itemCount: _filteredReplies.length,
                    itemBuilder: (context, index) {
                      final reply = _filteredReplies[index];
                      return _buildQuickReplyCard(reply);
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

  Widget _buildQuickReplyCard(Map<String, dynamic> reply) {
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
                Expanded(
                  child: Text(
                    reply['title'],
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
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reply['category'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF17A2B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reply['content'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Used ${reply['usage_count']} times',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Created: ${reply['created_date']}',
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
                  onPressed: () => _copyReply(reply['content']),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editQuickReply(reply),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteQuickReply(reply['id']),
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

  void _copyReply(String content) {
    // In a real app, you'd use Clipboard.setData(ClipboardData(text: content))
    // For now, we'll show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick reply ready to copy: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}"'),
        backgroundColor: const Color(0xFF17A2B8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _editQuickReply(Map<String, dynamic> reply) {
    _showCreateQuickReplyDialog(editingReply: reply);
  }

  void _deleteQuickReply(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quick Reply'),
        content: const Text('Are you sure you want to delete this quick reply? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _quickReplies.removeWhere((reply) => reply['id'] == id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quick reply deleted successfully'),
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

  void _showCreateQuickReplyDialog({Map<String, dynamic>? editingReply}) {
    final titleController = TextEditingController(text: editingReply?['title'] ?? '');
    final contentController = TextEditingController(text: editingReply?['content'] ?? '');
    String selectedCategory = editingReply?['category'] ?? 'Greetings';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingReply != null ? 'Edit Quick Reply' : 'Create Quick Reply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                onChanged: (value) => selectedCategory = value!,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Greetings', 'Information', 'Support', 'Orders', 'Other']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
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
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  if (editingReply != null) {
                    // Update existing reply
                    final index = _quickReplies.indexWhere((reply) => reply['id'] == editingReply['id']);
                    if (index != -1) {
                      _quickReplies[index] = {
                        ..._quickReplies[index],
                        'title': titleController.text,
                        'content': contentController.text,
                        'category': selectedCategory,
                      };
                    }
                  } else {
                    // Create new reply
                    final newReply = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'content': contentController.text,
                      'category': selectedCategory,
                      'usage_count': 0,
                      'created_date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
                    };
                    _quickReplies.add(newReply);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editingReply != null 
                        ? 'Quick reply updated successfully' 
                        : 'Quick reply created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: Text(editingReply != null ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}