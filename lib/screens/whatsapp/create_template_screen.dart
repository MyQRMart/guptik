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
  final _formKey = GlobalKey<FormState>();
  final String _category = 'MARKETING';
  final String _language = 'en_US';

  String _name = '';
  String _headerFormat = 'NONE';
  String _headerText = '';
  String _bodyText = '';
  String _footerText = '';

  bool _isLoading = false;
  String _loadingStatus =
      ''; // Tells the user what is happening in the background
  int _variableCount = 0;

  File? _selectedMedia;

  void _onBodyTextChanged(String text) {
    setState(() {
      _bodyText = text;
      _variableCount = RegExp(r'\{\{(\d+)\}\}').allMatches(text).length;
    });
  }

  Future<void> _pickMedia() async {
    FileType type = FileType.any;
    if (_headerFormat == 'IMAGE') {
      type = FileType.image;
    } else if (_headerFormat == 'VIDEO') {
      type = FileType.video;
    } else if (_headerFormat == 'DOCUMENT') {
      type = FileType.custom;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: _headerFormat == 'DOCUMENT' ? ['pdf'] : null,
    );

    if (result != null) {
      setState(() {
        _selectedMedia = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    if (['IMAGE', 'VIDEO', 'DOCUMENT'].contains(_headerFormat) &&
        _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select media first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Processing...';
    });

    try {
      String generatedHandle = '';

      // Auto-upload media to get the handle if required
      if (_selectedMedia != null) {
        setState(() => _loadingStatus = 'Uploading media securely to Meta...');
        generatedHandle = await widget.apiService.uploadMediaToMeta(
          _selectedMedia!,
          _headerFormat,
        );
      }

      setState(() => _loadingStatus = 'Submitting template for approval...');

      List<String> mockVariables = List.generate(
        _variableCount,
        (index) => "SampleData${index + 1}",
      );

      final success = await widget.apiService.createTemplate(
        name: _name,
        category: _category,
        language: _language,
        headerFormat: _headerFormat,
        headerText: _headerText,
        headerHandle: generatedHandle, // Use the automatically generated handle
        bodyText: _bodyText,
        footerText: _footerText,
        bodyVariableExamples: mockVariables,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiresMedia = [
      'IMAGE',
      'VIDEO',
      'DOCUMENT',
    ].contains(_headerFormat);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust me Create Template'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Name (lowercase_only)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _headerFormat,
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
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                setState(() {
                  _headerFormat = v!;
                  _selectedMedia = null;
                });
              },
            ),

            if (_headerFormat == 'TEXT') ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Header Text',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _headerText = v ?? '',
              ),
            ],

            if (requiresMedia) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedMedia != null
                      ? _headerFormat == 'IMAGE'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedMedia!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  'Selected: ${_selectedMedia!.path.split('/').last}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _headerFormat == 'IMAGE'
                                  ? Icons.image
                                  : _headerFormat == 'VIDEO'
                                  ? Icons.videocam
                                  : Icons.insert_drive_file,
                              size: 48,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select $_headerFormat',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Body Text (Use {{1}} for variables)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onBodyTextChanged,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Footer Text (Optional)',
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _footerText = v ?? '',
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    _loadingStatus,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _submitTemplate,
                child: const Text(
                  'Submit to Meta',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
