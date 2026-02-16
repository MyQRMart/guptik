import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';


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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(content.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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