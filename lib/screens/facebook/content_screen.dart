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
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = type;
            });
          }
        },
        selectedColor: _selectedPlatform == SocialPlatform.facebook 
            ? const Color(0xFF1877F2).withValues(alpha: 0.2) 
            : const Color(0xFFE1306C).withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected 
              ? (_selectedPlatform == SocialPlatform.facebook ? const Color(0xFF1877F2) : const Color(0xFFE1306C)) 
              : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        // Removed the "isDisabled" logic so you can always click the buttons
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // --- Helper: Build Platform Tabs (FB vs IG) ---
  Widget _buildTabBtn(String label, SocialPlatform platform) {
    final isSelected = _selectedPlatform == platform;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlatform = platform;
            _selectedFilter = ContentType.post; // Reset filter to 'Post' when switching platforms
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (platform == SocialPlatform.facebook ? const Color(0xFF1877F2) : const Color(0xFFE1306C))
                    : Colors.grey[600],
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Platform Toggle (FB / IG)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  _buildTabBtn('Facebook', SocialPlatform.facebook),
                  _buildTabBtn('Instagram', SocialPlatform.instagram),
                ],
              ),
            ),
          ),

          // 2. Filter Chips (Now includes Mentions and all are clickable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip("Posts", ContentType.post),
                _buildFilterChip("Reels", ContentType.reel),
                _buildFilterChip("Stories", ContentType.story),
                _buildFilterChip("Mentions", ContentType.mention), // ✅ RESTORED
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Main Content Grid
          Expanded(
            child: FutureBuilder<List<MetaContent>>(
              // Calling Service with selected filters
              future: _metaService.getContent(_selectedPlatform, _selectedFilter),
              
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading content.\n${snapshot.error}"));
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 12, 
                    mainAxisSpacing: 12, 
                    childAspectRatio: 0.85,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // ✅ NAVIGATION: Opens Full Screen Media
                        Navigator.push(context, MaterialPageRoute(
                           builder: (context) => FullScreenMediaScreen(
                             imageUrl: posts[index].imageUrl,
                             caption: posts[index].caption,
                           ),
                        ));
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
        backgroundColor: _selectedPlatform == SocialPlatform.facebook ? const Color(0xFF1877F2) : const Color(0xFFE1306C),
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