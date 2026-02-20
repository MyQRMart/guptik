import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/template_model.dart';
import 'package:guptik/screens/profilepopup/whatsapp_numbers_screen.dart';
import 'package:guptik/services/whatsapp/meta_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_template_screen.dart';
import 'send_template_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  MetaApiService? _apiService;
  Future<List<WhatsAppTemplate>>? _templatesFuture;

  bool _isLoadingSettings = true;
  bool _hasConfiguredKeys = false;

  @override
  void initState() {
    super.initState();
    _fetchUserSettingsAndTemplates();
  }

  Future<void> _fetchUserSettingsAndTemplates() async {
    setState(() => _isLoadingSettings = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _hasConfiguredKeys = false;
          _isLoadingSettings = false;
        });
        return;
      }

      _apiService = MetaApiService(
        accessToken: response['whatsapp_access_token'],
        businessAccountId: response['meta_business_account_id'],
        phoneNumberId: response['meta_wa_phone_number_id'],
        appId: response['meta_app_id'],
      );

      setState(() {
        _hasConfiguredKeys = true;
        _isLoadingSettings = false;
        _templatesFuture = _apiService!.fetchTemplates();
      });
    } catch (e) {
      setState(() => _isLoadingSettings = false);
    }
  }

  void _refreshTemplates() {
    if (_apiService != null) {
      setState(() => _templatesFuture = _apiService!.fetchTemplates());
    }
  }

  // --- NEW: WhatsApp-style Preview Dialog ---
  void _showTemplatePreview(BuildContext context, WhatsAppTemplate template) {
    final header = template.header;
    final body = template.body;
    // Find footer if it exists
    final footer = template.components
        .where((c) => c.type == 'FOOTER')
        .firstOrNull;
    final isApproved = template.status.toUpperCase() == 'APPROVED';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(
                0xFFE5DDD5,
              ), // Classic WhatsApp chat background color
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Template Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // The Chat Bubble
                Align(
                  alignment: Alignment
                      .centerRight, // Align to right like an outgoing message
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCF8C6), // WhatsApp Light Green Bubble
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(
                          0,
                        ), // Sharp corner for the 'tail'
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        if (header != null) ...[
                          if (header.format == 'TEXT')
                            Text(
                              header.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            )
                          else
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                header.format == 'IMAGE'
                                    ? Icons.image
                                    : header.format == 'VIDEO'
                                    ? Icons.videocam
                                    : Icons.insert_drive_file,
                                size: 48,
                                color: Colors.black38,
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],

                        // Body Section
                        if (body != null)
                          Text(
                            body.text,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),

                        // Footer Section
                        if (footer != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            footer.text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isApproved) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close preview
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SendTemplateScreen(
                                template: template,
                                apiService: _apiService!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text('Send Message'),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(template.status),
                        backgroundColor: Colors.orange.shade100,
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Trust me Templates'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_hasConfiguredKeys)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshTemplates,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _hasConfiguredKeys
          ? FloatingActionButton.extended(
              heroTag: 'templates_fab_unique_tag',
              onPressed: () async {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateTemplateScreen(apiService: _apiService!),
                  ),
                );
                if (shouldRefresh == true) _refreshTemplates();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoadingSettings)
      return const Center(child: CircularProgressIndicator());

    if (!_hasConfiguredKeys) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF17A2B8),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhatsAppNumbersScreen()),
            );
            _fetchUserSettingsAndTemplates();
          },
          child: const Text(
            'Configure API Settings First',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return FutureBuilder<List<WhatsAppTemplate>>(
      future: _templatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('No templates found.'));

        final templates = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            final isApproved = template.status.toUpperCase() == 'APPROVED';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                // NEW: Tapping the tile opens the preview!
                onTap: () => _showTemplatePreview(context, template),
                title: Text(
                  template.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${template.status} • ${template.language}'),
                trailing: isApproved
                    ? IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendTemplateScreen(
                              template: template,
                              apiService: _apiService!,
                            ),
                          ),
                        ),
                      )
                    : const Icon(Icons.hourglass_empty, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }
}
