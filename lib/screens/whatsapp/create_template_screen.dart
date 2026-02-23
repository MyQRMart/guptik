import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:guptik/services/whatsapp/meta_api_service.dart';

class CreateTemplateScreen extends StatefulWidget {
  final MetaApiService apiService;
  const CreateTemplateScreen({super.key, required this.apiService});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();
  final _footerController = TextEditingController();
  final _headerTextController = TextEditingController();

  String _selectedCategory = 'MARKETING';
  String _selectedLanguage = 'en_US';
  String _headerType = 'NONE';

  File? _selectedHeaderMedia;
  bool _isCreating = false;

  // NEW: List to store our buttons
  final List<Map<String, String>> _buttons = [];

  Future<void> _pickMedia() async {
    FileType type = FileType.any;
    if (_headerType == 'IMAGE')
      type = FileType.image;
    else if (_headerType == 'VIDEO')
      type = FileType.video;
    else if (_headerType == 'DOCUMENT')
      type = FileType.custom;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: _headerType == 'DOCUMENT' ? ['pdf'] : null,
    );

    if (result != null) {
      setState(() => _selectedHeaderMedia = File(result.files.single.path!));
    }
  }

  // NEW: Function to add a button to the list
  void _addButton(String type) {
    if (_buttons.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 buttons allowed')),
      );
      return;
    }
    setState(() {
      _buttons.add({'type': type, 'text': '', 'url': ''});
    });
  }

  Future<void> _submitTemplate() async {
    if (_nameController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Body are required')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      String headerHandle = '';
      if (['IMAGE', 'VIDEO', 'DOCUMENT'].contains(_headerType) &&
          _selectedHeaderMedia != null) {
        headerHandle = await widget.apiService.uploadMediaToMeta(
          _selectedHeaderMedia!,
          _headerType,
        );
      } else if (_headerType != 'NONE' &&
          _headerType != 'TEXT' &&
          _selectedHeaderMedia == null) {
        throw Exception('Please select a media file for the header');
      }

      // Automatically generate dummy examples for variables like {{1}}, {{2}}
      int variableCount = '{{'.allMatches(_bodyController.text).length;
      List<String> bodyVariables = List.generate(
        variableCount,
        (index) => 'DummyValue${index + 1}',
      );

      // Validate Buttons before sending
      for (var btn in _buttons) {
        if (btn['text']!.isEmpty) throw Exception('All buttons must have text');
        if (btn['type'] == 'URL' && btn['url']!.isEmpty)
          throw Exception('URL buttons must have a link');
      }

      await widget.apiService.createTemplate(
        name: _nameController.text,
        category: _selectedCategory,
        language: _selectedLanguage,
        headerFormat: _headerType,
        headerText: _headerTextController.text,
        headerHandle: headerHandle,
        bodyText: _bodyController.text,
        footerText: _footerController.text,
        bodyVariableExamples: bodyVariables,
        buttons: _buttons, // Pass our new buttons!
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trust me Template'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Basic Info ---
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name (lowercase, no spaces)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: [
              'MARKETING',
              'UTILITY',
              'AUTHENTICATION',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 16),

          // --- Header ---
          DropdownButtonFormField<String>(
            value: _headerType,
            decoration: const InputDecoration(
              labelText: 'Header Type',
              border: OutlineInputBorder(),
            ),
            items: [
              'NONE',
              'TEXT',
              'IMAGE',
              'VIDEO',
              'DOCUMENT',
            ].map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: (v) => setState(() {
              _headerType = v!;
              _selectedHeaderMedia = null;
            }),
          ),
          const SizedBox(height: 8),

          if (_headerType == 'TEXT')
            TextFormField(
              controller: _headerTextController,
              decoration: const InputDecoration(
                labelText: 'Header Text',
                border: OutlineInputBorder(),
              ),
            ),
          if (['IMAGE', 'VIDEO', 'DOCUMENT'].contains(_headerType))
            ElevatedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedHeaderMedia == null
                    ? 'Select $_headerType File'
                    : 'File Selected: ${_selectedHeaderMedia!.path.split('/').last}',
              ),
            ),
          const SizedBox(height: 16),

          // --- Body & Footer ---
          TextFormField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Body Text (Use {{1}}, {{2}} for variables)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _footerController,
            decoration: const InputDecoration(
              labelText: 'Footer Text (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // --- NEW: BUTTONS SECTION ---
          const Text(
            'Buttons (Optional)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buttons.asMap().entries.map((entry) {
            int index = entry.key;
            var btn = entry.value;
            return Card(
              color: Colors.grey[100],
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          btn['type'] == 'QUICK_REPLY'
                              ? 'Quick Reply Button'
                              : 'Visit Website Button',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _buttons.removeAt(index)),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: btn['text'],
                      decoration: const InputDecoration(
                        labelText: 'Button Text (e.g. "Yes", "Buy Now")',
                      ),
                      onChanged: (val) => btn['text'] = val,
                    ),
                    if (btn['type'] == 'URL')
                      TextFormField(
                        initialValue: btn['url'],
                        decoration: const InputDecoration(
                          labelText: 'Website URL (https://...)',
                        ),
                        onChanged: (val) => btn['url'] = val,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),

          if (_buttons.length < 3)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addButton('QUICK_REPLY'),
                    icon: const Icon(Icons.reply),
                    label: const Text('Add Quick Reply'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addButton('URL'),
                    icon: const Icon(Icons.link),
                    label: const Text('Add URL Button'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // --- Submit ---
          _isCreating
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _submitTemplate,
                  child: const Text(
                    'Create Template',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
