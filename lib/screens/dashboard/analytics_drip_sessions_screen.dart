import 'package:flutter/material.dart';

class AnalyticsDripSessionsScreen extends StatefulWidget {
  const AnalyticsDripSessionsScreen({super.key});

  @override
  State<AnalyticsDripSessionsScreen> createState() => _AnalyticsDripSessionsScreenState();
}

class _AnalyticsDripSessionsScreenState extends State<AnalyticsDripSessionsScreen> {
  String selectedPeriod = 'Last 30 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Drip Campaign Analytics'),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            itemBuilder: (context) => periods.map((period) {
              return PopupMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh analytics
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF17A2B8)),
                      const SizedBox(width: 12),
                      const Text(
                        'Drip Campaign Analytics:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selectedPeriod,
                          style: const TextStyle(
                            color: Color(0xFF17A2B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Campaign',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    initialValue: 'All Campaigns',
                    items: const [
                      DropdownMenuItem(value: 'All Campaigns', child: Text('All Campaigns')),
                      DropdownMenuItem(value: 'Welcome Series', child: Text('Welcome Series')),
                      DropdownMenuItem(value: 'Product Education', child: Text('Product Education')),
                      DropdownMenuItem(value: 'Re-engagement', child: Text('Re-engagement Campaign')),
                      DropdownMenuItem(value: 'Customer Onboarding', child: Text('Customer Onboarding')),
                    ],
                    onChanged: (value) {
                      // Handle campaign selection
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Campaign Performance Overview
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Active Campaigns',
                    '8',
                    '+2',
                    Icons.play_circle_filled,
                    Colors.green,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total Subscribers',
                    '4,521',
                    '+187',
                    Icons.group,
                    Colors.blue,
                    true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Messages Sent',
                    '12,847',
                    '+32.4%',
                    Icons.send,
                    Colors.purple,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Completion Rate',
                    '64.7%',
                    '+8.2%',
                    Icons.check_circle,
                    Colors.orange,
                    true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Campaign Performance Comparison
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campaign Performance Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCampaignPerformanceRow('Welcome Series', 1247, 847, 67.9, 8.2),
                  _buildCampaignPerformanceRow('Product Education', 894, 623, 69.7, 6.8),
                  _buildCampaignPerformanceRow('Re-engagement', 567, 334, 58.9, 4.5),
                  _buildCampaignPerformanceRow('Customer Onboarding', 423, 298, 70.4, 7.1),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Message Sequence Performance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Series - Message Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMessageSequenceRow('Day 1: Welcome Message', 1247, 1189, 95.3, 23.4),
                  _buildMessageSequenceRow('Day 3: Product Tour', 1189, 967, 81.3, 18.7),
                  _buildMessageSequenceRow('Day 7: Tips & Tricks', 967, 823, 85.1, 15.2),
                  _buildMessageSequenceRow('Day 14: Feature Highlight', 823, 698, 84.8, 12.8),
                  _buildMessageSequenceRow('Day 30: Feedback Request', 698, 534, 76.5, 8.3),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Engagement Metrics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Engagement Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEngagementMetric('Open Rate', '84.2%', Colors.blue),
                      ),
                      Expanded(
                        child: _buildEngagementMetric('Click Rate', '18.7%', Colors.green),
                      ),
                      Expanded(
                        child: _buildEngagementMetric('Unsubscribe Rate', '2.1%', Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Drop-off Analysis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drop-off Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropoffRow('After Message 1', 58, 4.7),
                  _buildDropoffRow('After Message 2', 222, 18.7),
                  _buildDropoffRow('After Message 3', 144, 17.5),
                  _buildDropoffRow('After Message 4', 125, 17.9),
                  _buildDropoffRow('After Message 5', 164, 30.7),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Best Performing Messages
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Best Performing Messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTopMessageRow(1, 'Welcome & Getting Started', 95.3, 23.4),
                  _buildTopMessageRow(2, 'Feature Tips & Tricks', 85.1, 15.2),
                  _buildTopMessageRow(3, 'Product Highlight', 84.8, 12.8),
                  _buildTopMessageRow(4, 'Tutorial Video', 81.3, 18.7),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timing Analysis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Optimal Timing Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimingRow('Best Day', 'Tuesday', '89.4% open rate'),
                  _buildTimingRow('Best Time', '10:00 AM', '91.2% open rate'),
                  _buildTimingRow('Worst Day', 'Saturday', '67.8% open rate'),
                  _buildTimingRow('Worst Time', '11:00 PM', '52.3% open rate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, IconData icon, Color color, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignPerformanceRow(String campaign, int subscribers, int completed, double rate, double avgMessages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              campaign,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              subscribers.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: rate > 65 ? Colors.green : rate > 55 ? Colors.orange : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              avgMessages.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17A2B8),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSequenceRow(String message, int sent, int opened, double openRate, double clickRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$opened/$sent',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Text(
                '${openRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: openRate > 85 ? Colors.green : openRate > 75 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Text(
                'Click rate: ${clickRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String metric, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDropoffRow(String point, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMessageRow(int rank, String message, double openRate, double clickRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rank <= 3 ? const Color(0xFF17A2B8) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Open: ${openRate.toStringAsFixed(1)}%, Click: ${clickRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, String value, String metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17A2B8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              metric,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}