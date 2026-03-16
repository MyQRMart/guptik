class ReelUtils {
  // Extract reel ID from the post ID or video URL
  static String extractReelId(String postId, String? videoUrl) {
    // Instagram media IDs that start with 178 or 179 are usually reel IDs
    if (postId.startsWith('178') || postId.startsWith('179')) {
      return postId;
    }

    // Try to extract from video URL if it contains a reel ID
    if (videoUrl != null && videoUrl.contains('/reel/')) {
      final uri = Uri.tryParse(videoUrl);
      if (uri != null) {
        final segments = uri.pathSegments;
        final reelIndex = segments.indexOf('reel');
        if (reelIndex != -1 && reelIndex + 1 < segments.length) {
          return segments[reelIndex + 1].replaceAll('/', '');
        }
      }
    }

    // Return the post ID as fallback
    return postId;
  }

  // Check if a URL is a video
  static bool isVideoUrl(String url) {
    return url.contains('/reel/') ||
        url.contains('.mp4') ||
        url.contains('.mov');
  }

  // Generate Instagram embed URL
  static String getEmbedUrl(String reelId) {
    return 'https://www.instagram.com/reel/$reelId/embed';
  }

  // Generate Instagram direct URL
  static String getDirectUrl(String reelId) {
    return 'https://www.instagram.com/reel/$reelId/';
  }
}
