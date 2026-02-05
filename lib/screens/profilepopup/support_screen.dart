import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'General',
    'Technical Issue',
    'Billing',
    'Feature Request',
    'Integration',
    'API',
    'Account',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I connect my WhatsApp Business account?',
      'answer': 'Go to Settings > API Settings, enter your WhatsApp Business API credentials, and click Connect. Make sure your account is verified.',
    },
    {
      'question': 'Why are my messages not being delivered?',
      'answer': 'Check your account status, ensure templates are approved, verify recipient numbers are valid, and confirm you haven\'t exceeded daily limits.',
    },
    {
      'question': 'How do I create message templates?',
      'answer': 'Navigate to Content Library > Message Templates > Add New. Create your template and submit for WhatsApp approval.',
    },
    {
      'question': 'What are the messaging limits?',
      'answer': 'Limits depend on your tier (Tier 1: 1K, Tier 2: 10K, Tier 3: 100K messages/day). Quality rating affects your tier.',
    },
    {
      'question': 'How do I upgrade my subscription?',
      'answer': 'Go to Settings > Subscriptions, select your desired plan, and follow the payment process.',
    },
    {
      'question': 'Can I integrate with my CRM?',
      'answer': 'Yes! Visit Integrations to connect with popular CRMs like HubSpot, Salesforce, and others.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Support Center',
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
              'How can we help you?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get help with your WhatsApp Business automation. Check our FAQ or contact our support team.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Live Chat',
                    'Chat with our support team',
                    Icons.chat,
                    Colors.green,
                    () => _startLiveChat(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    'Call Support',
                    'Speak with an expert',
                    Icons.phone,
                    Colors.blue,
                    () => _callSupport(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Documentation',
                    'Browse our guides',
                    Icons.book,
                    Colors.purple,
                    () => _openDocumentation(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    'Video Tutorials',
                    'Watch how-to videos',
                    Icons.play_circle,
                    Colors.red,
                    () => _openTutorials(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Contact Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send us a Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Category and Priority
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: _priorities.map((priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17A2B8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Send Message',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // FAQ Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqItems.length,
                      itemBuilder: (context, index) {
                        return _buildFAQItem(_faqItems[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Contact Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildContactInfo(Icons.email, 'Email', 'support@metafly.com'),
                    const SizedBox(height: 12),
                    _buildContactInfo(Icons.phone, 'Phone', '+1 (555) 123-4567'),
                    const SizedBox(height: 12),
                    _buildContactInfo(Icons.access_time, 'Hours', 'Mon-Fri: 9AM-6PM EST'),
                    const SizedBox(height: 12),
                    _buildContactInfo(Icons.location_on, 'Address', '123 Business St, Suite 100, New York, NY 10001'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            faq['answer'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF17A2B8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting live chat...')),
    );
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening phone dialer...')),
    );
  }

  void _openDocumentation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening documentation...')),
    );
  }

  void _openTutorials() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening video tutorials...')),
    );
  }

  void _submitMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Clear form
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _selectedCategory = 'General';
      _selectedPriority = 'Medium';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support ticket created successfully')),
    );
  }
}