import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'content_screen.dart';
import 'inbox_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'reels_screen.dart';
import 'stories_screen.dart';
import 'create_post_screen.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';

class FbAndInstaScreen extends StatefulWidget {
  const FbAndInstaScreen({super.key});

  @override
  State<FbAndInstaScreen> createState() => _FbAndInstaScreenState();
}

class _FbAndInstaScreenState extends State<FbAndInstaScreen> {
  final MetaService _metaService = MetaService();
  int _currentIndex = 0;

  // User profile data
  String? _userAvatarUrl;
  String? _userName;
  String? _userEmail;
  bool _isLoadingUser = true;

  // Real data variables
  int _fbFollowers = 0;
  int _igFollowers = 0;
  double _engagementRate = 0.0;
  bool _isLoadingStats = true;

  final List<Widget> _screens = [const ContentScreen(), const InboxScreen()];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userName =
              user.userMetadata?['full_name'] ??
              user.email?.split('@').first ??
              'User';
          _userEmail = user.email;
          _userAvatarUrl = user.userMetadata?['avatar_url'];
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      // Fetch Facebook followers
      final fbInsights = await _metaService.getPageInsights(
        SocialPlatform.facebook,
      );
      // Fetch Instagram followers
      final igInsights = await _metaService.getPageInsights(
        SocialPlatform.instagram,
      );

      // Calculate engagement rate (average of both platforms)
      double fbEngagement = fbInsights?.engagementRate ?? 0;
      double igEngagement = igInsights?.engagementRate ?? 0;
      double avgEngagement = (fbEngagement + igEngagement) / 2;

      if (mounted) {
        setState(() {
          _fbFollowers = fbInsights?.followers ?? 0;
          _igFollowers = igInsights?.followers ?? 0;
          _engagementRate = avgEngagement;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: FontAwesomeIcons.facebook,
                  label: 'FB Analytics',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsDashboardScreen(
                          platform: SocialPlatform.facebook,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: FontAwesomeIcons.instagram,
                  label: 'IG Analytics',
                  color: const Color(0xFFE1306C),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsDashboardScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.video_library,
                  label: 'Reels',
                  color: const Color(0xFF5851DB),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReelsScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.history,
                  label: 'Stories',
                  color: const Color(0xFFFFA500),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoriesScreen(
                          platform: SocialPlatform.instagram,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Professional Header with Avatar (No Popup)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Avatar - Top Left (No GestureDetector, just display)
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1877F2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: _userAvatarUrl != null
                                  ? NetworkImage(_userAvatarUrl!)
                                  : null,
                              backgroundColor: Colors.grey[200],
                              child: _userAvatarUrl == null
                                  ? _isLoadingUser
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _userName?.isNotEmpty == true
                                                ? _userName![0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Show user name and email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _userName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_userEmail != null)
                                Text(
                                  _userEmail!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Create Post Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1877F2), Color(0xFFE1306C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostScreen(),
                              ),
                            );
                          },
                          tooltip: 'Create Post',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Real Stats Row
                  if (_isLoadingStats)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'FB Followers',
                          _formatNumber(_fbFollowers),
                          const Color(0xFF1877F2),
                        ),
                        _buildStatCard(
                          'IG Followers',
                          _formatNumber(_igFollowers),
                          const Color(0xFFE1306C),
                        ),
                        _buildStatCard(
                          'Engagement',
                          '${_engagementRate.toStringAsFixed(1)}%',
                          const Color(0xFF31A24C),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Main Content
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF1877F2),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Content',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Inbox',
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsMenu,
        backgroundColor: const Color(0xFF1877F2),
        mini: true,
        child: const Icon(Icons.menu, size: 20),
        tooltip: 'Quick Actions',
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
