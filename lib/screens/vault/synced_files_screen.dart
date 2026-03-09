import 'package:flutter/material.dart';
import 'package:guptik/services/vault/sync_tracker.dart';
// Make sure this import path matches where your VaultSyncService is located!
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SyncedFilesScreen extends StatefulWidget {
  const SyncedFilesScreen({super.key});

  @override
  State<SyncedFilesScreen> createState() => _SyncedFilesScreenState();
}

class _SyncedFilesScreenState extends State<SyncedFilesScreen> {
  List<AssetEntity> _syncedAssets = [];
  bool _isLoading = true;
  final VaultSyncService _syncService =
      VaultSyncService(); // Instantiated your service!

  @override
  void initState() {
    super.initState();
    _loadSyncedAssets();
  }

  Future<void> _loadSyncedAssets() async {
    // 1. Get list of IDs we saved locally
    final List<String> syncedIds = await SyncTracker.getSyncedIds();

    if (syncedIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. ASK THE DESKTOP GATEWAY WHAT FILES IT ACTUALLY HAS
    bool serverCheckSuccess = false;
    List<String> serverFileNames = [];
    try {
      // DYNAMIC URL: Fetch the active desktop URL from Supabase for this specific user
      final String? baseUrl = await _syncService.getDesktopUrl();

      if (baseUrl != null) {
        print("Checking live files at: $baseUrl/vault/list");
        final response = await http.get(Uri.parse('$baseUrl/vault/list'));

        if (response.statusCode == 200) {
          final List<dynamic> serverFiles = jsonDecode(response.body);
          serverFileNames = serverFiles
              .map((f) => f['name'].toString())
              .toList();
          serverCheckSuccess = true;
        }
      } else {
        print("No desktop URL found. Skipping live verification.");
      }
    } catch (e) {
      print("Gateway offline, skipping live verification: $e");
    }

    // 3. Verify assets and build the UI list
    final List<AssetEntity> assets = [];

    for (String id in List.from(syncedIds)) {
      final asset = await AssetEntity.fromId(id);

      if (asset != null) {
        // If we successfully talked to the Gateway, let's verify!
        if (serverCheckSuccess) {
          final fileName = asset.title ?? 'unknown';

          if (!serverFileNames.contains(fileName)) {
            // THE GHOST BUSTER: Desktop deleted it, so we delete it from phone cache!
            print(
              '🗑️ $fileName is gone from desktop. Removing from mobile cache.',
            );
            await SyncTracker.removeSyncedId(id);
            continue; // Skip adding it to the UI
          }
        }
        assets.add(asset);
      } else {
        // The user deleted the photo from their phone's gallery!
        await SyncTracker.removeSyncedId(id);
      }
    }

    // 4. Update UI
    if (mounted) {
      setState(() {
        _syncedAssets = assets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Desktop Cloud", style: TextStyle(color: Colors.black)),
            Text(
              "Successfully Synced",
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSyncedAssets();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _syncedAssets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text(
                    "No files synced yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _syncedAssets.length,
              itemBuilder: (context, index) {
                return _SyncedTile(asset: _syncedAssets[index]);
              },
            ),
    );
  }
}

class _SyncedTile extends StatelessWidget {
  final AssetEntity asset;
  const _SyncedTile({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return Container(color: Colors.grey[100]);
          },
        ),
        const Positioned(
          bottom: 5,
          right: 5,
          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
        ),
      ],
    );
  }
}
