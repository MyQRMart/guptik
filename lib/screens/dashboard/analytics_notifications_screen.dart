import 'package:flutter/material.dart';

class AnalyticsNotificationsScreen extends StatefulWidget {
  const AnalyticsNotificationsScreen({super.key});

  @override
  State<AnalyticsNotificationsScreen> createState() => _AnalyticsNotificationsScreenState();
}

class _AnalyticsNotificationsScreenState extends State<AnalyticsNotificationsScreen> {
  String _selectedPeriod = 'Last 7 days';
  final List<String> _periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 90 days', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notifications Analytics',
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
            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Time Period:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPeriod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _periods.map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriod = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Metrics Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Total Campaigns',
                  '45',
                  Icons.campaign,
                  Colors.blue,
                  '+12.5%'
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard(
                  'Sent Notifications',
                  '12,847',
                  Icons.send,
                  Colors.green,
                  '+8.3%'
                )),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildMetricCard(
                  'Delivery Rate',
                  '94.2%',
                  Icons.check_circle,
                  Colors.teal,
                  '+2.1%'
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard(
                  'Click Rate',
                  '23.7%',
                  Icons.touch_app,
                  Colors.orange,
                  '+5.8%'
                )),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Campaign Performance Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campaign Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPerformanceTable(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Notification Types Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationTypesChart(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  change,
                  style: TextStyle(
                    color: change.startsWith('+') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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

  Widget _buildPerformanceTable() {
    final campaigns = [
      {'name': 'Welcome Series', 'sent': 2847, 'delivered': 2695, 'clicked': 678, 'status': 'Active'},
      {'name': 'Product Updates', 'sent': 1923, 'delivered': 1834, 'clicked': 423, 'status': 'Active'},
      {'name': 'Support Follow-up', 'sent': 1456, 'delivered': 1398, 'clicked': 287, 'status': 'Paused'},
      {'name': 'Promotional Offers', 'sent': 3214, 'delivered': 3048, 'clicked': 892, 'status': 'Active'},
      {'name': 'Order Confirmations', 'sent': 2876, 'delivered': 2743, 'clicked': 534, 'status': 'Active'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Campaign', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Sent', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Delivered', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Clicked', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Click Rate', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
        rows: campaigns.map((campaign) {
          final clickRate = ((campaign['clicked'] as int) / (campaign['sent'] as int) * 100);
          return DataRow(
            cells: [
              DataCell(Text(campaign['name'] as String)),
              DataCell(Text((campaign['sent'] as int).toString())),
              DataCell(Text((campaign['delivered'] as int).toString())),
              DataCell(Text((campaign['clicked'] as int).toString())),
              DataCell(Text('${clickRate.toStringAsFixed(1)}%')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: campaign['status'] == 'Active' ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    campaign['status'] as String,
                    style: TextStyle(
                      color: campaign['status'] == 'Active' ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationTypesChart() {
    final types = [
      {'type': 'Marketing', 'count': 8456, 'percentage': 42.3, 'color': Colors.blue},
      {'type': 'Transactional', 'count': 5234, 'percentage': 26.2, 'color': Colors.green},
      {'type': 'Support', 'count': 3421, 'percentage': 17.1, 'color': Colors.orange},
      {'type': 'Reminders', 'count': 2890, 'percentage': 14.4, 'color': Colors.purple},
    ];

    return Column(
      children: types.map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: type['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type['type'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${type['count']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Text(
                '${(type['percentage'] as double).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}