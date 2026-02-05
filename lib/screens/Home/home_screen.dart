import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';
import 'package:guptik/screens/dashboard/flows_screen.dart';
import 'package:guptik/screens/dashboard/message_templates_screen.dart';
import 'package:guptik/services/dashboard/whatsapp_business_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/screens/dashboard/quick_replies_screen.dart';
import 'package:guptik/screens/dashboard/contacts_screen.dart';
import 'package:guptik/screens/dashboard/contact_lists_screen.dart';
import 'package:guptik/screens/dashboard/contact_tags_screen.dart';
import 'package:guptik/screens/dashboard/smart_segments_screen.dart';
import 'package:guptik/screens/dashboard/import_export_screen.dart';
import 'package:guptik/screens/dashboard/notification_management_screen.dart';
import 'package:guptik/screens/dashboard/analytics_messaging_screen.dart';
import 'package:guptik/screens/dashboard/analytics_message_templates_screen.dart';
import 'package:guptik/screens/dashboard/analytics_flow_responses_screen.dart';
import 'package:guptik/screens/dashboard/analytics_bot_sessions_screen.dart';
import 'package:guptik/screens/dashboard/analytics_drip_sessions_screen.dart';
import 'package:guptik/screens/dashboard/analytics_notifications_screen.dart';
import 'package:guptik/screens/dashboard/basic_automation_screen.dart';
import 'package:guptik/screens/dashboard/auto_replies_screen.dart';
import 'package:guptik/screens/dashboard/bots_screen.dart';
import 'package:guptik/screens/dashboard/drip_sequences_screen.dart';
import 'package:guptik/services/dashboard/conversations_service.dart';
import 'package:guptik/screens/dashboard/business_settings_screen.dart';
import 'package:guptik/screens/whatsapp/main_whatsapp_screen.dart';


// Custom overflow-safe Row widget to prevent ALL overflow errors
class SafeRow extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      ),
    );
  }
}

