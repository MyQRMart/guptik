class ReelUtils {
  static String extractReelId(String postId, String? videoUrl) {
    // Instagram Reel IDs are usually the post ID itself
    // They typically start with 178, 179, 180, 181
    if (postId.startsWith('178') ||
        postId.startsWith('179') ||
        postId.startsWith('180') ||
        postId.startsWith('181')) {
      return postId;
    }

    // Try to extract from video URL if available
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
