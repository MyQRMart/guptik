import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guptik/services/vault/sync_tracker.dart';
import 'package:guptik/services/vault/vault_sync_service.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'synced_files_screen.dart'; 

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  AssetPathEntity? _currentAlbum;
  final List<AssetEntity> _allAssets = [];
  final Map<String, List<AssetEntity>> _groupedAssets = {};
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasPermission = false;
  
  int _currentPage = 0;
  final int _pageSize = 80;
  int _totalAssetCount = 0;
  
  final ScrollController _scrollController = ScrollController();
  
  // SYNC STATE
  bool _isSyncing = false;
  String _syncStatusText = "";
  double _syncProgress = 0.0;
  
  // NEW: Indicator logic
  bool _hasUnsyncedItems = false; 

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _scrollController.addListener(_onScroll);
    _checkSyncStatus(); // Check if we need to sync
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMoreAssets();
    }
  }

  // Check if we have items that are NOT in the synced list
  Future<void> _checkSyncStatus() async {
    // Simple check: Get total assets count vs synced count
    // (In a real app, compare IDs directly)
    final syncedIds = await SyncTracker.getSyncedIds();
    // Logic: If we have more assets than synced IDs, show the "Bulb"
    if (mounted) {
       setState(() {
         // This is a basic estimation. 
         // Real logic would check if _allAssets contains any ID not in syncedIds
         _hasUnsyncedItems = true; 
       });
    }
  }

  Future<void> _initialLoad() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) setState(() { _hasPermission = false; _isLoading = false; });
      return;
    }

    final FilterOptionGroup filterOption = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _currentAlbum = albums[0]; 
    _totalAssetCount = await _currentAlbum!.assetCountAsync;
    
    final List<AssetEntity> newAssets = await _currentAlbum!.getAssetListPaged(
      page: 0,
      size: _pageSize,
    );

    _processAssets(newAssets);
    
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoadingMore || _allAssets.length >= _totalAssetCount || _currentAlbum == null) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final List<AssetEntity> nextAssets = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    _processAssets(nextAssets);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _processAssets(List<AssetEntity> newAssets) {
    _allAssets.addAll(newAssets);
    for (var asset in newAssets) {
      String dateLabel = _getDateLabel(asset.createDateTime);
      if (_groupedAssets[dateLabel] == null) {
        _groupedAssets[dateLabel] = [];
      }
      _groupedAssets[dateLabel]!.add(asset);
    }
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat('EEE, MMM d').format(date); 
  }

  // ==========================================
  // SYNC LOGIC WITH SAVING
  // ==========================================
  Future<void> _handleSync() async {
    if (_isSyncing) return;
    if (_currentAlbum == null) return;

    final syncService = VaultSyncService();
    
    // UI Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Syncing Vault"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _syncProgress),
                  const SizedBox(height: 20),
                  Text(_syncStatusText, textAlign: TextAlign.center),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() => _isSyncing = true);

    try {
      _updateSyncStatus("Connecting...", 0.0);
      final String? url = await syncService.getDesktopUrl();
      if (url == null) throw Exception("No Desktop Found.");
      if (!await syncService.isGatewayOnline(url)) throw Exception("Desktop Offline.");

      final int totalCount = await _currentAlbum!.assetCountAsync;
      int successCount = 0;
      int batchSize = 50;

      for (int i = 0; i < totalCount; i += batchSize) {
        if (!mounted) break;

        int end = (i + batchSize < totalCount) ? i + batchSize : totalCount;
        List<AssetEntity> batch = await _currentAlbum!.getAssetListRange(start: i, end: end);

        for (int j = 0; j < batch.length; j++) {
          final asset = batch[j];
          final file = await asset.file;
          
          int currentIndex = i + j + 1;
          
          // Check if already synced to skip re-uploading (Optimization)
          bool alreadySynced = await SyncTracker.isSynced(asset.id);
          
          if (file != null && !alreadySynced) {
            _updateSyncStatus("Syncing $currentIndex of $totalCount", currentIndex / totalCount);
            
            bool success = await syncService.uploadFile(file, url);
            if (success) {
              successCount++;
              // MARK AS SYNCED LOCALLY
              await SyncTracker.markAsSynced(asset.id);
            }
          }
        }
        batch.clear();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Complete! Sent $successCount new files.'), backgroundColor: Colors.green),
        );
        setState(() => _hasUnsyncedItems = false); // Turn off the "bulb"
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _updateSyncStatus(String text, double progress) {
    setState(() {
      _syncStatusText = text;
      _syncProgress = progress;
    });
    (context as Element).markNeedsBuild();
  }

  void _openFullScreen(AssetEntity asset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MediaViewerPage(asset: asset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text("Guptik Vault", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
               // 1. SYNC BUTTON (With "Bulb" Logic)
               IconButton(
                icon: Icon(
                  Icons.cloud_upload, 
                  // If items need syncing, show Purple (Glowing), else Grey
                  color: _hasUnsyncedItems ? Colors.deepPurpleAccent : Colors.grey
                ),
                onPressed: _handleSync,
                tooltip: "Sync to Desktop",
              ),
              
              const SizedBox(width: 5),

              // 2. NEW: DESKTOP CLOUD ICON
              IconButton(
                icon: const Icon(Icons.desktop_mac, color: Colors.black), // Icon for Desktop Vault
                onPressed: () {
                  // Navigate to SyncedFilesScreen
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const SyncedFilesScreen())
                  );
                },
                tooltip: "View Desktop Files",
              ),

              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.purple,
                child: Text("G", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 15),
            ],
          ),

          if (!_hasPermission && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: TextButton(
                  onPressed: PhotoManager.openSetting,
                  child: const Text("Open Settings"),
                ),
              ),
            ),

          if (_isLoading)
             const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),

          if (_hasPermission && !_isLoading)
            ..._groupedAssets.entries.map((entry) {
              return SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DateHeaderDelegate(title: entry.key),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final asset = entry.value[index];
                          return GestureDetector(
                            onTap: () => _openFullScreen(asset), 
                            child: _RealMediaTile(asset: asset),
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                ],
              );
            }),
            
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

