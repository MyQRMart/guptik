import 'package:flutter/material.dart';
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class SyncedFilesScreen extends StatefulWidget {
  const SyncedFilesScreen({super.key});

  @override
  State<SyncedFilesScreen> createState() => _SyncedFilesScreenState();
}

class _SyncedFilesScreenState extends State<SyncedFilesScreen> {
  List<AssetEntity> _syncedAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncedAssets();
  }

  Future<void> _loadSyncedAssets() async {
    // 1. Get list of IDs we saved
    final List<String> syncedIds = await SyncTracker.getSyncedIds();
    
    if (syncedIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. Ask PhotoManager to find these specific assets
    // We fetch them all at once (you can paginate if you have thousands)
    final List<AssetEntity> assets = [];
    
    for (String id in syncedIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        assets.add(asset);
      }
    }

    // 3. Update UI
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
            Text("Successfully Synced", style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
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
                    const Text("No files synced yet", style: TextStyle(color: Colors.grey)),
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
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return Container(color: Colors.grey[100]);
          },
        ),
        const Positioned(
          bottom: 5,
          right: 5,
          child: Icon(Icons.check_circle, color: Colors.green, size: 20),
        )
      ],
    );
  }
}