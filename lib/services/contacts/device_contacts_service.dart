import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:guptik/models/contacts/phone_contact.dart';

class DeviceContactsService {
  Future<bool> requestAccess() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.readWrite);
      return status == PermissionStatus.granted || status == PermissionStatus.limited;
    } catch (e) {
      debugPrint('Contacts permission: $e');
      return false;
    }
  }

  Future<List<PhoneContact>> loadAll() async {
    final raw = await FlutterContacts.getAll(properties: ContactProperties.allProperties);
    var mapped = raw
        .map(_map)
        .where((c) => c.displayName.trim().isNotEmpty || c.deviceId.isNotEmpty)
        .toList();
    try {
      final groups = await FlutterContacts.groups.getAll();
      final extra = <String, List<String>>{};
      for (final g in groups) {
        final gid = g.id;
        if (gid == null || gid.isEmpty) continue;
        final members = await FlutterContacts.getAll(
          filter: ContactFilter.group(gid),
          properties: ContactProperties.none,
        );
        for (final m in members) {
          extra.putIfAbsent(m.id ?? '', () => []).add(gid);
        }
      }
      mapped = mapped
          .map((c) => extra.containsKey(c.deviceId) ? c.copyWith(groups: extra[c.deviceId]) : c)
          .toList();
    } catch (e) {
      debugPrint('Group membership: $e');
    }
    mapped.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return mapped;
  }

  Future<List<Map<String, dynamic>>> loadGroups() async {
    try {
      final groups = await FlutterContacts.groups.getAll(withContactCount: true);
      return groups
          .where((g) => (g.id ?? '').isNotEmpty)
          .map((g) => {
                'id': g.id,
                'name': g.name,
                'description': g.account?.name ?? '',
                'contact_count': g.contactCount ?? 0,
                'is_active': true,
              })
          .toList();
    } catch (e) {
      debugPrint('Groups load: $e');
      return [];
    }
  }

  Future<bool> insert({
    required String name,
    String phone = '',
    String email = '',
  }) async {
    try {
      await FlutterContacts.create(Contact(
        name: Name(first: name),
        phones: phone.trim().isEmpty ? const [] : [Phone(number: phone.trim())],
        emails: email.trim().isEmpty ? const [] : [Email(address: email.trim())],
      ));
      return true;
    } catch (e) {
      debugPrint('Insert contact: $e');
      return false;
    }
  }

  PhoneContact _map(Contact c) {
    final org = c.organizations.isEmpty ? null : c.organizations.first;
    final name = c.name;
    return PhoneContact(
      deviceId: c.id ?? '',
      displayName: (c.displayName ?? '').trim().isEmpty
          ? '${name?.first ?? ''} ${name?.last ?? ''}'.trim()
          : c.displayName!.trim(),
      givenName: name?.first ?? '',
      familyName: name?.last ?? '',
      organization: org?.name ?? '',
      jobTitle: org?.jobTitle ?? '',
      notes: c.notes.map((n) => n.note).where((n) => n.trim().isNotEmpty).join('\n'),
      isStarred: c.android?.isFavorite == true,
      phones: c.phones
          .map((p) => {
                'number': p.number,
                'label': p.label.customLabel ?? p.label.label.name,
              })
          .toList(),
      emails: c.emails
          .map((e) => {
                'address': e.address,
                'label': e.label.customLabel ?? e.label.label.name,
              })
          .toList(),
      addresses: c.addresses
          .map((a) => {
                'formatted': a.formatted ?? '',
                'street': a.street ?? '',
                'city': a.city ?? '',
                'region': a.state ?? '',
                'postcode': a.postalCode ?? '',
                'country': a.country ?? '',
                'label': a.label.customLabel ?? a.label.label.name,
              })
          .toList(),
    );
  }

  Future<List<PhoneContact>> loadGroupMembers(String groupId) async {
    final raw = await FlutterContacts.getAll(
      properties: ContactProperties.allProperties,
      filter: ContactFilter.group(groupId),
    );
    return raw.map(_map).toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  Future<bool> createGroup(String name) async {
    try {
      await FlutterContacts.groups.create(name.trim());
      return true;
    } catch (e) {
      debugPrint('Create group: $e');
      return false;
    }
  }

  Future<String> exportVcf() async {
    final raw = await FlutterContacts.getAll(properties: ContactProperties.allProperties);
    return FlutterContacts.vCard.exportAll(raw);
  }

  Future<int> importVcf(String text) async {
    final parsed = FlutterContacts.vCard.import(text);
    if (parsed.isEmpty) return 0;
    await FlutterContacts.createAll(parsed);
    return parsed.length;
  }

  Future<int> importCsv(String text) async {
    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;
    var start = 0;
    if (lines.first.toLowerCase().contains('name') && lines.first.contains(',')) {
      start = 1;
    }
    var n = 0;
    for (var i = start; i < lines.length; i++) {
      final cols = _csvRow(lines[i]);
      if (cols.isEmpty) continue;
      final name = cols[0].trim();
      if (name.isEmpty) continue;
      final phone = cols.length > 1 ? cols[1].trim() : '';
      final email = cols.length > 2 ? cols[2].trim() : '';
      if (await insert(name: name, phone: phone, email: email)) n++;
    }
    return n;
  }

  String toCsv(List<PhoneContact> contacts) {
    final buf = StringBuffer('name,phone,email,organization,address\n');
    for (final c in contacts) {
      buf.writeln([
        _csvCell(c.displayName),
        _csvCell(c.primaryPhone),
        _csvCell(c.primaryEmail),
        _csvCell(c.organization),
        _csvCell(c.addresses.isEmpty ? '' : (c.addresses.first['formatted'] ?? '')),
      ].join(','));
    }
    return buf.toString();
  }

  List<String> _csvRow(String line) {
    final out = <String>[];
    final re = RegExp(r'"([^"]*)"|([^,]+)');
    for (final m in re.allMatches(line)) {
      out.add((m.group(1) ?? m.group(2) ?? '').trim());
    }
    return out;
  }

  String _csvCell(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
