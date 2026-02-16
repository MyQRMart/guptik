import 'package:flutter/material.dart';
import 'package:guptik/models/vault/vault_media.dart';


class MediaTile extends StatelessWidget {
  final VaultMedia media;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaTile({
    super.key,
    required this.media,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Image/Thumbnail
          Image.network(
            media.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[800], child: const Icon(Icons.error));
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: Colors.grey[900]);
            },
          ),

          // 2. Video Indicator (If it's a video)
          if (media.type == MediaType.video)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
            
          // 3. Sync Status Indicator (Optional visual cue)
          if (!media.isSynced)
             Positioned(
              bottom: 4,
              right: 4,
              child: Icon(
                Icons.cloud_off,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}