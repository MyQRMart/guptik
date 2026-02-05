import 'package:flutter/material.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  // Notifications data - starts empty
  final List<Map<String, dynamic>> _notifications = [];

  List<String> get _filters => ['All', 'Sent', 'Scheduled', 'Draft', 'Failed'];

  List<Map<String, dynamic>> get _filteredNotifications {
    var filtered = _notifications.where((notification) {
      final matchesSearch = _searchController.text.isEmpty ||
          notification['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          notification['message'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || notification['status'] == _selectedFilter.toLowerCase();
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by created date (newest first)
    filtered.sort((a, b) => DateTime.parse(b['created_date']).compareTo(DateTime.parse(a['created_date'])));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Manage Notifications',
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
            onPressed: () => _createNotification(),
            tooltip: 'Create New Notification',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'templates':
                  _manageTemplates();
                  break;
                case 'schedule':
                  _viewScheduled();
                  break;
                case 'analytics':
                  _viewAnalytics();
                  break;
                case 'settings':
                  _openSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'templates',
                child: ListTile(
                  leading: Icon(Icons.article),
                  title: Text('Templates'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule',
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Scheduled'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
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
                _buildStatCard('Total Sent', _notifications.where((n) => n['status'] == 'sent').length.toString(), Icons.send),
                _buildStatCard('Scheduled', _notifications.where((n) => n['status'] == 'scheduled').length.toString(), Icons.schedule),
                _buildStatCard('Failed', _notifications.where((n) => n['status'] == 'failed').length.toString(), Icons.error),
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
                    hintText: 'Search notifications...',
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
          
          // Notifications List
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty && _selectedFilter == 'All' 
                              ? 'No notifications yet'
                              : 'No notifications found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty && _selectedFilter == 'All'
                              ? 'Create your first notification to reach your contacts'
                              : 'Try adjusting your search or filter criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchController.text.isEmpty && _selectedFilter == 'All') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _createNotification(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Notification'),
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
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification);
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17A2B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${notification['recipient_count']} recipients',
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification['message'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${notification['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (notification['scheduled_date'] != null) ...[
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${notification['scheduled_date']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _duplicateNotification(notification),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Duplicate'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'sent') ...[
                  TextButton.icon(
                    onPressed: () => _viewAnalytics(notification),
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('Analytics'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF17A2B8),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () => _editNotification(notification),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF17A2B8),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteNotification(notification['id']),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'scheduled':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return const Color(0xFF17A2B8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'draft':
        return Icons.drafts;
      case 'failed':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  void _createNotification() {
    _showCreateNotificationDialog();
  }

  void _showCreateNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool scheduleDelivery = false;
    DateTime? scheduledDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Schedule Delivery'),
                  value: scheduleDelivery,
                  onChanged: (value) => setState(() => scheduleDelivery = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                if (scheduleDelivery) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    title: Text(scheduledDate != null 
                        ? 'Scheduled: ${scheduledDate!.toString().split(' ')[0]}'
                        : 'Select Date & Time'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selectedDate = await _selectDateTime();
                      if (selectedDate != null) {
                        setState(() {
                          scheduledDate = selectedDate;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
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
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  this.setState(() {
                    _notifications.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'message': messageController.text,
                      'status': scheduleDelivery ? 'scheduled' : 'draft',
                      'recipient_count': 0, // Will be calculated when sent
                      'created_date': DateTime.now().toString().split(' ')[0],
                      'scheduled_date': scheduledDate?.toString().split(' ')[0],
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(scheduleDelivery 
                          ? 'Notification scheduled successfully'
                          : 'Notification draft created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
              ),
              child: Text(scheduleDelivery ? 'Schedule' : 'Create Draft'),
            ),
          ],
        ),
      ),
    );
  }

  void _editNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${notification['title']}" - Coming soon!'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
    );
  }

  void _duplicateNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.add({
        ...notification,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': '${notification['title']} (Copy)',
        'status': 'draft',
        'created_date': DateTime.now().toString().split(' ')[0],
        'scheduled_date': null,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification duplicated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAnalytics([Map<String, dynamic>? notification]) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification analytics - Coming soon!'),
        backgroundColor: Color(0xFF17A2B8),
      ),
    );
  }

  void _deleteNotification(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.removeWhere((notification) => notification['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted successfully'),
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

  Future<DateTime?> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        return DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    }
    return null;
  }

  void _manageTemplates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification templates - Coming soon!'),
        backgroundColor: Color(0xFF17A2B8),
      ),
    );
  }

  void _viewScheduled() {
    setState(() {
      _selectedFilter = 'Scheduled';
    });
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/notification-settings');
  }
}