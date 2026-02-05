import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class TemplateService {
  final SupabaseClient _client = Supabase.instance.client;

  // Logging utility
  void _log(String message, {String? error}) {
    if (error != null) {
      developer.log(message, name: 'TemplateService', error: error);
    } else {
      developer.log(message, name: 'TemplateService');
    }
  }

  // Get all templates for current user
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('message_templates')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _log('Error fetching templates', error: e.toString());
      return [];
    }
  }

  // Create new template
  Future<Map<String, dynamic>?> createTemplate(Map<String, dynamic> templateData) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Add user_id and timestamps
      templateData['user_id'] = user.id;
      templateData['created_at'] = DateTime.now().toIso8601String();
      templateData['updated_at'] = DateTime.now().toIso8601String();
      templateData['usage_count'] = 0;

      final response = await _client
          .from('message_templates')
          .insert(templateData)
          .select()
          .single();

      return response;
    } catch (e) {
      _log('Error creating template', error: e.toString());
      return null;
    }
  }

  // Update existing template
  Future<Map<String, dynamic>?> updateTemplate(String templateId, Map<String, dynamic> templateData) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      templateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('message_templates')
          .update(templateData)
          .eq('id', templateId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      _log('Error updating template', error: e.toString());
      return null;
    }
  }

  // Delete template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client
          .from('message_templates')
          .delete()
          .eq('id', templateId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      _log('Error deleting template', error: e.toString());
      return false;
    }
  }

  // Increment usage count
  Future<void> incrementUsageCount(String templateId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.rpc('increment_template_usage', params: {
        'template_id': templateId,
        'user_id': user.id,
      });
    } catch (e) {
      _log('Error incrementing usage count', error: e.toString());
    }
  }

  // Get favorite templates
  Future<List<Map<String, dynamic>>> getFavoriteTemplates() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('message_templates')
          .select()
          .eq('user_id', user.id)
          .eq('is_favorite', true)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _log('Error fetching favorite templates', error: e.toString());
      return [];
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String templateId, bool isFavorite) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('message_templates')
          .update({
            'is_favorite': !isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', templateId)
          .eq('user_id', user.id);
    } catch (e) {
      _log('Error toggling favorite', error: e.toString());
    }
  }

  // Get recent templates (most recently used)
  Future<List<Map<String, dynamic>>> getRecentTemplates({int limit = 5}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('message_templates')
          .select()
          .eq('user_id', user.id)
          .gt('usage_count', 0)
          .order('last_used_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _log('Error fetching recent templates', error: e.toString());
      return [];
    }
  }

  // Update last used timestamp
  Future<void> updateLastUsed(String templateId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('message_templates')
          .update({
            'last_used_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', templateId)
          .eq('user_id', user.id);
    } catch (e) {
      _log('Error updating last used', error: e.toString());
    }
  }

  // Remove duplicates based on name and content
  Future<void> removeDuplicateTemplates() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Get all templates for user
      final templates = await getTemplates();
      
      // Group by name and message content to find duplicates
      Map<String, List<Map<String, dynamic>>> groups = {};
      for (var template in templates) {
        String key = '${template['name']}_${template['message']}';
        if (groups[key] == null) {
          groups[key] = [];
        }
        groups[key]!.add(template);
      }

      // Remove duplicates (keep the most recent one)
      int duplicatesRemoved = 0;
      for (var group in groups.values) {
        if (group.length > 1) {
          // Sort by created_at to keep the newest
          group.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
          
          // Remove all except the first (newest)
          for (int i = 1; i < group.length; i++) {
            await deleteTemplate(group[i]['id'].toString());
            duplicatesRemoved++;
          }
        }
      }

      _log('Removed $duplicatesRemoved duplicate templates');
    } catch (e) {
      _log('Error removing duplicates', error: e.toString());
    }
  }
}