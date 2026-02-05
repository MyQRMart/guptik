import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/dashboard/create_template_screen.dart';
import 'package:guptik/services/dashboard/template_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageTemplatesScreen extends StatefulWidget {
  const MessageTemplatesScreen({super.key});

  @override
  State<MessageTemplatesScreen> createState() => _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState extends State<MessageTemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  
  List<Map<String, dynamic>> templates = [];
  List<Map<String, dynamic>> favoriteTemplates = [];
  List<Map<String, dynamic>> recentTemplates = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Feature 1: Search & Filter System
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  
  final List<String> _filterOptions = ['All', 'Marketing', 'Utility', 'Authentication', 'General', 'Greeting', 'Business', 'Support', 'Promotion', 'Reminder'];
  final List<String> _sortOptions = ['Name', 'Date Created', 'Usage Count', 'Category'];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _templateService.getTemplates(),
        _templateService.getFavoriteTemplates(),
        _templateService.getRecentTemplates(),
      ]);

      if (mounted) {
        setState(() {
          templates = results[0];
          favoriteTemplates = results[1];
          recentTemplates = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load templates: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeDuplicates() async {
    setState(() => _isLoading = true);
    
    try {
      await _templateService.removeDuplicateTemplates();
      await _loadTemplates(); // Reload after cleanup
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duplicate templates removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing duplicates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Message Templates', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Message Templates', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTemplates,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Templates', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTemplateVariablesHelp,
            tooltip: 'Template Variables Help',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _removeDuplicates,
            tooltip: 'Remove Duplicates',
          ),
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _showImportExportDialog,
            tooltip: 'Import/Export',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTemplateDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTemplates,
        child: templates.isEmpty ? _buildEmptyState() : _buildTemplatesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_snippet_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Templates Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first message template\nto get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showTemplateDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    List<Map<String, dynamic>> filteredTemplates = _getFilteredAndSortedTemplates();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature 1: Search and Filter Bar
          _buildSearchAndFilterBar(),
          const SizedBox(height: 16),
          
          // Feature 6: Quick Access Sections
          if (favoriteTemplates.isNotEmpty) ...[
            _buildSectionHeader('⭐ Favorites', favoriteTemplates.length),
            const SizedBox(height: 8),
            _buildTemplateList(favoriteTemplates.take(2).toList()),
            const SizedBox(height: 16),
          ],
          
          if (recentTemplates.isNotEmpty) ...[
            _buildSectionHeader('🕒 Recent', recentTemplates.length),
            const SizedBox(height: 8),
            _buildTemplateList(recentTemplates.take(3).toList()),
            const SizedBox(height: 16),
          ],
          
          // All Templates
          _buildSectionHeader('📝 All Templates', filteredTemplates.length),
          const SizedBox(height: 8),
          
          if (filteredTemplates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No templates match your search',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            _buildTemplateList(filteredTemplates),
        ],
      ),
    );
  }

  // Feature 1: Search & Filter System
  Widget _buildSearchAndFilterBar() {
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search templates...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 12),
        
        // Filter and Sort Row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _filterOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSort,
                decoration: InputDecoration(
                  labelText: 'Sort by',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Feature 6: Advanced Organization
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.teal[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.teal[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateList(List<Map<String, dynamic>> templateList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templateList.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(templateList[index], index);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, int index) {
    bool isFavorite = template['is_favorite'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTemplateIcon(template['category'] ?? 'General'),
                    color: _getCategoryColor(template['category'] ?? 'General'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template['name'] ?? 'Untitled Template',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(template),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showTemplateDialog(template: template, index: index);
                          break;
                        case 'duplicate':
                          _duplicateTemplate(template);
                          break;
                        case 'delete':
                          _deleteTemplate(index);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template['message'] ?? 'No content',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template['category'] ?? 'General').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template['category'] ?? 'General',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(template['category'] ?? 'General'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Used ${template['usage_count'] ?? 0} times',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filtering and Sorting Logic
  List<Map<String, dynamic>> _getFilteredAndSortedTemplates() {
    List<Map<String, dynamic>> filtered = templates;
    
    if (_selectedFilter != 'All') {
      filtered = filtered.where((template) => template['category'] == _selectedFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((template) {
        return template['name'].toLowerCase().contains(_searchQuery) ||
               template['message'].toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Name':
          return a['name'].compareTo(b['name']);
        case 'Usage Count':
          return (b['usageCount'] ?? 0).compareTo(a['usageCount'] ?? 0);
        case 'Category':
          return a['category'].compareTo(b['category']);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  void _toggleFavorite(Map<String, dynamic> template) async {
    final templateId = template['id'].toString();
    final isFavorite = template['is_favorite'] ?? false;
    
    await _templateService.toggleFavorite(templateId, isFavorite);
    _loadTemplates(); // Refresh the data
  }

  void _duplicateTemplate(Map<String, dynamic> template) async {
    Map<String, dynamic> duplicated = Map.from(template);
    duplicated.remove('id');
    duplicated.remove('created_at');
    duplicated.remove('updated_at');
    duplicated['name'] = '${template['name']} (Copy)';
    duplicated['usage_count'] = 0;
    duplicated['is_favorite'] = false;
    
    final result = await _templateService.createTemplate(duplicated);
    
    if (result != null) {
      _loadTemplates(); // Refresh the data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template['name']}" duplicated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to duplicate template'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useTemplate(Map<String, dynamic> template) async {
    final templateId = template['id'].toString();
    
    // Increment usage count and update last used
    await Future.wait([
      _templateService.incrementUsageCount(templateId),
      _templateService.updateLastUsed(templateId),
    ]);
    
    String processedMessage = _processTemplateVariables(template['message'] ?? '');
    Clipboard.setData(ClipboardData(text: processedMessage));
    
    // Refresh data to update usage count
    _loadTemplates();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${template['name']}" copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _processTemplateVariables(String message) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // Extract user information
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    
    final userEmail = user?.email ?? 'user@example.com';
    final userPhone = user?.userMetadata?['phone'] ?? user?.phone ?? '+1234567890';
    
    // Current date and time
    final now = DateTime.now();
    final currentDate = '${now.day}/${now.month}/${now.year}';
    final currentTime = TimeOfDay.now().format(context);
    
    return message
        .replaceAll('{{name}}', userName)
        .replaceAll('{{company}}', 'Meta Fly')
        .replaceAll('{{date}}', currentDate)
        .replaceAll('{{time}}', currentTime)
        .replaceAll('{{phone}}', userPhone)
        .replaceAll('{{email}}', userEmail)
        // Support numbered variables for WhatsApp Business API
        .replaceAll('{{1}}', userName)
        .replaceAll('{{2}}', 'Meta Fly')
        .replaceAll('{{3}}', currentDate);
  }

  void _showTemplateVariablesHelp() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    final userEmail = user?.email ?? 'user@example.com';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Template Variables'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use these variables in your templates:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildVariableRow('{{name}}', 'Your name', userName),
            _buildVariableRow('{{company}}', 'Company name', 'Meta Fly'),
            _buildVariableRow('{{date}}', 'Current date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            _buildVariableRow('{{time}}', 'Current time', TimeOfDay.now().format(context)),
            _buildVariableRow('{{phone}}', 'Your phone', user?.phone ?? '+1234567890'),
            _buildVariableRow('{{email}}', 'Your email', userEmail),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text('WhatsApp Business API Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _buildVariableRow('{{1}}', 'First parameter', userName),
            _buildVariableRow('{{2}}', 'Second parameter', 'Meta Fly'),
            _buildVariableRow('{{3}}', 'Third parameter', 'Current date'),
            const SizedBox(height: 12),
            const Text('Example:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('"Hello {{name}}, welcome to {{company}}! Today is {{date}}."'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableRow(String variable, String description, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              variable,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$description → $example',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showImportExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 Import/Export Templates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blue),
              title: const Text('Import Templates'),
              subtitle: const Text('Import from JSON file'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📥 Import feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('Export Templates'),
              subtitle: const Text('Export to JSON file'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📤 Export feature coming soon!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTemplateDialog({Map<String, dynamic>? template, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTemplateScreen(template: template),
      ),
    );
    
    if (result != null) {
      if (template != null) {
        // Update existing template
        final templateId = template['id'].toString();
        await _templateService.updateTemplate(templateId, result);
      } else {
        // Create new template
        await _templateService.createTemplate(result);
      }
      
      // Refresh the templates
      _loadTemplates();
    }
  }

  void _deleteTemplate(int index) async {
    Map<String, dynamic> template = templates[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final templateId = template['id'].toString();
      final success = await _templateService.deleteTemplate(templateId);
      
      if (success) {
        _loadTemplates(); // Refresh the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "${template['name']}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete template'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getTemplateIcon(String category) {
    switch (category) {
      case 'Marketing': return Icons.campaign;
      case 'Utility': return Icons.build;
      case 'Authentication': return Icons.security;
      case 'General': return Icons.text_snippet;
      case 'Greeting': return Icons.waving_hand;
      case 'Business': return Icons.business;
      case 'Support': return Icons.support_agent;
      case 'Promotion': return Icons.local_offer;
      case 'Reminder': return Icons.alarm;
      default: return Icons.text_snippet;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Marketing': return Colors.red;
      case 'Utility': return Colors.blue;
      case 'Authentication': return Colors.green;
      case 'General': return Colors.grey;
      case 'Greeting': return Colors.amber;
      case 'Business': return Colors.purple;
      case 'Support': return Colors.orange;
      case 'Promotion': return Colors.pink;
      case 'Reminder': return Colors.teal;
      default: return Colors.grey;
    }
  }
}