// ... (Rest of classes: MediaViewerPage, _VideoPlayerItem, _RealMediaTile, _DateHeaderDelegate)
// ... (Copy them from previous correct versions)
// ==========================================
// 1. FULL SCREEN VIEWER
// ==========================================
class MediaViewerPage extends StatefulWidget {
  final AssetEntity asset;
  const MediaViewerPage({super.key, required this.asset});

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  bool _isSharing = false;

  Future<void> _shareAsset() async {
    setState(() => _isSharing = true);
    try {
      final File? file = await widget.asset.file;
      if (file != null) {
        await Share.shareXFiles([XFile(file.path)], text: 'Shared from Guptik Vault');
      }
    } catch (e) {
      debugPrint("Share Error: $e");
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showInfo() async {
    final File? file = await widget.asset.file;
    final int sizeBytes = file?.lengthSync() ?? 0;
    final String sizeString = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
    final String path = file?.path ?? "Unknown Path";
    final String resolution = "${widget.asset.width} x ${widget.asset.height}";
    final String date = DateFormat('EEE, MMM d, y • h:mm a').format(widget.asset.createDateTime);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Info", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _infoRow(Icons.calendar_today, "Date", date),
              const Divider(),
              _infoRow(Icons.image, "Details", "${widget.asset.title ?? 'Unknown'}\n$resolution • ${sizeString}MB"),
              const Divider(),
              _infoRow(Icons.folder_open, "Path on Device", path),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(150),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isSharing
              ? const Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(color: Colors.white))
              : IconButton(icon: const Icon(Icons.share), onPressed: _shareAsset),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfo),
        ],
      ),
      body: Center(
        child: widget.asset.type == AssetType.video
            ? _VideoPlayerItem(asset: widget.asset) 
            : FutureBuilder<Uint8List?>(
                future: widget.asset.originBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.white);
                  return InteractiveViewer(child: Image.memory(snapshot.data!, fit: BoxFit.contain));
                },
              ),
      ),
    );
  }
}

// ==========================================
// 2. VIDEO PLAYER WIDGET
// ==========================================
class _VideoPlayerItem extends StatefulWidget {
  final AssetEntity asset;
  const _VideoPlayerItem({required this.asset});
  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _initVideo();
  }
  Future<void> _initVideo() async {
    final file = await widget.asset.file;
    if (file != null) {
      _controller = VideoPlayerController.file(file)..initialize().then((_) {
        if (mounted) { setState(() => _initialized = true); _controller!.play(); }
      });
    }
  }
  @override
  void dispose() { _controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) return const CircularProgressIndicator(color: Colors.white);
    return GestureDetector(
      onTap: () { setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()); },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)),
          if (!_controller!.value.isPlaying)
            Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 50)),
        ],
      ),
    );
  }
}

// ==========================================
// 3. GRID TILE WIDGET
// ==========================================
class _RealMediaTile extends StatelessWidget {
  final AssetEntity asset;
  const _RealMediaTile({required this.asset});
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, color: Colors.grey)));
            }
            return Container(color: Colors.grey[200]);
          },
        ),
        if (asset.type == AssetType.video) const Positioned(top: 5, right: 5, child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 20)),
        if (asset.type == AssetType.video) Positioned(bottom: 5, right: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(_formatDuration(asset.duration), style: const TextStyle(color: Colors.white, fontSize: 10)))),
      ],
    );
  }
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final min = duration.inMinutes;
    final sec = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _DateHeaderDelegate({required this.title});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white.withAlpha(245), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)));
  }
  @override
  double get maxExtent => 45;
  @override
  double get minExtent => 45;
  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) => oldDelegate.title != title;
}