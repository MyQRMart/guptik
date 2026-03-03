import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/template.dart';

class PreviewTemplateScreen extends StatelessWidget {
  final WhatsAppTemplate template;

  const PreviewTemplateScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    // Determine header widget
    Widget headerWidget;
    if (template.headerMediaType == 'TEXT' && template.headerText != null) {
      headerWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.text_fields, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Header',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    template.headerText!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (template.headerMediaType == 'IMAGE') {
      headerWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.image, size: 40, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Image Header',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (template.headerMediaId != null)
                    Text(
                      'Media ID: ${template.headerMediaId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (template.headerMediaType == 'VIDEO') {
      headerWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.video_library, size: 40, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video Header',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (template.headerMediaId != null)
                    Text(
                      'Media ID: ${template.headerMediaId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (template.headerMediaType == 'DOCUMENT') {
      headerWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, size: 40, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Header',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (template.headerMediaId != null)
                    Text(
                      'Media ID: ${template.headerMediaId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      headerWidget = const SizedBox.shrink();
    }

    // Build body text with sample variables if available
    String bodyText = template.body;
    if (template.variables != null && template.variables!.isNotEmpty) {
      template.variables!.forEach((key, value) {
        bodyText = bodyText.replaceAll(key, value.toString());
      });
    }

    // Footer
    Widget footerWidget = template.footer != null && template.footer!.isNotEmpty
        ? Container(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              template.footer!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        : const SizedBox.shrink();

    // Buttons
    List<Widget> buttonWidgets = [];
    if (template.buttons != null) {
      for (var btn in template.buttons!) {
        String btnText = btn['text'] ?? '';
        if (btn['type'] == 'PHONE_NUMBER') {
          buttonWidgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(btnText, style: const TextStyle(color: Colors.teal)),
                ],
              ),
            ),
          );
        } else if (btn['type'] == 'URL') {
          buttonWidgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(btnText, style: const TextStyle(color: Colors.teal)),
                ],
              ),
            ),
          );
        } else if (btn['type'] == 'QUICK_REPLY') {
          buttonWidgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  btnText,
                  style: const TextStyle(color: Colors.teal),
                ),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${template.name}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                if (headerWidget is! SizedBox) ...[
                  const Text(
                    'HEADER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  headerWidget,
                  const Divider(height: 24),
                ],

                // Body section
                const Text(
                  'BODY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(bodyText, style: const TextStyle(fontSize: 14)),
                ),

                // Footer section
                if (footerWidget is! SizedBox) ...[
                  const Divider(height: 24),
                  const Text(
                    'FOOTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  footerWidget,
                ],

                // Buttons section
                if (buttonWidgets.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'BUTTONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...buttonWidgets,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
