import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guptik/models/facebook/meta_content_model.dart'; // For SocialPlatform enum
import 'package:guptik/services/facebook/meta_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final MetaService _metaService = MetaService();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  SocialPlatform _selectedPlatform = SocialPlatform.facebook;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handlePost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Call the Service
    bool success = await _metaService.uploadPost(
      _selectedPlatform, 
      _selectedImage!, 
      _captionController.text
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Posted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload failed. Check console for details.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Post", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: (_selectedImage != null && !_isUploading) ? _handlePost : null,
            child: _isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text("Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Selector
            Row(
              children: [
                const Text("Post to: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Facebook"),
                  selected: _selectedPlatform == SocialPlatform.facebook,
                  onSelected: (val) => setState(() => _selectedPlatform = SocialPlatform.facebook),
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: _selectedPlatform == SocialPlatform.facebook ? Colors.blue : Colors.black),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Instagram"),
                  selected: _selectedPlatform == SocialPlatform.instagram,
                  onSelected: (val) => setState(() => _selectedPlatform = SocialPlatform.instagram),
                  selectedColor: Colors.pink.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: _selectedPlatform == SocialPlatform.instagram ? Colors.pink : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),

            // Image Picker Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          )
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Add Photo", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}