// Responsive row that wraps content
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrapWhenSmall;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapWhenSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (wrapWhenSmall && constraints.maxWidth < 600) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        }
        
        return Row(
          crossAxisAlignment: crossAxisAlignment,

        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Live Data State
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;
  final int _maxRetries = 3;
  
  // WhatsApp Business Service
  final WhatsAppBusinessService _whatsappService = WhatsAppBusinessService();
  
  // Conversations Service
  final ConversationsService _conversationsService = ConversationsService();
  
  // Get current user from Supabase
  User? get _currentUser => Supabase.instance.client.auth.currentUser;
  
  final List<DashboardSection> _sections = [
    DashboardSection(icon: Icons.dashboard, title: 'Dashboard', isSelected: true),
    DashboardSection(
      icon: Icons.library_books, 
      title: 'Content Library',
      subSections: [
        SubSection(title: 'Message Templates', icon: Icons.message),
        SubSection(title: 'Flows', icon: Icons.account_tree),
        SubSection(title: 'Quick Replies', icon: Icons.reply),
      ],
    ),
    DashboardSection(
      icon: Icons.contacts, 
      title: 'Contacts',
      subSections: [
        SubSection(title: 'Contacts', icon: Icons.person),
        SubSection(title: 'Lists', icon: Icons.list),
        SubSection(title: 'Tags', icon: Icons.local_offer),
        SubSection(title: 'Smart Segments', icon: Icons.group),
        SubSection(title: 'Import / Export', icon: Icons.import_export),
      ],
    ),
    DashboardSection(
      icon: Icons.notifications, 
      title: 'Notifications',
      subSections: [
        SubSection(title: 'Notifications', icon: Icons.notifications),
        SubSection(title: 'Add New', icon: Icons.add),
      ],
    ),
    DashboardSection(
      icon: Icons.autorenew, 
      title: 'Automations',
      subSections: [
        SubSection(title: 'Basic', icon: Icons.play_arrow),
        SubSection(title: 'Auto-replies', icon: Icons.reply_all),
        SubSection(title: 'Bots', icon: Icons.smart_toy),
        SubSection(title: 'Drip Sequences', icon: Icons.water_drop),
      ],
    ),
    DashboardSection(
      icon: Icons.analytics, 
      title: 'Analytics & Reports',
      subSections: [
        SubSection(title: 'Messaging', icon: Icons.message),
        SubSection(title: 'Notifications', icon: Icons.notifications),
        SubSection(title: 'Message Templates', icon: Icons.description),
        SubSection(title: 'Flow Responses', icon: Icons.account_tree),
        SubSection(title: 'Bot Sessions', icon: Icons.smart_toy),
        SubSection(title: 'Drip Sessions', icon: Icons.water_drop),
      ],
    ),
    DashboardSection(icon: Icons.inbox, title: 'Inbox'),
  ];

  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadLiveData();
    // Set up periodic refresh every 30 seconds
    _startPeriodicRefresh();
  }

  void _loadLiveData() async {
    await _loadLiveDataWithRetry();
  }

  Future<void> _loadLiveDataWithRetry([int attemptCount = 0]) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _whatsappService.getLiveDashboardData();
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isNetworkError = e.toString().contains('network') || 
                               e.toString().contains('timeout') ||
                               e.toString().contains('connection');
        
        if (isNetworkError && attemptCount < _maxRetries) {
          // Exponential backoff: 2^attemptCount * 2 seconds
          final delaySeconds = (2 << attemptCount) * 2;
          
          setState(() {
            _error = 'Connection issue. Retrying in $delaySeconds seconds... (${attemptCount + 1}/$_maxRetries)';
            _isLoading = false;
          });
          
          Future.delayed(Duration(seconds: delaySeconds), () {
            if (mounted) _loadLiveDataWithRetry(attemptCount + 1);
          });
        } else {
          setState(() {
            _error = attemptCount >= _maxRetries 
              ? 'Failed to load data after $_maxRetries attempts. Please check your connection and try again.'
              : 'Failed to load live data: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _startPeriodicRefresh() {
    // Refresh data every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadLiveData();
        _startPeriodicRefresh();
      }
    });
  }

  void _showUpgradePlanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.orange),
              SizedBox(width: 8),
              Text('Upgrade Your Plan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unlock premium features to grow your business faster:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem('?', 'Unlimited message templates'),
              _buildFeatureItem('?', 'Advanced analytics & reports'),
              _buildFeatureItem('?', 'Unlimited contacts & segments'),
              _buildFeatureItem('?', 'AI-powered automation'),
              _buildFeatureItem('?', 'Multi-device access'),
              _buildFeatureItem('?', 'Priority customer support'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Special offer: Get 30% off your first 3 months!',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpgrade() {
    // Show upgrade options or navigate to payment screen
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Your Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlanOption(
                'Starter',
                '\$19/month',
                'Perfect for small businesses',
                ['5,000 messages/month', 'Basic analytics', 'Email support'],
                false,
              ),
              const SizedBox(height: 16),
              _buildPlanOption(
                'Professional',
                '\$49/month',
                'Best for growing businesses',
                ['25,000 messages/month', 'Advanced analytics', 'Priority support', 'AI automation'],
                true,
              ),
              const SizedBox(height: 16),
              _buildPlanOption(
                'Enterprise',
                '\$99/month',
                'For large organizations',
                ['Unlimited messages', 'Custom integrations', 'Dedicated manager', 'White-label options'],
                false,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanOption(String name, String price, String description, List<String> features, bool isRecommended) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? Colors.orange : Colors.grey[300]!,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isRecommended ? Colors.orange.withValues(alpha: 0.05) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isRecommended ? Colors.orange : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isRecommended ? Colors.orange : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: isRecommended ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectPlan(name, price);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isRecommended ? Colors.orange : Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Select $name',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(String planName, String price) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $planName plan ($price). Redirecting to payment...'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'PROCEED',
          textColor: Colors.white,
          onPressed: () {
            // Here you would navigate to payment screen or open web payment
            // Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen(plan: planName)));
          },
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width < 400 
                ? MediaQuery.of(context).size.width * 0.9 
                : 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF17A2B8),
                        child: Text(
                          _getInitials(_getUserDisplayName()),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getUserDisplayName(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getUserEmail(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Menu Items
                _buildProfileMenuItem(Icons.person_outline, 'My Account'),
                _buildProfileMenuItem(Icons.phone_android, 'WhatsApp Numbers'),
                _buildProfileMenuItem(Icons.subscriptions, 'My Subscriptions'),
                
                const Divider(height: 1),
                
                _buildProfileMenuItem(Icons.api, 'API Configuration'),
                _buildProfileMenuItem(Icons.webhook, 'Webhook Configuration'),
                _buildProfileMenuItem(Icons.extension, 'Integrations'),
                _buildProfileMenuItem(Icons.card_giftcard, 'Refer and Earn'),
                _buildProfileMenuItem(Icons.bug_report_outlined, 'Report Bug'),
                
                const Divider(height: 1),
                
                _buildProfileMenuItem(Icons.logout, 'Log Out', isDestructive: true),
                
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _handleProfileAction(title);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProfileAction(String action) {
    switch (action) {
      case 'My Account':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'WhatsApp Numbers':
        Navigator.pushNamed(context, '/whatsapp-numbers');
        break;
      case 'My Subscriptions':
        Navigator.pushNamed(context, '/subscriptions');
        break;
      case 'API Configuration':
        Navigator.pushNamed(context, '/api-settings');
        break;
      case 'Webhook Configuration':
        Navigator.pushNamed(context, '/webhook-config');
        break;
      case 'Integrations':
        Navigator.pushNamed(context, '/integrations');
        break;
      case 'Refer and Earn':
        Navigator.pushNamed(context, '/referral');
        break;
      case 'Report Bug':
        Navigator.pushNamed(context, '/support');
        break;
      case 'Log Out':
        _showSignOutConfirmation();
        break;
    }
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store context before async operation
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              navigator.pop();
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
    }
  }

  String _getUserDisplayName() {
    return _dashboardData?.businessProfile?.displayName ?? 
           _currentUser?.userMetadata?['full_name'] ?? 
           _currentUser?.email?.split('@')[0] ?? 
           'Business User';
  }

  String _getUserEmail() {
    return _currentUser?.email ?? 'user@example.com';
  }

  int _getTotalMenuItemCount() {
    int count = 0;
    for (var section in _sections) {
      count++; // Main section
      if (section.isExpanded && section.subSections != null) {
        count += section.subSections!.length; // Sub sections
      }
    }
    return count;
  }

  Widget _buildMenuItem(int flatIndex) {
    int currentIndex = 0;
    
    for (int sectionIndex = 0; sectionIndex < _sections.length; sectionIndex++) {
      final section = _sections[sectionIndex];
      
      // Main section item
      if (currentIndex == flatIndex) {
        return _buildMainMenuItem(section, sectionIndex);
      }
      currentIndex++;
      
      // Sub section items (if expanded)
      if (section.isExpanded && section.subSections != null) {
        for (int subIndex = 0; subIndex < section.subSections!.length; subIndex++) {
          if (currentIndex == flatIndex) {
            return _buildSubMenuItem(section.subSections![subIndex], sectionIndex, subIndex);
          }
          currentIndex++;
        }
      }
    }
    
    return const SizedBox.shrink(); // Fallback
  }

  Widget _buildMainMenuItem(DashboardSection section, int sectionIndex) {
    final isSelected = sectionIndex == _selectedIndex;
    final hasSubSections = section.subSections != null && section.subSections!.isNotEmpty;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(
          section.icon, 
          color: isSelected ? const Color(0xFF17A2B8) : Colors.white70, 
          size: 20
        ),
        title: Text(
          section.title, 
          style: TextStyle(
            color: isSelected ? const Color(0xFF17A2B8) : Colors.white70, 
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, 
            fontSize: 14
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasSubSections
            ? Icon(
                section.isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isSelected ? const Color(0xFF17A2B8) : Colors.white70,
                size: 20,
              )
            : null,
        selected: isSelected,
        selectedTileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            if (hasSubSections) {
              // For sections with subsections:
              // 1. Toggle expansion
              section.isExpanded = !section.isExpanded;
              // 2. Also select this section (so it stays highlighted)
              _selectedIndex = sectionIndex;
              for (int i = 0; i < _sections.length; i++) {
                _sections[i].isSelected = i == sectionIndex;
                // Clear sub-section selections when selecting main section
                if (_sections[i].subSections != null) {
                  for (var subSection in _sections[i].subSections!) {
                    subSection.isSelected = false;
                  }
                }
              }
            } else {
              // For sections without subsections: just select
              _selectedIndex = sectionIndex;
              for (int i = 0; i < _sections.length; i++) {
                _sections[i].isSelected = i == sectionIndex;
                // Clear sub-section selections
                if (_sections[i].subSections != null) {
                  for (var subSection in _sections[i].subSections!) {
                    subSection.isSelected = false;
                  }
                }
              }
            }
          });
          
          // Close drawer on mobile when item is tapped
          if (MediaQuery.of(context).size.width < 768) {
            Navigator.pop(context);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }

  Widget _buildSubMenuItem(SubSection subSection, int sectionIndex, int subIndex) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: ListTile(
        dense: true,
        leading: const SizedBox(width: 20), // Indent for sub items
        title: Row(
          children: [
            if (subSection.icon != null) ...[
              Icon(
                subSection.icon!, 
                color: subSection.isSelected ? const Color(0xFF17A2B8) : Colors.white60, 
                size: 16
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                subSection.title, 
                style: TextStyle(
                  color: subSection.isSelected ? const Color(0xFF17A2B8) : Colors.white60, 
                  fontWeight: subSection.isSelected ? FontWeight.w600 : FontWeight.normal, 
                  fontSize: 13
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: subSection.isSelected,
        selectedTileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        onTap: () {
          setState(() {
            // Clear all selections
            _selectedIndex = -1; // No main section selected
            for (var section in _sections) {
              section.isSelected = false;
              if (section.subSections != null) {
                for (var sub in section.subSections!) {
                  sub.isSelected = false;
                }
              }
            }
            // Select this sub section
            subSection.isSelected = true;
          });
          
          // Close drawer on mobile when item is tapped
          if (MediaQuery.of(context).size.width < 768) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For mobile screens, use drawer instead of sidebar
        if (constraints.maxWidth < 768) {
          return SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              drawer: _buildMobileDrawer(context),
              body: Column(
                children: [
                  // Top Bar for Mobile
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        // Hamburger menu for mobile
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.grey, size: 24),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCurrentTitle(), 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: InkWell(
                            onTap: _showUpgradePlanDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.grey, size: 20),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showProfileMenu,
                          borderRadius: BorderRadius.circular(16),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF17A2B8),
                            child: Text(
                              _getInitials(_getUserDisplayName()),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            
                  // Content Area for Mobile
                  Expanded(
                    child: _buildCurrentContent(),
                  ),  
                ],
              ),
            ),
          );
        }
        
        // For desktop/tablet, use sidebar layout (ORIGINAL CODE)
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Row(
              children: [
                // Sidebar (ORIGINAL CODE)
                Container(
                  width: 260,
                  color: const Color(0xFF17A2B8),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Meta Fly', 
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                                
                        // Business Account Info
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.orange,
                                    child: Icon(Icons.store, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dashboardData?.businessProfile?.displayName ?? 'Business Name', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dashboardData?.businessProfile?.phoneNumber ?? 'Phone Number', 
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                                
                        const SizedBox(height: 20),
                                
                        // Navigation Menu
                        Expanded(
                          child: ListView.builder(
                            itemCount: _getTotalMenuItemCount(),
                            itemBuilder: (context, index) {
                              return _buildMenuItem(index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
                // Main Content (ORIGINAL CODE)
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar - FIXED LINE 947 (ORIGINAL)
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getCurrentTitle(), 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: InkWell(
                                onTap: _showUpgradePlanDialog,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.notifications_outlined, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _showProfileMenu,
                              borderRadius: BorderRadius.circular(16),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF17A2B8),
                                child: Text(
                                  _getInitials(_getUserDisplayName()),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            
                      // Content Area  
                      Expanded(
                        child: _buildCurrentContent(),
                      ),  
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mobile Drawer Widget
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: Container(
        color: const Color(0xFF17A2B8),
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Meta Fly', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Business Account Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.store, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dashboardData?.businessProfile?.displayName ?? 'Business Name', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dashboardData?.businessProfile?.phoneNumber ?? 'Phone Number', 
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Navigation Menu
            Expanded(
              child: ListView.builder(
                itemCount: _getTotalMenuItemCount(),
                itemBuilder: (context, index) {
                  return _buildMenuItem(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTitle() {
    // Check if any sub-section is selected
    for (var section in _sections) {
      if (section.subSections != null) {
        for (var subSection in section.subSections!) {
          if (subSection.isSelected) {
            return subSection.title;
          }
        }
      }
    }
    
    // Return main section title
    if (_selectedIndex >= 0 && _selectedIndex < _sections.length) {
      // Show "Conversations" when Inbox is selected (matching the image)
      if (_sections[_selectedIndex].title == 'Inbox') {
        return 'Conversations';
      }
      return _sections[_selectedIndex].title;
    }
    
    return 'Dashboard'; // Default
  }

  Widget _buildCurrentContent() {
    // Check if any sub-section is selected
    for (var section in _sections) {
      if (section.subSections != null) {
        for (var subSection in section.subSections!) {
          if (subSection.isSelected) {
            return _buildSubSectionContent(subSection.title, section.title);
          }
        }
      }
    }
    
    // Check main section selection
    if (_selectedIndex == 0) {
      return _buildDashboardContent();
    } else if (_selectedIndex > 0 && _selectedIndex < _sections.length) {
      return _buildOtherContent();
    }
    
    // Default to dashboard
    return _buildDashboardContent();
  }

  Widget _buildSubSectionContent(String subSectionTitle, [String? parentSection]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSubSectionIcon(subSectionTitle), 
            size: 64, 
            color: const Color(0xFF17A2B8)
          ),
          const SizedBox(height: 16),
          Text(
            subSectionTitle, 
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w600, 
              color: Color(0xFF17A2B8)
            )
          ),
          const SizedBox(height: 8),
          Text(
            _getSubSectionDescription(subSectionTitle),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (subSectionTitle == 'Message Templates') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessageTemplatesScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Flows') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlowsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Quick Replies') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuickRepliesScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Contacts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Lists') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactListsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Tags') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactTagsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Smart Segments') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartSegmentsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Import / Export') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportExportScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Notifications') {
                if (parentSection == 'Analytics & Reports') {
                  // Analytics & Reports - Notifications
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsNotificationsScreen(),
                    ),
                  );
                } else {
                  // Regular Notifications management
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationManagementScreen(),
                    ),
                  );
                }
              } else if (subSectionTitle == 'Add New') {
                // This is for creating a new notification
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationManagementScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Messaging') {
                // Analytics & Reports - Messaging
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsMessagingScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Message Templates') {
                // Analytics & Reports - Message Templates (different from Content Library)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsMessageTemplatesScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Flow Responses') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsFlowResponsesScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Bot Sessions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsBotSessionsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Drip Sessions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsDripSessionsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Basic') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BasicAutomationScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Auto-replies') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AutoRepliesScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Bots') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BotsScreen(),
                  ),
                );
              } else if (subSectionTitle == 'Drip Sequences') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DripSequencesScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $subSectionTitle...'),
                    backgroundColor: const Color(0xFF17A2B8),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Manage $subSectionTitle'),
          ),
        ],
      ),
    );
  }

  IconData _getSubSectionIcon(String subSectionTitle) {
    switch (subSectionTitle) {
      case 'Message Templates':
        return Icons.message;
      case 'Flows':
        return Icons.account_tree;
      case 'Quick Replies':
        return Icons.reply;
      case 'Contacts':
        return Icons.person;
      case 'Lists':
        return Icons.list;
      case 'Tags':
        return Icons.local_offer;
      case 'Smart Segments':
        return Icons.group;
      case 'Import / Export':
        return Icons.import_export;
      case 'Notifications':
        return Icons.notifications;
      case 'Add New':
        return Icons.add;
      case 'Basic':
        return Icons.play_arrow;
      case 'Auto-replies':
        return Icons.reply_all;
      case 'Bots':
        return Icons.smart_toy;
      case 'Drip Sequences':
        return Icons.water_drop;
      case 'Messaging':
        return Icons.message;
      case 'Flow Responses':
        return Icons.account_tree;
      case 'Bot Sessions':
        return Icons.smart_toy;
      case 'Drip Sessions':
        return Icons.water_drop;
      default:
        return Icons.description;
    }
  }

  String _getSubSectionDescription(String subSectionTitle) {
    switch (subSectionTitle) {
      case 'Message Templates':
        return 'Create and manage reusable message templates\nfor your WhatsApp Business communications.';
      case 'Flows':
        return 'Design automated conversation flows\nto engage with your customers effectively.';
      case 'Quick Replies':
        return 'Set up quick reply options to respond\nto common customer inquiries instantly.';
      case 'Contacts':
        return 'Manage your customer contact database and profiles.';
      case 'Lists':
        return 'Organize contacts into targeted lists for better communication.';
      case 'Tags':
        return 'Create and assign tags to categorize your contacts efficiently.';
      case 'Smart Segments':
        return 'Build dynamic customer segments based on behavior and attributes.';
      case 'Import / Export':
        return 'Import contacts from external sources or export your contact data.';
      case 'Notifications':
        return 'View and manage all your notification campaigns and alerts.';
      case 'Add New':
        return 'Create new notification campaigns to engage with your customers.';
      case 'Basic':
        return 'Set up basic automation rules for common business workflows.';
      case 'Auto-replies':
        return 'Configure automatic responses for incoming messages and inquiries.';
      case 'Bots':
        return 'Create intelligent chatbots to handle customer interactions automatically.';
      case 'Drip Sequences':
        return 'Design automated message sequences to nurture customer relationships.';
      case 'Messaging':
        return 'Analyze your messaging performance, delivery rates, and engagement metrics.';
      case 'Flow Responses':
        return 'Track and analyze how customers interact with your automated flows.';
      case 'Bot Sessions':
        return 'Monitor chatbot conversations and performance analytics.';
      case 'Drip Sessions':
        return 'Review drip campaign performance and customer engagement data.';
      default:
        return 'Content management feature';
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Onboard Section FIRST
          const Text(
            'Welcome Onboard! ??', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text('New here? Get started by following the steps below.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          
          const SizedBox(height: 32),

          // Onboarding Steps - FIXED: Responsive layout
          _buildResponsiveOnboardingSteps(),

          // ADD SOCIAL MEDIA ICONS AFTER ALL ONBOARDING STEPS
          const SizedBox(height: 32),
          
          // Social Media Icons Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                const Text(
                  'Connect with us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'social media platforms ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // WhatsApp Icon
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Whatsapp(),
                          ),
                       
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: const Column(
                          children: [
                           FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.green,
                             size: 30,
                                ),
                            SizedBox(height: 8),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Facebook Icon
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Facebook...'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: const Column(
                          children: [
                            FaIcon(
                                 FontAwesomeIcons.facebook,
                                    color: Colors.blue,
                                     size: 30,
                                     ),
                            SizedBox(height: 8),
                            Text(
                              'Facebook',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Instagram Icon
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Instagram...'),
                            backgroundColor: Colors.pink,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink[100]!),
                        ),
                        child: const Column(
                          children: [
                            FaIcon(
                                 FontAwesomeIcons.instagram,
                                    color: Colors.pink,
                                     size: 30,
                                     ),
                            SizedBox(height: 8),
                            Text(
                              'Instagram',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.pink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Business Account Status (LIVE DATA)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? _buildErrorDisplay()
                : _buildStatusGrid(),
          ),

          const SizedBox(height: 40),

          // WhatsApp API Usage Header
          _buildUsageHeader(),
          
          const SizedBox(height: 20),

          // API Usage Cards - FIXED: Simplified layout
          _buildUsageCards(),

          const SizedBox(height: 24),

          // Bottom Row with Plan, Contacts, and Quick Links - FIXED
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildResponsiveOnboardingSteps() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildOnboardingStep(1, 'Connect WhatsApp API', 'Configure API credentials.', Icons.key, true),
              const SizedBox(height: 16),
              _buildOnboardingStep(2, 'Verify Phone Number', 'Add and verify phone number.', Icons.phone, false),
              const SizedBox(height: 16),
              _buildOnboardingStep(3, 'Setup Business Profile', 'Complete business info.', Icons.business, false),
              const SizedBox(height: 16),
              _buildOnboardingStep(4, 'Create Message Template', 'Design your first template.', Icons.message, true),
            ],
          );
        } else if (constraints.maxWidth < 800) {
          return Column(
            children: [
              ResponsiveRow(
                children: [
                  Expanded(child: _buildOnboardingStep(1, 'Connect WhatsApp API', 'Configure API credentials.', Icons.key, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOnboardingStep(2, 'Verify Phone Number', 'Add and verify phone number.', Icons.phone, false)),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveRow(
                children: [
                  Expanded(child: _buildOnboardingStep(3, 'Setup Business Profile', 'Complete business info.', Icons.business, false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOnboardingStep(4, 'Create Message Template', 'Design your first template.', Icons.message, true)),
                ],
              ),
            ],
          );
        } else {
          return ResponsiveRow(
            children: [
              Expanded(child: _buildOnboardingStep(1, 'Connect WhatsApp API', 'Configure your WhatsApp Business API credentials and account settings.', Icons.key, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildOnboardingStep(2, 'Verify Phone Number', 'Add and verify your business phone number for message delivery.', Icons.phone, false)),
              const SizedBox(width: 16),
              Expanded(child: _buildOnboardingStep(3, 'Setup Business Profile', 'Complete your business information and professional profile.', Icons.business, false)),
              const SizedBox(width: 16),
              Expanded(child: _buildOnboardingStep(4, 'Create Message Template', 'Design and submit your first message template for approval.', Icons.message, true)),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatusGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              ResponsiveRow(
                children: [
                  Expanded(child: _buildStatusItem('Phone Number', _dashboardData?.phoneNumberStatus?.displayPhoneNumber ?? 'Loading...')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusItem('Display Name', _dashboardData?.businessProfile?.displayName ?? 'Loading...')),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveRow(
                children: [
                  Expanded(child: _buildStatusItem('Messaging Limit', '1k/24hr')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusItem('Quality Rating', _dashboardData?.qualityRating?.rating ?? 'Loading...', isGreen: true)),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveRow(
                children: [
                  Expanded(child: _buildStatusItem('MM Lite API', '')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusItem('Phone Status', _getConnectionStatus(), isGreen: _getConnectionStatus() == 'CONNECTED')),
                ],
              ),
            ],
          );
        } else {
          return ResponsiveRow(
            children: [
              Expanded(child: _buildStatusItem('Phone Number', _dashboardData?.phoneNumberStatus?.displayPhoneNumber ?? 'Loading...')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusItem('Display Name', _dashboardData?.businessProfile?.displayName ?? 'Loading...')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusItem('Messaging Limit', '1k/24hr')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusItem('MM Lite API', '')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusItem('Quality Rating', _dashboardData?.qualityRating?.rating ?? 'Loading...', isGreen: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusItem('Phone Status', _getConnectionStatus(), isGreen: _getConnectionStatus() == 'CONNECTED')),
            ],
          );
        }
      },
    );
  }

  Widget _buildUsageHeader() {
    return Row(
      children: [
        const Icon(Icons.code, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'WhatsApp API Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.info_outline, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        if (_isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Live',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey, size: 18),
                onPressed: _loadLiveData,
                tooltip: 'Refresh Data',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildUsageCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildMessageDeliveryCard(),
              const SizedBox(height: 16),
              _buildMessagesSummaryCard(),
            ],
          );
        } else {
          return ResponsiveRow(
            children: [
              Expanded(
                flex: 2,
                child: _buildMessageDeliveryCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMessagesSummaryCard(),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMessageDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Message Delivery Stats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.info_outline, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildStatColumn(_dashboardData?.messageAnalytics?.marketing.toString() ?? '0', 'Marketing'),
                    const SizedBox(height: 16),
                    _buildStatColumn(_dashboardData?.messageAnalytics?.authentication.toString() ?? '0', 'Auth'),
                    const SizedBox(height: 16),
                    _buildStatColumn(_dashboardData?.messageAnalytics?.service.toString() ?? '0', 'Service'),
                    const SizedBox(height: 16),
                    _buildStatColumn(_dashboardData?.messageAnalytics?.utility.toString() ?? '0', 'Utility'),
                    const SizedBox(height: 16),
                    _buildStatColumn(_dashboardData?.messageAnalytics?.total.toString() ?? '0', 'Total'),
                  ],
                );
              } else {
                return ResponsiveRow(
                  children: [
                    Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.marketing.toString() ?? '0', 'Marketing')),
                    Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.authentication.toString() ?? '0', 'Auth')),
                    Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.service.toString() ?? '0', 'Service')),
                    Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.utility.toString() ?? '0', 'Utility')),
                    Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.total.toString() ?? '0', 'Total')),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.info_outline, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          ResponsiveRow(
            children: [
              Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.sent.toString() ?? '0', 'Sent')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatColumn(_dashboardData?.messageAnalytics?.delivered.toString() ?? '0', 'Delivered')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _buildPlanCard(),
              const SizedBox(height: 16),
              _buildContactsCard(),
              const SizedBox(height: 16),
              _buildQuickLinksCard(),
            ],
          );
        } else {
          return ResponsiveRow(
            children: [
              Expanded(child: _buildPlanCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildContactsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildQuickLinksCard()),
            ],
          );
        }
      },
    );
  }

  Widget _buildPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Meta Fly Plan: Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanItem('Message templates', '0 / 250'),
          _buildPlanItem('Contacts', '1 / 500'),
          _buildPlanItem('Messages', '2 / 1,000'),
          _buildPlanItem('Bulk broadcast notifications', '0 / 8'),
          _buildPlanItem('Transactional notifications', '0 / 1'),
          _buildPlanItem('API Requests', '0 / 100'),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contacts, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/contacts'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Contacts', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quick Links',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickLink(Icons.chat, 'Follow us on WhatsApp', Colors.green),
          _buildQuickLink(Icons.facebook, 'Join our Facebook group', Colors.blue),
          _buildQuickLink(Icons.star, 'Review us on TrustPilot', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadLiveData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF17A2B8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getConnectionStatus() {
    if (_dashboardData?.phoneNumberStatus?.status == 'VERIFIED') {
      return 'CONNECTED';
    }
    return 'DISCONNECTED';
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          // Handle quick link tap
        },
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStep(int step, String title, String description, IconData icon, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon, 
                  color: isCompleted ? Colors.white : Colors.grey[600], 
                  size: 24
                ),
              ),
              const Spacer(),
              if (isCompleted) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
            const SizedBox(height: 16),
          Text(
            'STEP $step', 
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey, 
              letterSpacing: 1
            )
          ),
          const SizedBox(height: 8),
          Text(
            title, 
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            description, 
            style: const TextStyle(
              fontSize: 14, 
              color: Colors.grey, 
              height: 1.4
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Learn more.', 
              style: TextStyle(
                color: Color(0xFF17A2B8), 
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, {bool isGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isGreen && value.isNotEmpty) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            if (isGreen && value.isNotEmpty) const SizedBox(width: 6),
            Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isGreen ? Colors.green : Colors.black87))),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherContent() {
    // Check if Inbox is selected
    if (_selectedIndex >= 0 && _selectedIndex < _sections.length && _sections[_selectedIndex].title == 'Inbox') {
      return _buildInboxContent();
    }
    
    // Default content for other sections
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_sections[_selectedIndex].icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_sections[_selectedIndex].title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Content coming soon...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInboxContent() {
    return InboxContentWidget(conversationsService: _conversationsService);
  }
}

// REST OF THE CODE REMAINS THE SAME AS YOUR PREVIOUS CODE
// (DashboardSection, SubSection, InboxContentWidget, etc.)

class DashboardSection {
  final IconData icon;
  final String title;
  final int? badge;
  bool isSelected;
  final List<SubSection>? subSections;
  bool isExpanded;

  DashboardSection({
    required this.icon, 
    required this.title, 
    this.badge, 
    this.isSelected = false,
    this.subSections,
    this.isExpanded = false,
  });
}

class SubSection {
  final String title;
  final IconData? icon;
  bool isSelected;

  SubSection({
    required this.title,
    this.icon,
    this.isSelected = false,
  });
}

// Inbox Content Widget - Shows inbox interface within main dashboard area
class InboxContentWidget extends StatefulWidget {
  final ConversationsService conversationsService;

  const InboxContentWidget({
    super.key,
    required this.conversationsService,
  });

  @override
  State<InboxContentWidget> createState() => _InboxContentWidgetState();
}

class _InboxContentWidgetState extends State<InboxContentWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  List<Conversation> conversations = [];
  List<Message> selectedConversationMessages = [];
  Conversation? selectedConversation;
  bool isLoading = true;
  String selectedFilter = 'All';
  String searchQuery = '';
  
  final List<String> filters = ['All', 'Active', 'Closed'];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);
    
    try {
      String? filterParam = selectedFilter == 'All' ? null : selectedFilter.toLowerCase();
      final loadedConversations = searchQuery.isEmpty
          ? await widget.conversationsService.getConversations(filter: filterParam)
          : await widget.conversationsService.searchConversations(searchQuery);
      
      setState(() {
        conversations = loadedConversations;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  Future<void> _loadConversationMessages(Conversation conversation) async {
    setState(() {
      selectedConversation = conversation;
      selectedConversationMessages = [];
    });

    try {
      final messages = await widget.conversationsService.getConversationMessages(conversation.id);
      setState(() {
        selectedConversationMessages = messages;
      });
      
      // Mark as read
      if (conversation.isUnread) {
        await widget.conversationsService.markAsRead(conversation.id);
        _loadConversations(); // Refresh conversations to update read status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || selectedConversation == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add message to UI immediately
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: selectedConversation!.id,
      content: messageText,
      timestamp: DateTime.now(),
      isFromBusiness: true,
      messageType: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      selectedConversationMessages.add(newMessage);
    });

    // Send via API
    final success = await widget.conversationsService.sendMessage(
      phoneNumber: selectedConversation!.phoneNumber,
      message: messageText,
    );

    if (success) {
      // Update message status to delivered
      setState(() {
        final index = selectedConversationMessages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          selectedConversationMessages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            isFromBusiness: newMessage.isFromBusiness,
            messageType: newMessage.messageType,
            status: MessageStatus.delivered,
          );
        }
      });
    } else {
      // Update message status to failed
      setState(() {
        final index = selectedConversationMessages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          selectedConversationMessages[index] = Message(
            id: newMessage.id,
            conversationId: newMessage.conversationId,
            content: newMessage.content,
            timestamp: newMessage.timestamp,
            isFromBusiness: newMessage.isFromBusiness,
            messageType: newMessage.messageType,
            status: MessageStatus.failed,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          // Stack layout for medium screens
          return Stack(
            children: [
              // Conversations list (hidden when conversation is selected)
              if (selectedConversation == null || constraints.maxWidth > 600)
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildConversationList(),
                  ),
                ),
              
              // Conversation view (slides in)
              if (selectedConversation != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildConversationView(),
                  ),
                ),
            ],
          );
        }
        
        // Desktop layout (original side-by-side)
        return Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left sidebar with constraints
              Expanded(
                flex: 1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildConversationList(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Main conversation area
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: selectedConversation == null
                      ? _buildSelectConversationState()
                      : _buildConversationView(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationList() {
    return Column(
      children: [
        // Conversations Header with Settings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: Colors.grey, size: 18),
                onPressed: () {
                  // Handle new conversation
                },
                tooltip: 'New Conversation',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessSettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey, size: 18),
                onPressed: () {
                  _loadConversations();
                },
                tooltip: 'Refresh',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        
        // Header with search and filters
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search contacts and messages',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                    _loadConversations();
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Filter tabs
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: filters.map((filter) => GestureDetector(
                  onTap: () {
                    setState(() => selectedFilter = filter);
                    _loadConversations();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedFilter == filter 
                          ? const Color(0xFF17A2B8) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selectedFilter == filter 
                            ? const Color(0xFF17A2B8) 
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selectedFilter == filter ? Colors.white : Colors.grey[700],
                        fontWeight: selectedFilter == filter ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        
        // Conversations list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return _buildConversationTile(conversation);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = selectedConversation?.id == conversation.id;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF17A2B8).withValues(alpha: 0.1) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF17A2B8),
          child: Text(
            _getInitials(conversation.contactName??''),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.contactName??'',
                style: TextStyle(
                  fontWeight: conversation.isUnread ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTimestamp(conversation.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: conversation.isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage??'',
                style: TextStyle(
                  fontSize: 11,
                  color: conversation.isUnread ? Colors.black87 : Colors.grey[600],
                  fontWeight: conversation.isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.isUnread)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF17A2B8),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '?',
                  style: TextStyle(color: Colors.white, fontSize: 6),
                ),
              ),
          ],
        ),
        onTap: () => _loadConversationMessages(conversation),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'All conversations loaded.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectConversationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Select a contact to view conversation.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationView() {
    return Column(
      children: [
        // Conversation header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF17A2B8),
                child: Text(
                  _getInitials(selectedConversation!.contactName??''),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedConversation!.contactName??'',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedConversation!.phoneNumber,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  // Show conversation options
                },
              ),
            ],
          ),
        ),
        
        // Messages list
        Expanded(
          child: selectedConversationMessages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: selectedConversationMessages.length,
                  itemBuilder: (context, index) {
                    final message = selectedConversationMessages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),
        
        // Message input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF17A2B8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isFromBusiness = message.isFromBusiness;
    
    return Align(
      alignment: isFromBusiness ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isFromBusiness ? const Color(0xFF17A2B8) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromBusiness ? 12 : 4),
            bottomRight: Radius.circular(isFromBusiness ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isFromBusiness ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    color: isFromBusiness ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                if (isFromBusiness) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 10,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}