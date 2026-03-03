import 'package:flutter/material.dart';
import 'package:guptik/models/whatsapp/wa_template_group.dart';
import 'package:guptik/services/whatsapp/wa_template_service.dart';

class GroupFormScreen extends StatefulWidget {
  final WATemplateGroup? group;
  const GroupFormScreen({super.key, this.group});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<Map<String, String>> _contacts = [];

  final SupabaseService _supabase = SupabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _groupNameController.text = widget.group!.groupName;
      _contacts.addAll(widget.group!.groupContacts);
    } else {
      _addContact();
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add({'name': '', 'number': ''});
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('+')) {
      return 'Number should start with + and country code';
    }
    if (value.length < 10) {
      return 'Enter a valid number';
    }
    return null;
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final validContacts = _contacts
        .where((c) => c['name']!.isNotEmpty && c['number']!.isNotEmpty)
        .map((c) => {'name': c['name']!, 'number': c['number']!})
        .toList();

    if (validContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one contact with name and number'),
        ),
      );
      return;
    }

    final userId = _supabase.getCurrentUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create groups'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final group = WATemplateGroup(
      id: widget.group?.id ?? 0,
      userId: userId,
      groupName: _groupNameController.text,
      groupContacts: validContacts,
    );

    try {
      if (widget.group == null) {
        await _supabase.insertWATemplateGroup(group);
      } else {
        await _supabase.updateWATemplateGroup(widget.group!.id, group);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group == null ? 'Create New Group' : 'Edit Group'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Name
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
                          child: const Icon(Icons.group, color: Colors.teal),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Group Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Marketing Team, VIP Customers',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Group name is required' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contacts Header
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Icons.contacts,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Contacts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addContact,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add contacts with their WhatsApp numbers',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Contact List
            ..._contacts.asMap().entries.map((entry) {
              final index = entry.key;
              final contact = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: contact['name'],
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'John Doe',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.teal,
                                ),
                              ),
                              onChanged: (val) => contact['name'] = val,
                              validator: (val) {
                                if (contact['number']!.isNotEmpty &&
                                    val!.isEmpty) {
                                  return 'Name required if number is entered';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _contacts.length > 1
                                ? () => _removeContact(index)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: contact['number'],
                        decoration: InputDecoration(
                          labelText: 'WhatsApp Number',
                          hintText: '+919876543210',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.teal,
                          ),
                        ),
                        onChanged: (val) => contact['number'] = val,
                        validator: (val) {
                          if (contact['name']!.isNotEmpty && val!.isEmpty) {
                            return 'Number required if name is entered';
                          }
                          return _validateNumber(val);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Save Button
            Container(
              width: double.infinity,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _saveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  widget.group == null ? 'Create Group' : 'Update Group',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
