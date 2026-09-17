import 'package:flutter/foundation.dart';
import 'package:guptik/models/whatsapp/internal_template.dart';
import 'package:guptik/models/whatsapp/template.dart';
import 'package:guptik/models/whatsapp/wa_template_group.dart';
import 'package:guptik/services/node/node_table_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final _store = NodeTableClient();

  String? getCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in!');
    }
    return user?.id;
  }

  Future<Map<String, dynamic>?> getUserApiSettings() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return await _client.from('user_api_settings').select().eq('user_id', userId).maybeSingle();
  }

  Future<Map<String, String>> getWhatsAppCredentials() async {
    final settings = await getUserApiSettings();
    if (settings == null) {
      throw Exception(
        'No API settings found. Please configure your WhatsApp credentials in Settings tab.',
      );
    }
    return {
      'accessToken': settings['whatsapp_access_token'] ?? '',
      'phoneNumberId': settings['meta_wa_phone_number_id'] ?? '',
      'businessAccountId': settings['meta_business_account_id'] ?? '',
      'appId': settings['meta_app_id'] ?? '',
    };
  }

  Future<List<WhatsAppTemplate>> getTemplates() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    final response = await _store.select(
      'whatsapp_templates',
      eq: {'user_id': userId},
      order: 'created_at',
      ascending: false,
    );
    return response.map(WhatsAppTemplate.fromJson).toList();
  }

  Future<List<WhatsAppTemplate>> getApprovedTemplates() async {
    final templates = await getTemplates();
    return templates.where((t) => t.status.toLowerCase().contains('approved')).toList();
  }

  Future<WhatsAppTemplate?> getTemplateById(String id) async {
    final response = await _store.maybeSingle('whatsapp_templates', {'id': id});
    if (response == null) return null;
    return WhatsAppTemplate.fromJson(response);
  }

  Future<void> insertTemplate(WhatsAppTemplate template) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    final data = template.toJson();
    data['user_id'] = userId;
    await _store.insert('whatsapp_templates', data);
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> updates) async {
    await _store.update('whatsapp_templates', eq: {'id': id}, set: updates);
  }

  Future<void> deleteTemplate(String id) async {
    await _store.delete('whatsapp_templates', {'id': id});
  }

  Future<void> updateTemplateStatus(String id, String status) async {
    await _store.update(
      'whatsapp_templates',
      eq: {'id': id},
      set: {'status': status, 'updated_at': DateTime.now().toIso8601String()},
    );
  }

  Future<void> updateTemplateStatusByNumericId(String numericId, String status) async {
    await _store.update(
      'whatsapp_templates',
      eq: {'whatsapp_numeric_id': numericId},
      set: {'status': status, 'updated_at': DateTime.now().toIso8601String()},
    );
  }

  Future<void> upsertTemplate(WhatsAppTemplate template) async {
    if (template.whatsappNumericId == null) {
      await _store.insert('whatsapp_templates', template.toJson());
      return;
    }
    final existing = await _store.maybeSingle(
      'whatsapp_templates',
      {'whatsapp_numeric_id': template.whatsappNumericId!},
    );
    if (existing != null) {
      final updateData = template.toJson();
      if (updateData['header_media_id'] == null && existing['header_media_id'] != null) {
        updateData['header_media_id'] = existing['header_media_id'];
      }
      await _store.update(
        'whatsapp_templates',
        eq: {'whatsapp_numeric_id': template.whatsappNumericId!},
        set: updateData,
      );
    } else {
      await _store.insert('whatsapp_templates', template.toJson());
    }
  }

  Future<List<WATemplateGroup>> getWATemplateGroups() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    final response = await _store.select(
      'wa_template_groups',
      eq: {'user_id': userId},
      order: 'id',
      ascending: false,
    );
    return response.map(WATemplateGroup.fromJson).toList();
  }

  Future<WATemplateGroup?> getWATemplateGroup(int id) async {
    final response = await _store.maybeSingle('wa_template_groups', {'id': '$id'});
    if (response == null) return null;
    return WATemplateGroup.fromJson(response);
  }

  Future<void> insertWATemplateGroup(WATemplateGroup group) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    await _store.insert('wa_template_groups', {
      'user_id': userId,
      'group_name': group.groupName,
      'group_contacts': group.groupContacts,
    });
  }

  Future<void> updateWATemplateGroup(int id, WATemplateGroup group) async {
    await _store.update(
      'wa_template_groups',
      eq: {'id': '$id'},
      set: {
        'group_name': group.groupName,
        'group_contacts': group.groupContacts,
      },
    );
  }

  Future<void> deleteWATemplateGroup(int id) async {
    await _store.delete('wa_template_groups', {'id': '$id'});
  }

  Future<Map<String, dynamic>> getGroupStats(int groupId) async {
    final group = await getWATemplateGroup(groupId);
    if (group == null) return {'exists': false};
    return {
      'exists': true,
      'name': group.groupName,
      'contact_count': group.groupContacts.length,
      'group_id': group.id,
    };
  }

  Future<void> addMultipleContacts(int groupId, List<Map<String, String>> newContacts) async {
    final group = await getWATemplateGroup(groupId);
    if (group == null) throw Exception('Group not found');
    await updateWATemplateGroup(
      groupId,
      WATemplateGroup(
        id: group.id,
        userId: group.userId,
        groupName: group.groupName,
        groupContacts: [...group.groupContacts, ...newContacts],
      ),
    );
  }

  Future<List<WATemplateGroup>> searchGroups(String searchTerm) async {
    final groups = await getWATemplateGroups();
    final q = searchTerm.toLowerCase();
    return groups.where((g) => g.groupName.toLowerCase().contains(q)).toList();
  }

  Future<List<Map<String, String>>> exportGroupContacts(int groupId) async {
    final group = await getWATemplateGroup(groupId);
    if (group == null) throw Exception('Group not found');
    return group.groupContacts;
  }

  Future<List<InternalTemplate>> getInternalTemplates() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];
    final response = await _store.select(
      'internal_templates',
      eq: {'user_id': userId},
      order: 'created_at',
      ascending: false,
    );
    return response.map(InternalTemplate.fromJson).toList();
  }

  Future<InternalTemplate?> getInternalTemplate(String id) async {
    final response = await _store.maybeSingle('internal_templates', {'id': id});
    if (response == null) return null;
    return InternalTemplate.fromJson(response);
  }

  Future<void> insertInternalTemplate(InternalTemplate template) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');
    final data = template.toJson();
    data['user_id'] = userId;
    await _store.insert('internal_templates', data);
  }

  Future<void> updateInternalTemplate(String id, InternalTemplate template) async {
    final data = template.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();
    await _store.update('internal_templates', eq: {'id': id}, set: data);
  }

  Future<void> deleteInternalTemplate(String id) async {
    await _store.delete('internal_templates', {'id': id});
  }
}
