import 'package:flutter/material.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/widgets/facebook/meta_grid_card.dart';
import 'create_post_screen.dart';
import 'fullscreen_media_screen.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final MetaService _metaService = MetaService();

  SocialPlatform _selectedPlatform = SocialPlatform.facebook;
  ContentType _selectedFilter = ContentType.post;

  // --- Helper: Build Filter Chips (Posts, Reels, Stories, Mentions) ---
  Widget _buildFilterChip(String label, ContentType type) {
    final isSelected = _selectedFilter == type;
    final primaryColor = _selectedPlatform == SocialPlatform.facebook
        ? const Color(0xFF1877F2)
        : const Color(0xFFE1306C);

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper: Build Platform Tabs (FB vs IG) ---
  Widget _buildTabBtn(String label, SocialPlatform platform) {
    final isSelected = _selectedPlatform == platform;
    final primaryColor = platform == SocialPlatform.facebook
        ? const Color(0xFF1877F2)
        : const Color(0xFFE1306C);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlatform = platform;
            _selectedFilter = ContentType
                .post; // Reset filter to 'Post' when switching platforms
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? primaryColor : Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. Header with Platform Toggle (FB / IG) and Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Platform Toggle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildTabBtn('Facebook', SocialPlatform.facebook),
                      _buildTabBtn('Instagram', SocialPlatform.instagram),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Posts", ContentType.post),
                      _buildFilterChip("Reels", ContentType.reel),
                      _buildFilterChip("Stories", ContentType.story),
                      _buildFilterChip("Mentions", ContentType.mention),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Main Content Grid
          Expanded(
            child: FutureBuilder<List<MetaContent>>(
              // Calling Service with selected filters
              future: _metaService.getContent(
                _selectedPlatform,
                _selectedFilter,
              ),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading content.\n${snapshot.error}"),
                  );
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_off, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          "No ${_selectedFilter.name}s found.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                // Grid View
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // ✅ NAVIGATION: Opens Full Screen Media (only if image exists)
                        if (posts[index].imageUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenMediaScreen(
                                imageUrl: posts[index].imageUrl,
                                caption: posts[index].caption,
                              ),
                            ),
                          );
                        }
                      },
                      child: MetaGridCard(content: posts[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // 4. Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: _selectedPlatform == SocialPlatform.facebook
            ? const Color(0xFF1877F2)
            : const Color(0xFFE1306C),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
      ),
    );
  }
}
