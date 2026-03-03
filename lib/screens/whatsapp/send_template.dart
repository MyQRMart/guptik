import 'package:flutter/material.dart';
import 'package:guptik/services/whatsapp/wa_template_WhatsAppApiService.dart';
import 'package:guptik/utils/whastapp%20templates/helpers.dart';
import '../../models/whatsapp/template.dart';

class SendTemplateScreen extends StatefulWidget {
  final WhatsAppTemplate template;
  const SendTemplateScreen({super.key, required this.template});

  @override
  State<SendTemplateScreen> createState() => _SendTemplateScreenState();
}

class _SendTemplateScreenState extends State<SendTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final Map<String, TextEditingController> _varControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  final WhatsAppApiService _whatsapp = WhatsAppApiService();

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔍 Template headerMediaType: ${widget.template.headerMediaType}',
    );
    debugPrint('🔍 Template headerMediaId: ${widget.template.headerMediaId}');

    // Fixed: extractVariables is now imported from helpers.dart
    final vars = extractVariables(widget.template.body);
    for (var v in vars) {
      _varControllers[v] = TextEditingController();
      _focusNodes[v] = FocusNode();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _varControllers.values) {
      c.dispose();
    }
    for (var f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _applyFormatting(String varKey, String format) {
    final controller = _varControllers[varKey];
    if (controller == null) return;

    final text = controller.text;
    final selection = controller.selection;

    if (selection.isCollapsed) {
      final newText = _getFormattedPlaceholder(format);
      final newSelection = TextSelection.collapsed(
        offset: selection.start + newText.length,
      );
      controller.text =
          text.substring(0, selection.start) +
          newText +
          text.substring(selection.start);
      controller.selection = newSelection;
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final wrappedText = _wrapWithFormat(selectedText, format);

      final newText =
          text.substring(0, selection.start) +
          wrappedText +
          text.substring(selection.end);
      final newSelection = TextSelection.collapsed(
        offset: selection.start + wrappedText.length,
      );

      controller.text = newText;
      controller.selection = newSelection;
    }

    setState(() {});
  }

  String _getFormattedPlaceholder(String format) {
    switch (format) {
      case 'bold':
        return '*text*';
      case 'italic':
        return '_text_';
      case 'strikethrough':
        return '~text~';
      case 'monospace':
        return '`text`';
      default:
        return '';
    }
  }

  String _wrapWithFormat(String text, String format) {
    switch (format) {
      case 'bold':
        return '*$text*';
      case 'italic':
        return '_${text}_';
      case 'strikethrough':
        return '~$text~';
      case 'monospace':
        return '`$text`';
      default:
        return text;
    }
  }

  void _showFormattingHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Text Formatting Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Use these markers to format your text:'),
              const SizedBox(height: 12),
              _HelpRow(marker: '*text*', description: 'Bold text'),
              const SizedBox(height: 4),
              _HelpRow(marker: '_text_', description: 'Italic text'),
              const SizedBox(height: 4),
              _HelpRow(marker: '~text~', description: 'Strikethrough'),
              const SizedBox(height: 4),
              _HelpRow(marker: '`text`', description: 'Monospace/code'),
              const SizedBox(height: 12),
              const Text(
                'Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '*Dileep* → **Dileep**',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              Text(
                '_Dileep_ → *Dileep*',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can also combine:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '_*Dileep*_ → ***Dileep***',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final bodyVars = _varControllers.values.map((c) => c.text).toList();

      final rawPhone = _phoneController.text;
      final cleanPhone = rawPhone
          .replaceAll('+', '')
          .replaceAll(' ', '')
          .replaceAll('-', '');
      debugPrint('📞 Sending to (clean): $cleanPhone');

      String? mediaId = widget.template.headerMediaId;

      if (widget.template.headerMediaType == 'IMAGE' && mediaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No media ID available. Please recreate the template.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final List<Map<String, dynamic>> components = [];

      if (widget.template.headerMediaType != null &&
          widget.template.headerMediaType != 'NONE' &&
          mediaId != null) {
        components.add({
          'type': 'header',
          'parameters': [
            {
              'type': widget.template.headerMediaType!.toLowerCase(),
              widget.template.headerMediaType!.toLowerCase(): {'id': mediaId},
            },
          ],
        });
      }

      if (bodyVars.isNotEmpty) {
        components.add({
          'type': 'body',
          'parameters': bodyVars
              .map((val) => {'type': 'text', 'text': val})
              .toList(),
        });
      }

      await _whatsapp.sendTemplateMessage(
        to: cleanPhone,
        templateName: widget.template.name,
        languageCode: widget.template.language,
        components: components,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Message sent successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildFormatButton(String varKey, String format, IconData icon) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _applyFormatting(varKey, format),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(color: Colors.teal.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 18, color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send: ${widget.template.name}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showFormattingHelp,
            tooltip: 'Formatting Help',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Phone Number Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone, color: Colors.teal),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recipient Phone Number',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: '+919876543210',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Variables Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.abc,
                            color: Colors.orange,
                          ), // Fixed: Changed from Icons.variable to Icons.abc
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Variable Values',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill in the values for each variable',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    ..._varControllers.entries.map((entry) {
                      final varKey = entry.key;
                      final controller = entry.value;
                      final isFocused = _focusNodes[varKey]?.hasFocus ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  varKey,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller,
                                focusNode: _focusNodes[varKey],
                                maxLines: 3,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Enter value for $varKey',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  suffixIcon: isFocused
                                      ? PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.format_size,
                                            color: Colors.teal,
                                          ),
                                          tooltip: 'Formatting options',
                                          onSelected: (format) =>
                                              _applyFormatting(varKey, format),
                                          itemBuilder: (ctx) => const [
                                            PopupMenuItem(
                                              value: 'bold',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.format_bold,
                                                    color: Colors.black,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Bold'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'italic',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.format_italic,
                                                    color: Colors.black,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Italic'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'strikethrough',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.format_strikethrough,
                                                    color: Colors.black,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Strikethrough'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'monospace',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.code,
                                                    color: Colors.black,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Monospace'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),

                              if (isFocused) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildFormatButton(
                                      varKey,
                                      'bold',
                                      Icons.format_bold,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFormatButton(
                                      varKey,
                                      'italic',
                                      Icons.format_italic,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFormatButton(
                                      varKey,
                                      'strikethrough',
                                      Icons.format_strikethrough,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFormatButton(
                                      varKey,
                                      'monospace',
                                      Icons.code,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Send Button
            Container(
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String marker;
  final String description;
  const _HelpRow({required this.marker, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              marker,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 8),
          Text(description),
        ],
      ),
    );
  }
}
