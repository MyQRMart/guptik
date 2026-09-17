import 'package:flutter/material.dart';
import 'package:guptik/models/contacts/phone_contact.dart';
import 'package:guptik/screens/dashboard/contact_people_page.dart';
import 'package:guptik/services/contacts/device_contacts_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

const Color _gold = Color(0xFFD4AF37);

class SmartSegmentsScreen extends StatefulWidget {
  const SmartSegmentsScreen({super.key});

  @override
  State<SmartSegmentsScreen> createState() => _SmartSegmentsScreenState();
}

class _SmartSegmentsScreenState extends State<SmartSegmentsScreen> {
  final _search = TextEditingController();
  final _device = DeviceContactsService();
  List<PhoneContact> _all = [];
  bool _loading = true;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _denied = false;
    });
    if (!await _device.requestAccess()) {
      if (!mounted) return;
      setState(() {
        _denied = true;
        _loading = false;
      });
      return;
    }
    final people = await _device.loadAll();
    if (!mounted) return;
    setState(() {
      _all = people;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _segments {
    final defs = [
      ('Starred', 'Favourites on this phone', 'Starred', Icons.star),
      ('Has a phone', 'At least one number', 'Phone', Icons.phone),
      ('Has an email', 'At least one email', 'Email', Icons.email_outlined),
      ('Phone + email', 'Both number and email', 'Both', Icons.verified),
      ('Has an address', 'Postal address present', 'Address', Icons.place_outlined),
      ('Company / org', 'Organization filled in', 'Org', Icons.business),
      ('Missing phone', 'No number on the card', 'MissingPhone', Icons.phone_disabled),
      ('Missing email', 'No email on the card', 'MissingEmail', Icons.mail_outline),
    ];
    final rows = defs
        .map((d) => {
              'name': d.$1,
              'description': d.$2,
              'filter': d.$3,
              'icon': d.$4,
              'contact_count': filterPhoneContacts(_all, d.$3).length,
              'is_active': true,
            })
        .toList();
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((s) =>
            s['name'].toString().toLowerCase().contains(q) ||
            s['description'].toString().toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _segments;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Smart Segments', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, color: _gold)),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    _stat('Segments', '${rows.length}'),
                    _stat('Phone book', '${_all.length}'),
                    _stat('Active', '${rows.where((s) => (s['contact_count'] as int) > 0).length}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search segments…',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: _gold),
                    filled: true,
                    fillColor: Colors.black54,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _gold, width: 2),
                    ),
                  ),
                ),
              ),
              Expanded(child: _body(rows)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String l, String v) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(l, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _body(List<Map<String, dynamic>> rows) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (_denied) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: const Text('Grant contacts access', style: TextStyle(color: _gold)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final s = rows[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(s['icon'] as IconData, color: _gold),
            title: Text(s['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(s['description'].toString(), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            trailing: Text('${s['contact_count']}', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
            onTap: () => openPeople(
              context,
              s['name'].toString(),
              filterPhoneContacts(_all, s['filter'] as String),
            ),
          ),
        );
      },
    );
  }
}
