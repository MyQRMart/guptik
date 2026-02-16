import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final Map<String, List<AssetEntity>> _groupedAssets = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  final String _desktopSyncUrl = "https://your-desktop-app-endpoint.com/api/sync";
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) setState(() { _hasPermission = false; _isLoading = false; });
      return;
    }

    final FilterOptionGroup filterOption = FilterOptionGroup(
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final List<AssetEntity> recentAssets = await albums[0].getAssetListRange(start: 0, end: 100);

    Map<String, List<AssetEntity>> tempGroup = {};
    for (var asset in recentAssets) {
      String dateLabel = _getDateLabel(asset.createDateTime);
      if (tempGroup[dateLabel] == null) tempGroup[dateLabel] = [];
      tempGroup[dateLabel]!.add(asset);
    }

    if (mounted) {
      setState(() {
        _hasPermission = true;
        _groupedAssets.clear();
        _groupedAssets.addAll(tempGroup);
        _isLoading = false;
      });
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

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      debugPrint("Syncing real assets to: $_desktopSyncUrl");
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synced to Desktop successfully!')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
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
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text("Guptik Vault", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
               IconButton(
                icon: _isSyncing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                onPressed: _isSyncing ? null : _handleSync,
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
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

// ==========================================
// 1. FULL SCREEN VIEWER (With Info Sheet)
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

  // --- SHOW INFO SHEET LOGIC ---
  void _showInfo() async {
    // Fetch file details asynchronously
    final File? file = await widget.asset.file;
    final int sizeBytes = file?.lengthSync() ?? 0;
    final String sizeString = (sizeBytes / (1024 * 1024)).toStringAsFixed(2); // Convert to MB
    final String path = file?.path ?? "Unknown Path";
    final String resolution = "${widget.asset.width} x ${widget.asset.height}";
    final String date = DateFormat('EEE, MMM d, y • h:mm a').format(widget.asset.createDateTime);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white, // White background for clean look
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Info",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Date & Time
              _infoRow(Icons.calendar_today, "Date", date),
              const Divider(),
              
              // File Name & Resolution
              _infoRow(Icons.image, "Details", "${widget.asset.title ?? 'Unknown'}\n$resolution • ${sizeString}MB"),
              const Divider(),
              
              // File Path
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
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(icon: const Icon(Icons.share), onPressed: _shareAsset),
          
          // INFO BUTTON
          IconButton(
            icon: const Icon(Icons.info_outline), 
            onPressed: _showInfo, // <--- Triggers the bottom sheet
          ),
        ],
      ),
      body: Center(
        child: widget.asset.type == AssetType.video
            ? _VideoPlayerItem(asset: widget.asset) 
            : FutureBuilder<Uint8List?>(
                future: widget.asset.originBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  return InteractiveViewer(
                    child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                  );
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
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller!.play(); 
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_controller!.value.isPlaying)
            Container(
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(50)),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
            ),
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
          future: asset.thumbnailDataWithSize(const ThumbnailSize.square(250)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover, gaplessPlayback: true);
            }
            return Container(color: Colors.grey[200]);
          },
        ),
        if (asset.type == AssetType.video)
          const Positioned(
            top: 5, right: 5,
            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 20),
          ),
        if (asset.type == AssetType.video)
          Positioned(
            bottom: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: Text(
                _formatDuration(asset.duration),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
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

// ==========================================
// 4. HEADER DELEGATE
// ==========================================
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  _DateHeaderDelegate({required this.title});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white.withAlpha(245),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  @override
  double get maxExtent => 45;
  @override
  double get minExtent => 45;
  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) => oldDelegate.title != title;
}