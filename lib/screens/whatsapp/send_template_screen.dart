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
  String _loadingStatus = ''; // Shows "Uploading..." vs "Sending..."

  File? _selectedMedia;
  String _mediaUrlFallback =
      ''; // For when user pastes a link instead of picking a file

  @override
  void initState() {
    super.initState();
    // Create a text controller for every {{1}}, {{2}} variable the template needs
    for (int i = 0; i < widget.template.requiredBodyVariables; i++) {
      _variableControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _variableControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMedia(String format) async {
    FileType type = FileType.any;
    if (format == 'IMAGE') {
      type = FileType.image;
    } else if (format == 'VIDEO') {
      type = FileType.video;
    } else if (format == 'DOCUMENT') {
      type = FileType.custom;
    }

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

    setState(() {
      _isSending = true;
      _loadingStatus = 'Preparing...';
    });

    final header = widget.template.header;
    // Check if the template actually needs media
    String? mediaType =
        (header != null &&
            ['IMAGE', 'VIDEO', 'DOCUMENT'].contains(header.format))
        ? header.format
        : null;

    String? finalMediaLink;
    String? finalMediaId;

    try {
      // 1. Handle Media Upload if required
      if (mediaType != null) {
        if (_selectedMedia != null) {
          setState(() => _loadingStatus = 'Uploading media to WhatsApp...');

          // REAL UPLOAD: Sends file to Meta and gets a valid Media ID
          finalMediaId = await widget.apiService.uploadMediaForMessage(
            _selectedMedia!,
            mediaType,
          );
        } else if (_mediaUrlFallback.isNotEmpty) {
          // If they pasted a link, we use that
          finalMediaLink = _mediaUrlFallback;
        } else {
          // Fixed the accidentally commented-out exception
          throw Exception('Please select an image/video or paste a link.');
        }
      }

      // 2. Send the Message
      setState(() => _loadingStatus = 'Sending message...');

      final success = await widget.apiService.sendTemplateMessage(
        targetPhoneNumber: _phoneController.text,
        templateName: widget.template.name,
        languageCode: widget.template.language,
        headerMediaType: mediaType,
        mediaLink: finalMediaLink, // Used if URL pasted
        mediaId: finalMediaId, // Used if File picked (Priority)
        bodyVariables: _variableControllers.map((c) => c.text).toList(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message Sent Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to template list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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

    // Grab buttons if they exist
    final buttonsComponent = widget.template.components
        .where((c) => c.type == 'BUTTONS')
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Send: ${widget.template.name}'),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Phone Input ---
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Recipient Phone Number (e.g. 919876543210)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              helperText: 'Must include country code (e.g., 91 for India)',
            ),
          ),
          const SizedBox(height: 20),

          // --- Media Picker (Only shows if template needs it) ---
          if (requiresMedia) ...[
            Text(
              'Header Media ($headerFormat)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () => _pickMedia(headerFormat),
              child: Container(
                height: 160,
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedMedia!.path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
                            'Tap to select $headerFormat',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '— OR PASTE LINK —',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Public Media URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (val) => _mediaUrlFallback = val,
            ),
            const SizedBox(height: 20),
          ],

          // --- Variable Inputs (Only shows if template has {{1}}, etc) ---
          if (widget.template.requiredBodyVariables > 0) ...[
            const Text(
              'Message Variables',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.template.requiredBodyVariables, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextFormField(
                  controller: _variableControllers[index],
                  decoration: InputDecoration(
                    labelText: '{{${index + 1}}}',
                    hintText: 'Enter value for variable ${index + 1}',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // --- NEW: Included Buttons Visualizer ---
          if (buttonsComponent != null &&
              buttonsComponent.buttons.isNotEmpty) ...[
            const Text(
              'Included Buttons',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'These will be attached automatically by WhatsApp.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFDCF8C6,
                ).withOpacity(0.5), // Faint WhatsApp Green
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: buttonsComponent.buttons.map((btn) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          btn['type'] == 'URL'
                              ? Icons.open_in_new
                              : Icons.reply,
                          color: const Color(0xFF00A884),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          btn['text'] ?? 'Button',
                          style: const TextStyle(
                            color: Color(0xFF00A884),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- Send Button ---
          if (_isSending)
            Column(
              children: [
                const CircularProgressIndicator(color: Color(0xFF17A2B8)),
                const SizedBox(height: 12),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              label: const Text(
                'Send Message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
