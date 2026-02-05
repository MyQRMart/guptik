import 'package:flutter/material.dart';

class AnalyticsFlowResponsesScreen extends StatefulWidget {
  const AnalyticsFlowResponsesScreen({super.key});

  @override
  State<AnalyticsFlowResponsesScreen> createState() => _AnalyticsFlowResponsesScreenState();
}

class _AnalyticsFlowResponsesScreenState extends State<AnalyticsFlowResponsesScreen> {
  String selectedPeriod = 'Last 7 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Flow Response Analytics'),
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
            // Period and Flow Selector
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
                      const Icon(Icons.account_tree, color: Color(0xFF17A2B8)),
                      const SizedBox(width: 12),
                      const Text(
                        'Flow Analytics Period:',
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
                      labelText: 'Select Flow',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    initialValue: 'All Flows',
                    items: const [
                      DropdownMenuItem(value: 'All Flows', child: Text('All Flows')),
                      DropdownMenuItem(value: 'Welcome Flow', child: Text('Welcome Flow')),
                      DropdownMenuItem(value: 'Support Flow', child: Text('Support Flow')),
                      DropdownMenuItem(value: 'Product Inquiry', child: Text('Product Inquiry Flow')),
                      DropdownMenuItem(value: 'Feedback Flow', child: Text('Feedback Flow')),
                    ],
                    onChanged: (value) {
                      // Handle flow selection
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Flow Overview
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Interactions',
                    '3,247',
                    '+18.5%',
                    Icons.touch_app,
                    Colors.blue,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Completion Rate',
                    '68.4%',
                    '+5.2%',
                    Icons.check_circle,
                    Colors.green,
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
                    'Drop-off Rate',
                    '31.6%',
                    '-3.1%',
                    Icons.exit_to_app,
                    Colors.orange,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Steps/Session',
                    '4.2',
                    '+0.8',
                    Icons.timeline,
                    Colors.purple,
                    true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Flow Performance Comparison
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
                    'Flow Performance Comparison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFlowPerformanceRow('Welcome Flow', 1247, 892, 71.5, 4.8),
                  _buildFlowPerformanceRow('Support Flow', 834, 523, 62.7, 3.2),
                  _buildFlowPerformanceRow('Product Inquiry', 678, 445, 65.6, 4.1),
                  _buildFlowPerformanceRow('Feedback Flow', 488, 362, 74.2, 5.1),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step-by-Step Analysis
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
                    'Welcome Flow - Step Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStepAnalysisRow('Step 1: Greeting', 1247, 1189, 95.3),
                  _buildStepAnalysisRow('Step 2: Menu Selection', 1189, 1034, 87.0),
                  _buildStepAnalysisRow('Step 3: Information Request', 1034, 923, 89.3),
                  _buildStepAnalysisRow('Step 4: Confirmation', 923, 892, 96.6),
                  _buildStepAnalysisRow('Step 5: Completion', 892, 892, 100.0),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Response Type Distribution
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
                    'Response Type Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildResponseTypeRow('Button Clicks', 1894, 58.4, Icons.touch_app),
                  _buildResponseTypeRow('Quick Replies', 967, 29.8, Icons.reply),
                  _buildResponseTypeRow('Text Input', 284, 8.7, Icons.keyboard),
                  _buildResponseTypeRow('List Selection', 102, 3.1, Icons.list),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Drop-off Points Analysis
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
                    'Common Drop-off Points',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropoffRow('Step 2: Menu Selection', 155, 13.0),
                  _buildDropoffRow('Step 3: Information Request', 111, 10.7),
                  _buildDropoffRow('Step 1: Greeting', 58, 4.7),
                  _buildDropoffRow('Step 4: Confirmation', 31, 3.4),
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

  Widget _buildFlowPerformanceRow(String flowName, int started, int completed, double rate, double avgSteps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              flowName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$completed/$started',
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
                color: rate > 70 ? Colors.green : rate > 60 ? Colors.orange : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              avgSteps.toStringAsFixed(1),
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

  Widget _buildStepAnalysisRow(String step, int entered, int completed, double rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$completed/$entered (${rate.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rate > 95 ? Colors.green : rate > 85 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              rate > 95 ? Colors.green : rate > 85 ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTypeRow(String type, int count, double percentage, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropoffRow(String step, int count, double percentage) {
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
              step,
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
}