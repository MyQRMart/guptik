import 'package:flutter/material.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _selectedPlan = 'pro';
  
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'starter',
      'name': 'Starter',
      'price': 29,
      'period': 'month',
      'features': [
        '1,000 messages/month',
        '1 WhatsApp number',
        'Basic templates',
        'Email support',
        'Basic analytics',
      ],
      'popular': false,
    },
    {
      'id': 'pro',
      'name': 'Professional',
      'price': 79,
      'period': 'month',
      'features': [
        '10,000 messages/month',
        '3 WhatsApp numbers',
        'Advanced templates',
        'Priority support',
        'Advanced analytics',
        'Automation flows',
        'API access',
      ],
      'popular': true,
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 199,
      'period': 'month',
      'features': [
        'Unlimited messages',
        'Unlimited numbers',
        'Custom templates',
        '24/7 support',
        'Custom analytics',
        'Advanced automation',
        'Full API access',
        'Custom integrations',
      ],
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
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
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the perfect plan for your business needs. Upgrade or downgrade anytime.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Current Plan Status
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan: Professional',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Next billing date: November 20, 2025',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Plans
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  // Mobile: Single column
                  return Column(
                    children: _plans.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPlanCard(plan),
                    )).toList(),
                  );
                } else {
                  // Desktop: Grid
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
                  );
                }
              },
            ),
            
            const SizedBox(height: 40),
            
            // Usage Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Usage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildUsageItem('Messages Sent', '7,543', '10,000', 0.75),
                    const SizedBox(height: 16),
                    _buildUsageItem('WhatsApp Numbers', '2', '3', 0.67),
                    const SizedBox(height: 16),
                    _buildUsageItem('Templates Used', '12', '∞', null),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan['id'];
    final isPopular = plan['popular'] as bool;
    
    return Stack(
      children: [
        Card(
          elevation: isSelected ? 8 : 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                ? Border.all(color: const Color(0xFF17A2B8), width: 2)
                : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${plan['price']}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17A2B8),
                        ),
                      ),
                      Text(
                        '/${plan['period']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...plan['features'].map<Widget>((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  const Spacer(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectPlan(plan['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected 
                          ? const Color(0xFF17A2B8)
                          : Colors.grey[200],
                        foregroundColor: isSelected 
                          ? Colors.white
                          : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isSelected ? 'Current Plan' : 'Select Plan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsageItem(String label, String used, String limit, double? progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$used${limit != '∞' ? ' / $limit' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8 ? Colors.red : const Color(0xFF17A2B8),
            ),
          ),
        ],
      ],
    );
  }

  void _selectPlan(String planId) {
    setState(() {
      _selectedPlan = planId;
    });
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Plan'),
        content: Text('Switch to ${_plans.firstWhere((p) => p['id'] == planId)['name']} plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan updated successfully')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}