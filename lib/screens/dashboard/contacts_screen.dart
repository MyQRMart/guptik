import 'package:flutter/material.dart';
import 'package:guptik/models/contacts/phone_contact.dart';
import 'package:guptik/services/contacts/contact_sync_service.dart';
import 'package:guptik/services/contacts/device_contacts_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _gold = Color(0xFFD4AF37);
const Color _bg = Color(0xFF0A0A0A);

class ContactsScreen extends StatefulWidget {
  final String? initialFilter;
  const ContactsScreen({super.key, this.initialFilter});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  final _device = DeviceContactsService();
  final _sync = ContactSyncService();

  List<PhoneContact> _all = [];
  String _filter = 'All';
  bool _loading = true;
  bool _denied = false;
  bool _syncing = false;
  String? _error;

  static const _filters = ['All', 'Starred', 'Phone', 'Email'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && _filters.contains(widget.initialFilter)) {
      _filter = widget.initialFilter!;
    }
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
      _error = null;
    });
    final ok = await _device.requestAccess();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _denied = true;
        _loading = false;
      });
      return;
    }
    try {
      final list = await _device.loadAll();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not read phone contacts.';
        _loading = false;
      });
    }
  }

  List<PhoneContact> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _all.where((c) {
      final hitSearch = q.isEmpty ||
          c.displayName.toLowerCase().contains(q) ||
          c.organization.toLowerCase().contains(q) ||
          c.phones.any((p) => (p['number'] ?? '').contains(q)) ||
          c.emails.any((e) => (e['address'] ?? '').toLowerCase().contains(q));
      final hitFilter = _filter == 'All' ||
          (_filter == 'Starred' && c.isStarred) ||
          (_filter == 'Phone' && c.phones.isNotEmpty) ||
          (_filter == 'Email' && c.emails.isNotEmpty);
      return hitSearch && hitFilter;
    }).toList();
  }

  Future<void> _syncNode() async {
    setState(() => _syncing = true);
    try {
      final n = await _sync.pushToNode(_all);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $n contacts to your desktop node.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Add to phone', style: TextStyle(color: _gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(name, 'Name'),
            const SizedBox(height: 8),
            _field(phone, 'Phone', keyboard: TextInputType.phone),
            const SizedBox(height: 8),
            _field(email, 'Email', keyboard: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save', style: TextStyle(color: _gold))),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final saved = await _device.insert(
      name: name.text.trim(),
      phone: phone.text.trim(),
      email: email.text.trim(),
    );
    if (!mounted) return;
    if (saved) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not write to the phone address book.')),
      );
    }
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _gold.withValues(alpha: 0.4))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _gold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: _gold),
        actions: [
          IconButton(
            tooltip: 'Reload phone',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: _gold),
          ),
          IconButton(
            tooltip: 'Sync to desktop',
            onPressed: (_loading || _denied || _syncing) ? null : _syncNode,
            icon: _syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                : const Icon(Icons.cloud_upload_outlined, color: _gold),
          ),
          IconButton(
            tooltip: 'Add to phone',
            onPressed: _denied ? null : _add,
            icon: const Icon(Icons.person_add, color: _gold),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              _stats(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, email…',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: _gold),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.5),
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
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _filters.map((f) {
                    final on = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f, style: TextStyle(color: on ? _gold : Colors.white70)),
                        selected: on,
                        onSelected: (_) => setState(() => _filter = f),
                        backgroundColor: Colors.black54,
                        selectedColor: _gold.withValues(alpha: 0.18),
                        checkmarkColor: _gold,
                        side: BorderSide(color: on ? _gold : Colors.white24),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _stat('Phone book', '${_all.length}', Icons.smartphone),
          _stat('Starred', '${_all.where((c) => c.isStarred).length}', Icons.star),
          _stat('With email', '${_all.where((c) => c.emails.isNotEmpty).length}', Icons.email_outlined),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }
    if (_denied) {
      return _message(
        Icons.lock_outline,
        'Contacts permission needed',
        'Allow GupTik to read this phone’s address book.',
        action: 'Grant access',
        onTap: _load,
      );
    }
    if (_error != null) {
      return _message(Icons.error_outline, _error!, 'Try again.', action: 'Retry', onTap: _load);
    }
    final rows = _visible;
    if (rows.isEmpty) {
      return _message(
        Icons.contacts_outlined,
        _all.isEmpty ? 'No contacts on this phone' : 'Nothing in this filter',
        _all.isEmpty ? 'Add a contact or sync after you have people in the address book.' : 'Clear search or switch section.',
        action: _all.isEmpty ? 'Add contact' : null,
        onTap: _all.isEmpty ? _add : null,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: rows.length,
      itemBuilder: (_, i) => _card(rows[i]),
    );
  }

  Widget _message(IconData icon, String title, String sub, {String? action, VoidCallback? onTap}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: _gold.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub, style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
            if (action != null && onTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
                child: Text(action),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(PhoneContact c) {
    final initial = c.displayName.isEmpty ? '?' : c.displayName[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: () => _detail(c),
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Text(initial, style: const TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(c.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            if (c.isStarred) const Icon(Icons.star, color: _gold, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.primaryPhone.isNotEmpty)
              Text(c.primaryPhone, style: TextStyle(color: Colors.grey[300], fontFamily: 'monospace')),
            if (c.primaryEmail.isNotEmpty)
              Text(c.primaryEmail, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (c.organization.isNotEmpty)
              Text(c.organization, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        isThreeLine: c.primaryEmail.isNotEmpty || c.organization.isNotEmpty,
      ),
    );
  }

  void _detail(PhoneContact c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.displayName, style: const TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.bold)),
              if (c.organization.isNotEmpty)
                Text('${c.organization}${c.jobTitle.isNotEmpty ? ' · ${c.jobTitle}' : ''}',
                    style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              ...c.phones.map((p) => _row(Icons.phone, p['number'] ?? '', p['label'] ?? '', () {
                    launchUrl(Uri(scheme: 'tel', path: p['number']));
                  })),
              ...c.emails.map((e) => _row(Icons.email_outlined, e['address'] ?? '', e['label'] ?? '', () {
                    launchUrl(Uri(scheme: 'mailto', path: e['address']));
                  })),
              ...c.addresses.map((a) => _row(Icons.place_outlined, a['formatted'] ?? '', a['label'] ?? '', null)),
              if (c.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(c.notes, style: TextStyle(color: Colors.grey[400])),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String value, String label, VoidCallback? onTap) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _gold, size: 20),
      title: Text(value, style: const TextStyle(color: Colors.white)),
      subtitle: label.isEmpty ? null : Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      onTap: onTap,
    );
  }
}
