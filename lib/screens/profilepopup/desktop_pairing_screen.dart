import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/profilepopup/qr_scanner_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DesktopPairingScreen extends StatefulWidget {
  const DesktopPairingScreen({super.key});

  @override
  State<DesktopPairingScreen> createState() => _DesktopPairingScreenState();
}

class _DesktopPairingScreenState extends State<DesktopPairingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  Future<void> _checkExistingConnection() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('desktop_devices')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      setState(() {
        _connectedDevice = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error checking connection: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleQRScan() async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(result);
        await _saveDeviceToSupabase(data);
      } catch (e) {
        _showSnackBar("Invalid QR Code format", Colors.red);
      }
    }
  }

  Future<void> _saveDeviceToSupabase(Map<String, dynamic> deviceData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('desktop_devices').upsert({
        'user_id': userId,
        'device_id': deviceData['device_id'],
        'device_model': deviceData['model'],
        'is_verified': true,
        'installation_status': 'completed',
        'last_active_at': DateTime.now().toIso8601String(),
      });

      _showSnackBar("Device paired successfully!", Colors.green);
      _checkExistingConnection();
    } catch (e) {
      _showSnackBar("Failed to pair device: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _generateUserUrl() {
    final uid = _supabase.auth.currentUser?.id ?? "";
    final reversedUid = uid.split('').reversed.join('');
    final deviceId = _connectedDevice?['device_id'] ?? "unknown";
    return "MyQRMart.com/guptik/users/$reversedUid/$deviceId";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Connection'),
        backgroundColor: const Color(0xFF17A2B8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _connectedDevice == null ? _buildScannerPrompt() : _buildConnectedView(),
      ),
    );
  }

  Widget _buildScannerPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.desktop_windows, size: 100, color: Colors.grey),
        const SizedBox(height: 24),
        const Text(
          "No Desktop Device Paired",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Open the GupTik Desktop App and scan the QR code to sync your server settings.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _handleQRScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text("Scan Desktop QR"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    final url = _generateUserUrl();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text("Connected to ${_connectedDevice?['device_model']}"),
            subtitle: Text("ID: ${_connectedDevice?['device_id']}"),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "Your Unique Server URL:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  _showSnackBar("URL copied to clipboard", Colors.blue);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}