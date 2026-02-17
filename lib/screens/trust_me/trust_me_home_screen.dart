import 'package:flutter/material.dart';
import 'trust_me_chat_list_screen.dart';
import 'trust_me_status_screen.dart';
import 'trust_me_calls_screen.dart';

class TrustMeHomeScreen extends StatefulWidget {
  const TrustMeHomeScreen({super.key});

  @override
  State<TrustMeHomeScreen> createState() => _TrustMeHomeScreenState();
}

class _TrustMeHomeScreenState extends State<TrustMeHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Camera, Chats, Updates, Calls
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF075E54),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF25D366),
        ),
        // Removed tabBarTheme to fix the type error. 
        // We will style the TabBar directly below.
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trust Me"),
          actions: [
            IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true, // This helps tabs fit better
            indicatorColor: Colors.white, // Style added here directly
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              // FIXED: Removed 'width'. Used Container to size the icon if needed, 
              // or just the Icon itself.
              Tab(icon: Icon(Icons.camera_alt)), 
              Tab(text: "CHATS"),
              Tab(text: "UPDATES"),
              Tab(text: "CALLS"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            Center(child: Text("Camera")),
            TrustMeChatListScreen(),
            TrustMeStatusScreen(),
            TrustMeCallsScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.message, color: Colors.white),
        ),
      ),
    );
  }
}