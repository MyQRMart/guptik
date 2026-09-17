import 'package:flutter/material.dart';
import 'package:guptik/models/contacts/phone_contact.dart';
import 'package:guptik/screens/dashboard/contacts_screen.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _gold = Color(0xFFD4AF37);

class ContactPeoplePage extends StatelessWidget {
  final String title;
  final List<PhoneContact> people;

  const ContactPeoplePage({super.key, required this.title, required this.people});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('${people.length} people', style: TextStyle(color: Colors.grey[400])),
              ),
              Expanded(
                child: people.isEmpty
                    ? const Center(child: Text('No contacts in this set.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: people.length,
                        itemBuilder: (_, i) {
                          final c = people[i];
                          final initial = c.displayName.isEmpty ? '?' : c.displayName[0].toUpperCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _gold.withValues(alpha: 0.3)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.black,
                                child: Text(initial, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(c.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                [c.primaryPhone, c.primaryEmail].where((s) => s.isNotEmpty).join(' · '),
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              onTap: () {
                                if (c.primaryPhone.isNotEmpty) {
                                  launchUrl(Uri(scheme: 'tel', path: c.primaryPhone));
                                } else if (c.primaryEmail.isNotEmpty) {
                                  launchUrl(Uri(scheme: 'mailto', path: c.primaryEmail));
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<PhoneContact> filterPhoneContacts(List<PhoneContact> all, String key) {
  switch (key) {
    case 'Starred':
      return all.where((c) => c.isStarred).toList();
    case 'Phone':
      return all.where((c) => c.phones.isNotEmpty).toList();
    case 'Email':
      return all.where((c) => c.emails.isNotEmpty).toList();
    case 'Both':
      return all.where((c) => c.phones.isNotEmpty && c.emails.isNotEmpty).toList();
    case 'Address':
      return all.where((c) => c.addresses.any((a) => (a['formatted'] ?? '').trim().isNotEmpty)).toList();
    case 'Org':
      return all.where((c) => c.organization.trim().isNotEmpty).toList();
    case 'MissingPhone':
      return all.where((c) => c.phones.isEmpty).toList();
    case 'MissingEmail':
      return all.where((c) => c.emails.isEmpty).toList();
    default:
      return all;
  }
}

void openPeople(BuildContext context, String title, List<PhoneContact> people) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ContactPeoplePage(title: title, people: people)),
  );
}

/// Kept so older calls to ContactsScreen(initialFilter) still compile.
void openContactsFilter(BuildContext context, String filter) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ContactsScreen(initialFilter: filter)),
  );
}
