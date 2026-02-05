import 'package:flutter/material.dart';
import 'package:guptik/screens/profilepopup/qr_scanner_screen.dart';

class WhatsAppWebScreen extends StatefulWidget {
  const WhatsAppWebScreen({super.key});

  @override
  State<WhatsAppWebScreen> createState() => _WhatsAppWebScreenState();
}

class _WhatsAppWebScreenState extends State<WhatsAppWebScreen> {
  bool isConnected = false;
  List<Map<String, dynamic>> activeSessions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Web', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF25D366),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh sessions
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Scanner Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open WhatsApp Web and scan the QR code to connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showQRScanner(context);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Open Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    'New Session',
                    Icons.add_circle_outline,
                    Colors.blue,
                    () {
                      _showQRScanner(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    'Disconnect All',
                    Icons.power_off,
                    Colors.red,
                    () {
                      _disconnectAllSessions();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Active Sessions
            const Text(
              'Active Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            activeSessions.isEmpty
                ? _buildEmptySessionsState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeSessions.length,
                    itemBuilder: (context, index) {
                      final session = activeSessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'How to Connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Open WhatsApp Web on your computer\n'
                    '2. Tap "Scan QR Code" above\n'
                    '3. Point your camera at the QR code\n'
                    '4. Wait for connection to establish',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    bool isActive = session['status'] == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.computer,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          session['device'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session['location']),
            Text(
              'Last active: ${session['lastActive']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session['status'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _disconnectSession(session);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRScanner(BuildContext context) async {
    // Navigate to the real QR scanner screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    // Handle the scanned result
    if (result != null) {
      _handleQRCodeScan(result);
    }
  }

  void _handleQRCodeScan(String qrData) {
    // Validate if it's a WhatsApp Web QR code
    if (qrData.contains('whatsapp.com') || qrData.contains('1@') || qrData.length > 50) {
      // Simulate successful connection
      setState(() {
        isConnected = true;
        activeSessions.insert(0, {
          'device': 'New Browser Session',
          'lastActive': 'Just now',
          'location': 'Current Device',
          'status': 'Active'
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully connected to WhatsApp Web!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Invalid QR code
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid WhatsApp Web QR code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnectSession(Map<String, dynamic> session) {
    setState(() {
      activeSessions.remove(session);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Disconnected from ${session['device']}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _disconnectAllSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect All Sessions'),
        content: const Text('Are you sure you want to disconnect all active WhatsApp Web sessions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                activeSessions.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All sessions disconnected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySessionsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.devices_other_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to WhatsApp Web to see your active sessions here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}