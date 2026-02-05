import 'package:flutter/material.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Import / Export',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: TabController(length: 2, vsync: Scaffold.of(context)),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Import', icon: Icon(Icons.file_upload)),
            Tab(text: 'Export', icon: Icon(Icons.file_download)),
          ],
        ),
      ),
      body: TabBarView(
        controller: TabController(length: 2, vsync: Scaffold.of(context)),
        children: [
          _buildImportTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Import Statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF17A2B8).withValues(alpha: 0.1),
                  const Color(0xFF17A2B8).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 48,
                  color: const Color(0xFF17A2B8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Import Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import contacts from various sources to quickly build your contact database.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Import Options
          const Text(
            'Import Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildImportOption(
            icon: Icons.description,
            title: 'CSV File',
            description: 'Import contacts from a CSV file with name, phone, email columns',
            onTap: () => _showImportDialog('CSV'),
          ),
          
          const SizedBox(height: 12),
          
          _buildImportOption(
            icon: Icons.table_chart,
            title: 'Excel File',
            description: 'Import contacts from an Excel spreadsheet (.xlsx, .xls)',
            onTap: () => _showImportDialog('Excel'),
          ),
          
          const SizedBox(height: 12),
          
          _buildImportOption(
            icon: Icons.contact_phone,
            title: 'vCard File',
            description: 'Import contacts from vCard (.vcf) files',
            onTap: () => _showImportDialog('vCard'),
          ),
          
          const SizedBox(height: 12),
          
          _buildImportOption(
            icon: Icons.code,
            title: 'JSON File',
            description: 'Import contacts from JSON format files',
            onTap: () => _showImportDialog('JSON'),
          ),
          
          const SizedBox(height: 24),
          
          // Import History
          const Text(
            'Recent Imports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No import history yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your import history will appear here once you start importing contacts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF17A2B8).withValues(alpha: 0.1),
                  const Color(0xFF17A2B8).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_download,
                  size: 48,
                  color: const Color(0xFF17A2B8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Export Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17A2B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your contacts to various formats for backup or use in other applications.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export Options
          const Text(
            'Export Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildExportOption(
            icon: Icons.description,
            title: 'Export to CSV',
            description: 'Export all contacts to a CSV file',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('CSV'),
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            icon: Icons.table_chart,
            title: 'Export to Excel',
            description: 'Export contacts to an Excel spreadsheet',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('Excel'),
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            icon: Icons.contact_phone,
            title: 'Export to vCard',
            description: 'Export contacts to vCard format',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('vCard'),
          ),
          
          const SizedBox(height: 12),
          
          _buildExportOption(
            icon: Icons.code,
            title: 'Export to JSON',
            description: 'Export contacts in JSON format',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('JSON'),
          ),
          
          const SizedBox(height: 24),
          
          // Export Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color: const Color(0xFF17A2B8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Export Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Customize your export by selecting specific contact groups:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('All Contacts', true),
                _buildFilterOption('Tagged Contacts Only', false),
                _buildFilterOption('Favorites Only', false),
                _buildFilterOption('Specific Lists', false),
                _buildFilterOption('Smart Segments', false),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export History
          const Text(
            'Recent Exports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No export history yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your export history will appear here once you start exporting contacts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF17A2B8),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF17A2B8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required String contactCount,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF17A2B8),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contactCount,
              style: const TextStyle(
                color: Color(0xFF17A2B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.download,
          color: Color(0xFF17A2B8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return CheckboxListTile(
      title: Text(title),
      value: isSelected,
      onChanged: (value) {
        // Handle filter selection
      },
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF17A2B8),
    );
  }

  void _showImportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import from $format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_upload,
              size: 48,
              color: const Color(0xFF17A2B8),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a $format file to import contacts.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Required columns: Name, Phone Number\nOptional: Email, Tags, Notes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format import - Coming soon!'),
                  backgroundColor: const Color(0xFF17A2B8),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export to $format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download,
              size: 48,
              color: const Color(0xFF17A2B8),
            ),
            const SizedBox(height: 16),
            Text(
              'Export your contacts to $format format.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This will include all contact information including names, phone numbers, emails, and tags.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format export - Coming soon!'),
                  backgroundColor: const Color(0xFF17A2B8),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}