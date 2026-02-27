import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
// Models
import '../../models/home_control/home_model.dart';
import '../../services/home_control/home_control_services.dart';
import '../../providers/home_control/dynamic_theme_provider.dart';
import '../../widgets/home_control/home_control_widgets.dart';
import 'rooms_list_screen.dart';

class HomecontrolScreen extends StatelessWidget {
  const HomecontrolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the DynamicThemeProvider here
    return ChangeNotifierProvider(
      create: (_) => DynamicThemeProvider(),
      child: const HomeControlBody(),
    );
  }
}

class HomeControlBody extends StatefulWidget {
  const HomeControlBody({super.key});

  @override
  State<HomeControlBody> createState() => _HomeControlBodyState();
}

class _HomeControlBodyState extends State<HomeControlBody> {
  final _supabase = Supabase.instance.client;
  final _wallpaperService = LocalWallpaperService();
  final _homeService = HomeControlService();
  List<Home> _homes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // UPDATED QUERY: Fetch both boards and rooms to satisfy the Home model
      final response = await _supabase
          .from('hc_homes')
          .select('*, hc_boards(*), hc_rooms(*)')
          .eq('user_id', user.id);

      final homes = <Home>[];

      for (var data in response) {
        final home = Home.fromJson(data);
        final wallpaper = await _wallpaperService.getHomeWallpaper(home.id);

        // Reconstruct home with local wallpaper path
        // Note: We use the existing home data but add the local wallpaper path
        homes.add(
          Home(
            id: home.id,
            userId: home.userId,
            name: home.name,
            wallpaperPath: wallpaper,
            boards: home.boards,
            rooms: home.rooms,
          ),
        );
      }

      if (mounted)
        setState(() {
          _homes = homes;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading homes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addHome() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Home'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Home Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _homeService.createHome(name: controller.text.trim());
                  _loadHomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding home: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHome(Home home) async {
    // 1. Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Home?'),
        content: Text(
          'Are you sure you want to delete "${home.name}"?\n\nThis will delete all rooms and boards associated with this home. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 2. Perform delete in Supabase
      // Note: Ensure you have CASCADE delete set up in Supabase,
      // otherwise you might need to delete boards/rooms first manually.
      await _supabase.from('hc_homes').delete().eq('id', home.id);

      // 3. Remove wallpaper if exists
      // (Optional: Implement removal in _wallpaperService if needed)

      // 4. Update UI
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Home "${home.name}" deleted')));
        _loadHomes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting home: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setWallpaper(Home home) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _wallpaperService.setHomeWallpaper(
        homeId: home.id,
        sourcePath: image.path,
      );
      _loadHomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the provider here so we can pass it down later
    final theme = Provider.of<DynamicThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Homes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            // Updated to use the correct method name from DynamicThemeProvider
            onPressed: () => theme.updateDarkMode(!theme.isDarkMode),
          ),
        ],
      ),
      body: AnimatedSkyBackground(
        isDarkMode: theme.isDarkMode,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _homes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No homes yet',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addHome,
                      child: const Text('Create First Home'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: _homes.length,
                itemBuilder: (context, index) {
                  final home = _homes[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        image: home.wallpaperPath != null
                            ? DecorationImage(
                                image: FileImage(File(home.wallpaperPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: home.wallpaperPath == null
                            ? LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.purple.shade300,
                                ],
                              )
                            : null,
                      ),
                      child: InkWell(
                        // NAVIGATION FIX: Pass the existing provider to the next screen
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: theme,
                              child: RoomListScreen(
                                homeId: home.id,
                                homeName: home.name,
                              ),
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(color: Colors.black26),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Text(
                                home.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${home.rooms.length} Rooms',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '${home.boards.length} Boards',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (val) {
                                  if (val == 'wallpaper') _setWallpaper(home);
                                  if (val == 'delete') _deleteHome(home);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'wallpaper',
                                    child: Text('Set Wallpaper'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete Home',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHome,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
