import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guptik/screens/mediaplayer/Mobile_monetization_screen.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/screens/node/pair_node_screen.dart';
import 'package:guptik/services/node/node_auth.dart';

import 'mobile_home_loader.dart';
import 'mobile_upload_screen.dart';
import 'mobile_profile_screen.dart';
import 'mobile_reels_screen.dart';

class MobileMainLayout extends StatefulWidget {
  final String gatewayUrl;
  final String currentUserUid; 

  const MobileMainLayout({
    Key? key, 
    required this.gatewayUrl,
    required this.currentUserUid,
  }) : super(key: key);

  @override
  _MobileMainLayoutState createState() => _MobileMainLayoutState();
}

class _MobileMainLayoutState extends State<MobileMainLayout> {
  int _currentIndex = 0;
  late String _resolvedUserId;
  String? _userChannelId;
  bool _isResolvingChannel = true;

  /// Viewer ("incognito") mode: this phone is not paired with a PC, so it can watch public
  /// videos and see basic details, but cannot upload or use the owner-only tabs.
  bool get _viewerOnly => !NodeAuth.instance.isPaired;

  void _authChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    NodeAuth.instance.removeListener(_authChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    NodeAuth.instance.addListener(_authChanged);
    _resolvedUserId = widget.currentUserUid;
    _resolveActiveUserAndChannel();
  }

  String _getSanitizedGatewayUrl() {
    return NodeUrl.sanitize(widget.gatewayUrl);
  }

  Future<void> _resolveActiveUserAndChannel() async {
    try {
      final supabase = Supabase.instance.client;
      var user = supabase.auth.currentUser;
      
      if (_resolvedUserId.isEmpty && user != null) {
        _resolvedUserId = user.id;
      }

      if (_resolvedUserId.isNotEmpty) {
        // 1. Try to find the channel using the user's explicit auth ID / owner_uid
        try {
          final channelData = await supabase
              .from('mp_channels')
              .select('channel_id')
              .or('channel_id.eq.$_resolvedUserId,owner_uid.eq.$_resolvedUserId')
              .maybeSingle();

          if (channelData != null && channelData['channel_id'] != null) {
            if (mounted) {
              setState(() {
                _userChannelId = channelData['channel_id'].toString();
                _isResolvingChannel = false;
              });
            }
            return;
          }
        } catch (_) {}

        // 2. Fallback: Query mp_videos to find the channel_id associated with this user's uploads
        try {
          final videoChannel = await supabase
              .from('mp_videos')
              .select('channel_id')
              .eq('creator_uid', _resolvedUserId)
              .limit(1)
              .maybeSingle();

          if (videoChannel != null && videoChannel['channel_id'] != null) {
            if (mounted) {
              setState(() {
                _userChannelId = videoChannel['channel_id'].toString();
                _isResolvingChannel = false;
              });
            }
            return;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("⚠️ Channel resolution warning: $e");
    }

    if (mounted) {
      setState(() {
        _userChannelId = _resolvedUserId.isNotEmpty ? _resolvedUserId : null;
        _isResolvingChannel = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingChannel) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final effectiveChannelId = _userChannelId ?? _resolvedUserId;
    final sanitizedNodeUrl = _getSanitizedGatewayUrl();
    if (sanitizedNodeUrl.isEmpty && !_viewerOnly) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No desktop node URL. Pair your PC first.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // 🚀 Updated screens layout: Home (0), Shots (1), Upload (2), Profile (3), Earnings (4)
    final List<Widget> screens = [
      MobileHomeLoader(gatewayUrl: sanitizedNodeUrl),
      // 🚀 FIX: MobileReelsScreen lives inside an IndexedStack, so it stays
      // mounted (and its video was auto-playing) even while another tab is
      // showing. `isVisible` is only true while the Shots tab (index 1) is
      // actually selected, so playback only starts when the user taps the
      // Shots icon and stops the instant they switch away.
      MobileReelsScreen(gatewayUrl: sanitizedNodeUrl, isVisible: _currentIndex == 1),
      if (_viewerOnly)
        const _PairPrompt(what: 'upload videos')
      else
        MobileUploadScreen(gatewayUrl: sanitizedNodeUrl),
      if (_viewerOnly)
        const _PairPrompt(what: 'see your channel')
      else
        MobileProfileScreen(
          key: ValueKey(effectiveChannelId),
          channelId: effectiveChannelId,
          nodeUrl: sanitizedNodeUrl,
        ),
      if (_viewerOnly)
        const _PairPrompt(what: 'see your earnings')
      else
        MobileMonetizationScreen(channelId: effectiveChannelId),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      extendBody: true, 
      bottomNavigationBar: _buildGlassmorphicNavBar(),
    );
  }

  Widget _buildGlassmorphicNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 85,
          padding: const EdgeInsets.only(bottom: 15), 
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.6), 
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(icon: Icons.home_filled, index: 0, label: "Home"),
              _buildNavItem(icon: Icons.slow_motion_video_rounded, index: 1, label: "Shots"), // 🚀 ADDED: Shots tab (reels-only vertical feed)
              _buildCenterUploadButton(),
              _buildNavItem(icon: Icons.person_rounded, index: 3, label: "Profile"),
              _buildNavItem(icon: Icons.monetization_on_outlined, index: 4, label: "Earnings"), // 🚀 ADDED
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? Colors.orange : Colors.grey[500],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey[500],
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCenterUploadButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (_currentIndex == 2)
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              )
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}


/// Shown in place of owner-only tabs while the phone is not paired with a PC.
class _PairPrompt extends StatelessWidget {
  const _PairPrompt({required this.what});
  final String what;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              Text('Pair your PC to $what',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('You are watching as a viewer: public videos and basic details only.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PairNodeScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Pair with PC', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
