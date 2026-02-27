import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/widgets/facebook/auto_reply_dialog.dart';

class MetaGridCard extends StatelessWidget {
  final MetaContent content;

  const MetaGridCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: Stack(
              children: [
                // -------------------------------------------------------------
                // ✅ FIXED: Replaced DecorationImage with Image.network + errorBuilder
                // -------------------------------------------------------------
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      content.imageUrl,
                      fit: BoxFit.cover,
                      // If the image fails to load, it shows this instead of crashing!
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                        );
                      },
                      // Adds a smooth loading spinner while the image downloads
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // -------------------------------------------------------------
                // NEW: Settings Button (Top-Left) - Only for Instagram
                // -------------------------------------------------------------
                if (content.platform == SocialPlatform.instagram)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        // Prevent the card tap from firing and open the dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              AutoReplyDialog(postId: content.id),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                // -------------------------------------------------------------
                // EXISTING: Platform Icon (Top-Right)
                // -------------------------------------------------------------
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      content.platform == SocialPlatform.facebook
                          ? FontAwesomeIcons.facebook
                          : FontAwesomeIcons.instagram,
                      size: 14,
                      color: content.platform == SocialPlatform.facebook
                          ? const Color(0xFF1877F2)
                          : const Color(0xFFE1306C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.caption,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${content.likes}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.comment, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${content.comments}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
