import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_template_group.dart';
import 'package:guptik/services/whatsapp/wa_template_service.dart';
import 'group_form_screen.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final SupabaseService _supabase = SupabaseService();
  late Future<List<WATemplateGroup>> _groupsFuture;

  final TextEditingController _searchController = TextEditingController();
  List<WATemplateGroup> _allGroups = [];
  List<WATemplateGroup> _filteredGroups = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _refreshList();
    _searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshList() {
    setState(() {
      _groupsFuture = _supabase.getWATemplateGroups().then((groups) {
        _allGroups = groups;
        _filterGroups();
        return _filteredGroups;
      });
    });
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredGroups = List.from(_allGroups);
    } else {
      _filteredGroups = _allGroups.where((group) {
        return group.groupName.toLowerCase().contains(query);
      }).toList();
    }
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _filterGroups();
  }

  Future<void> _deleteGroup(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase.deleteWATemplateGroup(id);
      _refreshList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
              )
            : const Text('Contact Groups'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _clearSearch();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              tooltip: 'Search',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const GroupFormScreen()),
          );
          if (result == true) _refreshList();
        },
        icon: const Icon(Icons.group_add),
        label: const Text('New Group'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<WATemplateGroup>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groups = _filteredGroups;

          if (groups.isEmpty) {
            if (_searchController.text.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No groups match "${_searchController.text}"',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Clear Search'),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first group',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_searchController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.teal[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Found ${groups.length} result${groups.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearSearch,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text(
                            group.groupContacts.length.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          group.groupName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${group.groupContacts.length} contacts',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupFormScreen(group: group),
                                ),
                              ).then((_) => _refreshList());
                            } else if (value == 'delete') {
                              _deleteGroup(group.id);
                            } else if (value == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupDetailScreen(group: group),
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('View'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
