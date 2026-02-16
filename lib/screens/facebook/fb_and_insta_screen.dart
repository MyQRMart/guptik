import 'package:flutter/material.dart';
import 'content_screen.dart'; // Make sure this import is correct
import 'inbox_screen.dart';   // Make sure this import is correct

class FbAndInstaScreen extends StatefulWidget {
  const FbAndInstaScreen({super.key});

  @override
  State<FbAndInstaScreen> createState() => _FbAndInstaScreenState();
}

class _FbAndInstaScreenState extends State<FbAndInstaScreen> {
  int _currentIndex = 0;

  // The screens for the bottom tabs
  final List<Widget> _screens = [
    const ContentScreen(), // This screen HAS its own button already
    const InboxScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Facebook & Instagram', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: _screens[_currentIndex],

      // ---------------------------------------------------------
      // ✅ FIX: REMOVED the FloatingActionButton from here.
      // We rely on the one inside 'ContentScreen' instead.
      // ---------------------------------------------------------

      // ---------------------------------------------------------
      // BOTTOM NAVIGATION: Content & Inbox
      // ---------------------------------------------------------
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        // Using a safe opacity approach
        indicatorColor: const Color(0xFF1877F2).withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF1877F2)),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF1877F2)),
            label: 'Inbox',
          ),
        ],
      ),
    );
  }
}