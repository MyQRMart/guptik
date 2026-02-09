import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_message.dart';
import 'package:guptik/services/whatsapp/wa_message_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class MediaContent extends StatefulWidget {
  final Message message;

  const MediaContent({super.key, required this.message});

  @override
  State<MediaContent> createState() => _MediaContentState();
}

class _MediaContentState extends State<MediaContent> {
  final MessageService _messageService = MessageService();
  String? _accessToken;
  bool _isLoadingToken = true;
  File? _downloadedFile;
  bool _isDownloading = false;

  // Video Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _loadAuth();
  }

  Future<void> _loadAuth() async {
    if (widget.message.isIncoming) {
      final token = await _messageService.getAccessToken();
      if (mounted) {
        setState(() {
          _accessToken = token;
          _isLoadingToken = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingToken = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.hasMedia) return Container();
    if (_isLoadingToken) return const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator()));

    final mediaUrl = widget.message.mediaUrl;
    final fileName = widget.message.fileName ?? 'Media_${DateTime.now().millisecondsSinceEpoch}';
    final mimeType = widget.message.mimeType ?? '';

    if (mediaUrl == null) return const Text("Media unavailable");

    if (widget.message.isImage) {
      return _buildImageContent(mediaUrl);
    } else if (widget.message.isVideo) {
      return _buildVideoContent(mediaUrl, fileName);
    } else if (widget.message.isAudio) {
      return _buildAudioContent(mediaUrl, fileName);
    } else if (widget.message.isDocument) {
      return _buildDocumentContent(mediaUrl, fileName, mimeType);
    }

    return Text('Unsupported media: $mimeType');
  }

  // ---------------- IMAGE ----------------
  Widget _buildImageContent(String url) {
    // If incoming, use headers. If outgoing (likely myqrmart/public), standard network image
    final Map<String, String>? headers = (widget.message.isIncoming && _accessToken != null)
        ? {'Authorization': 'Bearer $_accessToken'}
        : null;

    return GestureDetector(
      onTap: () {
        // Implement full screen view here if needed
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          url,
          headers: headers,
          width: 250,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 250,
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            // Fallback for "Raw Data" encoded urls that might expire or need refresh
            return Container(
              width: 250,
              height: 200,
              color: Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey),
                  SizedBox(height: 4),
                  Text("Image not found", style: TextStyle(fontSize: 10)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- VIDEO ----------------
  Widget _buildVideoContent(String url, String fileName) {
    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12.0)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else
            const Icon(Icons.videocam, size: 50, color: Colors.white),

          // Play/Download Button
          if (!_isDownloading)
            IconButton(
              icon: Icon(
                _videoController != null && _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40, 
                color: Colors.white
              ),
              onPressed: () => _handleVideoPlay(url, fileName),
            ),
          
          if (_isDownloading)
            const CircularProgressIndicator(color: Colors.white),
        ],
      ),
    );
  }

  Future<void> _handleVideoPlay(String url, String fileName) async {
    if (_videoController != null) {
      setState(() {
        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
      });
      return;
    }

    // Need to download first if authenticated
    if (widget.message.isIncoming && _accessToken != null) {
      setState(() => _isDownloading = true);
      final file = await _messageService.downloadAuthenticatedMedia(url, '$fileName.mp4');
      if (file != null && mounted) {
        _initializeVideoFromFile(file);
      }
      setState(() => _isDownloading = false);
    } else {
      // Outgoing/Public URL
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
            _videoController!.play();
          });
        });
    }
  }

  void _initializeVideoFromFile(File file) {
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController!.play();
        });
      });
  }

  // ---------------- AUDIO ----------------
  Widget _buildAudioContent(String url, String fileName) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12.0)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: Colors.green,
            iconSize: 40,
            onPressed: () => _handleAudioPlay(url, fileName),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isDownloading ? 'Downloading...' : 'Audio Message', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(fileName, style: TextStyle(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAudioPlay(String url, String fileName) async {
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
      return;
    }

    if (_downloadedFile != null) {
      await _audioPlayer.play(DeviceFileSource(_downloadedFile!.path));
      setState(() => _isPlayingAudio = true);
      return;
    }

    if (widget.message.isIncoming && _accessToken != null) {
      setState(() => _isDownloading = true);
      final file = await _messageService.downloadAuthenticatedMedia(url, '$fileName.mp3'); // Append ext if needed
      if (file != null && mounted) {
        _downloadedFile = file;
        await _audioPlayer.play(DeviceFileSource(file.path));
        setState(() => _isPlayingAudio = true);
      }
      setState(() => _isDownloading = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _isPlayingAudio = true);
    }
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  // ---------------- DOCUMENT ----------------
  Widget _buildDocumentContent(String url, String fileName, String mimeType) {
    return GestureDetector(
      onTap: () => _handleDocumentOpen(url, fileName),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.orange, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(mimeType.split('/').last.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            if (_isDownloading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.download, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDocumentOpen(String url, String fileName) async {
    if (widget.message.isIncoming && _accessToken != null) {
       setState(() => _isDownloading = true);
       final file = await _messageService.downloadAuthenticatedMedia(url, fileName);
       setState(() => _isDownloading = false);
       
       if (file != null) {
         // Use open_filex or similar package here. For now, we print path.
         debugPrint("File downloaded to: ${file.path}");
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File saved: ${file.path}")));
       }
    } else {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }
}