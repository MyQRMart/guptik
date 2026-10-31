import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guptik/models/contacts/phone_contact.dart';
import 'package:guptik/services/contacts/device_contacts_service.dart';
import 'package:guptik/services/mediaplayer/node_url.dart';
import 'package:guptik/services/node/node_http.dart';

class ContactSyncService {
  Future<int> pushToNode(List<PhoneContact> contacts) async {
    final base = await NodeUrl.resolveMine();
    if (base == null || base.isEmpty) {
      throw StateError('Desktop node is offline.');
    }

    var sent = 0;
    const chunk = 80;
    final groups = await DeviceContactsService().loadGroups();
    for (var i = 0; i < contacts.length; i += chunk) {
      final slice = contacts.skip(i).take(chunk).map((c) => c.toJson()).toList();
      final res = await nodeHttp.post(
        Uri.parse('$base/contacts/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contacts': slice,
          'groups': i == 0 ? groups : [],
          'replace': i == 0,
          'offset': i,
        }),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        debugPrint('Contact sync HTTP ${res.statusCode}: ${res.body}');
        throw StateError('Node rejected sync (${res.statusCode}).');
      }
      sent += slice.length;
    }
    if (contacts.isEmpty) {
      final res = await nodeHttp.post(
        Uri.parse('$base/contacts/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contacts': [], 'replace': true, 'offset': 0}),
      );
      if (res.statusCode != 200) {
        throw StateError('Node rejected empty sync.');
      }
    }
    return sent;
  }
}
