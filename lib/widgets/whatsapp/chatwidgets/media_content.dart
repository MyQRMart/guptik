import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_message.dart';

class MediaContent extends StatelessWidget {
  final Message message;

  const MediaContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (!message.hasMedia) return Container();
    
    final mediaUrl = message.mediaUrl;
    final mimeType = message.mimeType ?? '';
    final fileName = message.fileName ?? 'Media';
    
    if (message.isImage) {
      return _buildImageContent(mediaUrl, fileName);
    } else if (message.isVideo) {
      return _buildVideoContent(mediaUrl, fileName);
    } else if (message.isAudio) {
      return _buildAudioContent(mediaUrl, fileName);
    } else if (message.isDocument) {
      return _buildDocumentContent(mediaUrl, fileName, mimeType);
    }
    
    return Container();
  }

  Widget _buildImageContent(String? mediaUrl, String fileName) {
    if (mediaUrl == null) return Container();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Image.network(
        mediaUrl,
        width: 250,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 250,
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 250,
            height: 200,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Image\nFailed to load',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoContent(String? mediaUrl, String fileName) {
    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Video',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(String? mediaUrl, String fileName) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.audio_file, size: 40, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Message',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_filled, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(String? mediaUrl, String fileName, String mimeType) {
    IconData icon;
    Color iconColor;
    
    if (mimeType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (mimeType.contains('word') || mimeType.contains('doc')) {
      icon = Icons.description;
      iconColor = Colors.blue;
    } else if (mimeType.contains('excel') || mimeType.contains('sheet')) {
      icon = Icons.table_chart;
      iconColor = Colors.green;
    } else if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      icon = Icons.slideshow;
      iconColor = Colors.orange;
    } else if (mimeType.contains('text')) {
      icon = Icons.text_fields;
      iconColor = Colors.grey;
    } else if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('archive')) {
      icon = Icons.archive;
      iconColor = Colors.purple;
    } else {
      icon = Icons.insert_drive_file;
      iconColor = Colors.orange;
    }
    
    final fileSize = message.fileSize;
    final sizeText = fileSize != null && fileSize.isNotEmpty
        ? '${(int.tryParse(fileSize) ?? 0) / 1024} KB'
        : '';
    
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (sizeText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sizeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.download, color: Colors.blue),
        ],
      ),
    );
  }
}