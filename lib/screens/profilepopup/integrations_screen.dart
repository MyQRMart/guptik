import 'package:flutter/material.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final List<Map<String, dynamic>> _integrations = [
    {
      'id': 'zapier',
      'name': 'Zapier',
      'description': 'Connect with 5000+ apps through Zapier automation',
      'icon': Icons.link,
      'color': Colors.orange,
      'connected': true,
      'category': 'Automation',
    },
    {
      'id': 'shopify',
      'name': 'Shopify',
      'description': 'Sync products, orders, and customer data',
      'icon': Icons.shopping_cart,
      'color': Colors.green,
      'connected': false,
      'category': 'E-commerce',
    },
    {
      'id': 'woocommerce',
      'name': 'WooCommerce',
      'description': 'WordPress e-commerce integration',
      'icon': Icons.store,
      'color': Colors.purple,
      'connected': false,
      'category': 'E-commerce',
    },
    {
      'id': 'hubspot',
      'name': 'HubSpot CRM',
      'description': 'Sync contacts and lead data automatically',
      'icon': Icons.people,
      'color': Colors.blue,
      'connected': true,
      'category': 'CRM',
    },
    {
      'id': 'salesforce',
      'name': 'Salesforce',
      'description': 'Enterprise CRM integration',
      'icon': Icons.cloud,
      'color': Colors.lightBlue,
      'connected': false,
      'category': 'CRM',
    },
    {
      'id': 'google_sheets',
      'name': 'Google Sheets',
      'description': 'Export data and sync contacts with spreadsheets',
      'icon': Icons.table_chart,
      'color': Colors.green,
      'connected': true,
      'category': 'Productivity',
    },
    {
      'id': 'mailchimp',
      'name': 'Mailchimp',
      'description': 'Sync email marketing lists and campaigns',
      'icon': Icons.email,
      'color': Colors.yellow,
      'connected': false,
      'category': 'Marketing',
    },
    {
      'id': 'stripe',
      'name': 'Stripe',
      'description': 'Payment processing and subscription management',
      'icon': Icons.payment,
      'color': Colors.indigo,
      'connected': false,
      'category': 'Payments',
    },
  ];

  String _selectedCategory = 'All';
  List<String> get _categories {
    final categories = _integrations.map((i) => i['category'] as String).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  List<Map<String, dynamic>> get _filteredIntegrations {
    if (_selectedCategory == 'All') return _integrations;
    return _integrations.where((i) => i['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Integrations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Connect Your Apps',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Integrate WhatsApp with your favorite tools and platforms to streamline your workflow.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Connected',
                    _integrations.where((i) => i['connected']).length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Available',
                    _integrations.length.toString(),
                    Icons.apps,
                    const Color(0xFF17A2B8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _selectedCategory == category,
                    label: Text(category),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF17A2B8),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category ? Colors.white : Colors.black87,
                    ),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Integrations Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 1 ? 3 : 2.5,
                  ),
                  itemCount: _filteredIntegrations.length,
                  itemBuilder: (context, index) {
                    return _buildIntegrationCard(_filteredIntegrations[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard(Map<String, dynamic> integration) {
    final isConnected = integration['connected'] as bool;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (integration['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    integration['icon'],
                    color: integration['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integration['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          integration['category'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConnected ? 'Connected' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isConnected ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              integration['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _toggleIntegration(integration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected 
                    ? Colors.red[100]
                    : const Color(0xFF17A2B8),
                  foregroundColor: isConnected 
                    ? Colors.red[700]
                    : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isConnected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleIntegration(Map<String, dynamic> integration) {
    final isConnected = integration['connected'] as bool;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isConnected ? 'Disconnect' : 'Connect'} ${integration['name']}'),
        content: Text(
          isConnected 
            ? 'Are you sure you want to disconnect ${integration['name']}? This will stop all data syncing.'
            : 'Connect ${integration['name']} to sync data and automate workflows.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                integration['connected'] = !isConnected;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${integration['name']} ${!isConnected ? 'connected' : 'disconnected'} successfully'
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.red : const Color(0xFF17A2B8),
            ),
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }
}