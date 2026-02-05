import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool showPreview = true;
  bool groupMessages = false;
  String notificationTone = 'Default';
  TimeOfDay? quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay? quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  final List<String> tones = ['Default', 'Classic', 'Modern', 'Silent'];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Load notification preferences from SharedPreferences or Supabase
    // Current values will be default until loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF17A2B8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // General Notifications
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: pushNotifications,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        pushNotifications = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: emailNotifications,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        emailNotifications = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sound & Vibration
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sound & Vibration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Sound'),
                    subtitle: const Text('Play notification sounds'),
                    value: soundEnabled,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        soundEnabled = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notification Tone'),
                    subtitle: Text('Currently: $notificationTone'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showToneDialog,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate for notifications'),
                    value: vibrationEnabled,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        vibrationEnabled = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Message Notifications
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Message Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Show Preview'),
                    subtitle: const Text('Show message content in notifications'),
                    value: showPreview,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        showPreview = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Group Messages'),
                    subtitle: const Text('Group notifications from same contact'),
                    value: groupMessages,
                    activeThumbColor: const Color(0xFF17A2B8),
                    onChanged: (value) {
                      setState(() {
                        groupMessages = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quiet Hours
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Quiet Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(quietHoursStart?.format(context) ?? 'Not set'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(quietHoursEnd?.format(context) ?? 'Not set'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Tone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tones.map((tone) {
            return RadioListTile<String>(
              title: Text(tone),
              value: tone,
              // ignore: deprecated_member_use
              groupValue: notificationTone,
              activeColor: const Color(0xFF17A2B8),
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() {
                  notificationTone = value!;
                });
                Navigator.pop(context);
                _saveNotificationSettings();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0))
          : (quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          quietHoursStart = picked;
        } else {
          quietHoursEnd = picked;
        }
      });
      _saveNotificationSettings();
    }
  }

  void _saveNotificationSettings() {
    // Save notification preferences to SharedPreferences or Supabase
    // This will persist the user's notification settings
  }
}