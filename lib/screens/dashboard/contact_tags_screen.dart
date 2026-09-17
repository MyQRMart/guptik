import 'package:flutter/material.dart';
import 'package:guptik/models/contacts/phone_contact.dart';
import 'package:guptik/screens/dashboard/contact_people_page.dart';
import 'package:guptik/services/contacts/device_contacts_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

const Color _gold = Color(0xFFD4AF37);

class ContactTagsScreen extends StatefulWidget {
  const ContactTagsScreen({super.key});

  @override
  State<ContactTagsScreen> createState() => _ContactTagsScreenState();
}

class _ContactTagsScreenState extends State<ContactTagsScreen> {
  final _search = TextEditingController();
  final _device = DeviceContactsService();
  List<PhoneContact> _all = [];
  List<Map<String, dynamic>> _groups = [];
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
    final groups = await _device.loadGroups();
    if (!mounted) return;
    setState(() {
      _all = people;
      _groups = groups;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _rows {
    final derived = <Map<String, dynamic>>[
      {
        'id': 'starred',
        'name': 'Starred',
        'description': 'Favourites on this phone',
        'contact_count': _all.where((c) => c.isStarred).length,
        'kind': 'filter',
        'filter': 'Starred',
      },
      {
        'id': 'email',
        'name': 'Has email',
        'description': 'At least one email address',
        'contact_count': _all.where((c) => c.emails.isNotEmpty).length,
        'kind': 'filter',
        'filter': 'Email',
      },
      {
        'id': 'phone',
        'name': 'Has phone',
        'description': 'At least one number',
        'contact_count': _all.where((c) => c.phones.isNotEmpty).length,
        'kind': 'filter',
        'filter': 'Phone',
      },
      {
        'id': 'address',
        'name': 'Has address',
        'description': 'Postal address on file',
        'contact_count': filterPhoneContacts(_all, 'Address').length,
        'kind': 'filter',
        'filter': 'Address',
      },
      {
        'id': 'org',
        'name': 'Company',
        'description': 'Organization / job title',
        'contact_count': filterPhoneContacts(_all, 'Org').length,
        'kind': 'filter',
        'filter': 'Org',
      },
    ];
    final groups = _groups
        .map((g) => {
              ...g,
              'kind': 'group',
              'description': (g['description'] as String?)?.isNotEmpty == true
                  ? g['description']
                  : 'Phone group',
            })
        .toList();
    final all = [...derived, ...groups];
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((t) =>
            t['name'].toString().toLowerCase().contains(q) ||
            t['description'].toString().toLowerCase().contains(q))
        .toList();
  }

  Future<void> _create() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('New tag (phone group)', style: TextStyle(color: _gold)),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Name', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create', style: TextStyle(color: _gold))),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    final saved = await _device.createGroup(c.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved ? 'Group created on this phone.' : 'Could not create group.'),
    ));
    if (saved) _load();
  }

  Future<void> _open(Map<String, dynamic> row) async {
    if (row['kind'] == 'group') {
      final id = row['id']?.toString() ?? '';
      final people = id.isEmpty ? <PhoneContact>[] : await _device.loadGroupMembers(id);
      if (!mounted) return;
      openPeople(context, row['name'].toString(), people);
      return;
    }
    openPeople(context, row['name'].toString(), filterPhoneContacts(_all, row['filter'] as String));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Contact Tags', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, color: _gold)),
          IconButton(onPressed: _denied ? null : _create, icon: const Icon(Icons.add, color: _gold)),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              _stats(rows),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search tags…',
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

  Widget _stats(List<Map<String, dynamic>> rows) {
    final tagged = rows.fold<int>(0, (s, t) => s + ((t['contact_count'] as num?)?.toInt() ?? 0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _stat('Tags', '${rows.length}'),
          _stat('On phone', '${_all.length}'),
          _stat('Tagged hits', '$tagged'),
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
    if (rows.isEmpty) {
      return const Center(child: Text('No tags yet.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final t = rows[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(t['kind'] == 'group' ? Icons.folder_special : Icons.local_offer, color: _gold),
            title: Text(t['name'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(t['description'].toString(), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            trailing: Text('${t['contact_count']}', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
            onTap: () => _open(t),
          ),
        );
      },
    );
  }
}
