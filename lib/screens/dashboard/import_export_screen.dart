import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:guptik/services/contacts/contact_sync_service.dart';
import 'package:guptik/services/contacts/device_contacts_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const Color _gold = Color(0xFFD4AF37);

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _device = DeviceContactsService();
  final _sync = ContactSyncService();
  int _count = 0;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _refreshCount();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refreshCount() async {
    if (!await _device.requestAccess()) {
      if (!mounted) return;
      setState(() => _status = 'Contacts permission needed.');
      return;
    }
    final all = await _device.loadAll();
    if (!mounted) return;
    setState(() {
      _count = all.length;
      _status = null;
    });
  }

  Future<void> _run(Future<String> Function() job) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final msg = await job();
      if (!mounted) return;
      setState(() => _status = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _refreshCount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _importFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['vcf', 'csv', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return 'Cancelled.';
    final f = picked.files.first;
    final bytes = f.bytes ?? (f.path == null ? null : await File(f.path!).readAsBytes());
    if (bytes == null) return 'Could not read file.';
    final text = String.fromCharCodes(bytes);
    final name = (f.name).toLowerCase();
    final n = name.endsWith('.csv') || text.contains(',') && !text.contains('BEGIN:VCARD')
        ? await _device.importCsv(text)
        : await _device.importVcf(text);
    return 'Imported $n contacts into the phone book.';
  }

  Future<String> _export(String kind) async {
    if (!await _device.requestAccess()) return 'Contacts permission needed.';
    final all = await _device.loadAll();
    final body = kind == 'vcf' ? await _device.exportVcf() : _device.toCsv(all);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/guptik-contacts.$kind');
    await file.writeAsString(body);
    await Share.shareXFiles([XFile(file.path)], text: 'GupTik contacts');
    return 'Shared ${all.length} contacts as $kind.';
  }

  Future<String> _syncNode() async {
    if (!await _device.requestAccess()) return 'Contacts permission needed.';
    final all = await _device.loadAll();
    final n = await _sync.pushToNode(all);
    return 'Synced $n contacts to the desktop node.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Import / Export', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: _gold),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _gold,
          labelColor: _gold,
          unselectedLabelColor: Colors.white54,
          dividerColor: _gold.withValues(alpha: 0.2),
          tabs: const [
            Tab(text: 'Import', icon: Icon(Icons.file_upload)),
            Tab(text: 'Export', icon: Icon(Icons.file_download)),
          ],
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DynamicAppBackground()),
          TabBarView(
            controller: _tabs,
            children: [
              _pane(
                icon: Icons.cloud_upload,
                title: 'Import contacts',
                subtitle: '$_count people currently on this phone.',
                buttons: [
                  _btn('From vCard / CSV file', Icons.attach_file, () => _run(_importFile)),
                  _btn('Reload phone book', Icons.smartphone, () => _run(() async {
                        await _refreshCount();
                        return 'Phone book has $_count contacts.';
                      })),
                  _btn('Sync phone → desktop', Icons.cloud_upload_outlined, () => _run(_syncNode)),
                ],
              ),
              _pane(
                icon: Icons.cloud_download,
                title: 'Export contacts',
                subtitle: 'Share the $_count contacts on this phone.',
                buttons: [
                  _btn('Export vCard (.vcf)', Icons.contacts, () => _run(() => _export('vcf'))),
                  _btn('Export CSV', Icons.table_chart, () => _run(() => _export('csv'))),
                  _btn('Sync phone → desktop', Icons.cloud_upload_outlined, () => _run(_syncNode)),
                ],
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator(color: _gold)),
            ),
        ],
      ),
    );
  }

  Widget _pane({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> buttons,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 140, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 48, color: _gold),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, style: const TextStyle(color: _gold, fontSize: 13), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...buttons,
      ],
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: _busy ? null : onTap,
        tileColor: Colors.black.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _gold.withValues(alpha: 0.3)),
        ),
        leading: Icon(icon, color: _gold),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      ),
    );
  }
}
