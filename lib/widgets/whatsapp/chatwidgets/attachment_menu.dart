import 'package:flutter/material.dart';

class AttachmentMenu extends StatelessWidget {
  final bool showAttachmentMenu;
  final VoidCallback onPickGallery;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickVideo;
  final VoidCallback onRecordAudio;
  final VoidCallback onPickDocument;

  const AttachmentMenu({
    super.key,
    required this.showAttachmentMenu,
    required this.onPickGallery,
    required this.onTakePhoto,
    required this.onPickVideo,
    required this.onRecordAudio,
    required this.onPickDocument,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAttachmentMenu) return Container();

    return Positioned(
      bottom: 70,
      left: 16,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildAttachmentMenuItem(
              icon: Icons.photo_library,
              title: 'Gallery',
              color: Colors.green,
              onTap: onPickGallery,
            ),
            _buildAttachmentMenuItem(
              icon: Icons.camera_alt,
              title: 'Camera',
              color: Colors.blue,
              onTap: onTakePhoto,
            ),
            _buildAttachmentMenuItem(
              icon: Icons.videocam,
              title: 'Video',
              color: Colors.purple,
              onTap: onPickVideo,
            ),
            _buildAttachmentMenuItem(
              icon: Icons.audio_file,
              title: 'Audio',
              color: Colors.orange,
              onTap: onRecordAudio,
            ),
            _buildAttachmentMenuItem(
              icon: Icons.insert_drive_file,
              title: 'Document',
              color: Colors.red,
              onTap: onPickDocument,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}