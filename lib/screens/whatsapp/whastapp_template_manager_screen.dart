import 'package:flutter/material.dart';
import 'package:guptik/screens/whatsapp/internal_tab.dart';
import 'package:guptik/screens/whatsapp/template_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsAppTemplateManagerScreen extends StatelessWidget {
  const WhatsAppTemplateManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current logged-in user
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[100],
          title: const Text(
            'WhatsApp Template Manager',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'WhatsApp Templates'),
              Tab(text: 'Template Groups'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.teal[800]),
                        const SizedBox(width: 4),
                        Text(
                          user.email?.split('@').first ?? 'User',
                          style: TextStyle(
                            color: Colors.teal[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: const TabBarView(
          children: [TemplateListScreen(), InternalGroupsTab()],
        ),
      ),
    );
  }
}
