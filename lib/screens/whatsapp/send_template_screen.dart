import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:guptik/models/whatsapp/template_model.dart';
import 'package:guptik/services/whatsapp/meta_api_service.dart';

class SendTemplateScreen extends StatefulWidget {
  final WhatsAppTemplate template;
  final MetaApiService apiService;
  const SendTemplateScreen({
    super.key,
    required this.template,
    required this.apiService,
  });

  @override
  State<SendTemplateScreen> createState() => _SendTemplateScreenState();
}

class _SendTemplateScreenState extends State<SendTemplateScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _variableControllers = [];
  bool _isSending = false;

  File? _selectedMedia;
  String _mediaUrlFallback =
      ''; // In case they prefer pasting a link instead of picking a file

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.template.requiredBodyVariables; i++) {
      _variableControllers.add(TextEditingController());
    }
  }

  Future<void> _pickMedia(String format) async {
    FileType type = FileType.any;
    if (format == 'IMAGE')
      type = FileType.image;
    else if (format == 'VIDEO')
      type = FileType.video;
    else if (format == 'DOCUMENT')
      type = FileType.custom;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: format == 'DOCUMENT' ? ['pdf'] : null,
    );

    if (result != null) {
      setState(() => _selectedMedia = File(result.files.single.path!));
    }
  }

  Future<void> _sendMessage() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    setState(() => _isSending = true);
    final header = widget.template.header;
    String? mediaType =
        (header != null &&
            ['IMAGE', 'VIDEO', 'DOCUMENT'].contains(header.format))
        ? header.format
        : null;

    // Logic to determine the media link to send
    String? finalMediaLink;
    if (mediaType != null) {
      if (_selectedMedia != null) {
        // TODO: Upload _selectedMedia to Supabase Storage here and get the URL
        // finalMediaLink = await SupabaseStorageService.upload(_selectedMedia!);
        finalMediaLink =
            'https://dummyimage.com/600x400/000/fff'; // Temporary placeholder
      } else if (_mediaUrlFallback.isNotEmpty) {
        finalMediaLink = _mediaUrlFallback;
      }
    }

    try {
      final success = await widget.apiService.sendTemplateMessage(
        targetPhoneNumber: _phoneController.text,
        templateName: widget.template.name,
        languageCode: widget.template.language,
        headerMediaType: mediaType,
        mediaLink: finalMediaLink,
        bodyVariables: _variableControllers.map((c) => c.text).toList(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message Sent Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerFormat = widget.template.header?.format;
    final requiresMedia =
        headerFormat != null &&
        ['IMAGE', 'VIDEO', 'DOCUMENT'].contains(headerFormat);

    return Scaffold(
      appBar: AppBar(
        title: Text('Send: ${widget.template.name}'),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Recipient Phone Number (e.g. 919876543210)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 20),

          if (requiresMedia) ...[
            Text(
              'Requires $headerFormat',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickMedia(headerFormat),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _selectedMedia != null
                    ? headerFormat == 'IMAGE'
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
                                  color: Colors.blue,
                                ),
                              ),
                            )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            headerFormat == 'IMAGE'
                                ? Icons.image
                                : headerFormat == 'VIDEO'
                                ? Icons.videocam
                                : Icons.insert_drive_file,
                            size: 40,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select $headerFormat from device',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Paste Public URL instead',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (val) => _mediaUrlFallback = val,
            ),
            const SizedBox(height: 20),
          ],

          if (widget.template.requiredBodyVariables > 0) ...[
            const Text(
              'Variables',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.template.requiredBodyVariables, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextFormField(
                  controller: _variableControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Value for {{${index + 1}}}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _isSending ? null : _sendMessage,
            child: _isSending
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send Message', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
