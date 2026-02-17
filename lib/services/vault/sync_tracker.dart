import 'package:shared_preferences/shared_preferences.dart';

class SyncTracker {
  static const String _key = 'synced_asset_ids';

  // Save an Asset ID as "Synced"
  static Future<void> markAsSynced(String assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> syncedIds = prefs.getStringList(_key) ?? [];
    
    if (!syncedIds.contains(assetId)) {
      syncedIds.add(assetId);
      await prefs.setStringList(_key, syncedIds);
    }
  }

  // Get list of ALL synced IDs
  static Future<List<String>> getSyncedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // Check if a specific photo is already synced
  static Future<bool> isSynced(String assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_key) ?? [];
    return ids.contains(assetId);
  }
}