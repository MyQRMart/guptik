import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTemplateScreen extends StatefulWidget {
  final Map<String, dynamic>? template;

  const CreateTemplateScreen({super.key, this.template});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _headerController;
  late TextEditingController _bodyController;
  late TextEditingController _footerController;
  
  // Form values
  String _selectedCategory = 'Marketing';
  String _selectedLanguage = 'English';
  String _selectedTemplateType = 'Custom';
  String _selectedHeaderType = 'None';
  final String _status = 'DRAFT';
  
  // Button-related state
  bool _showButtonOptions = false;
  String _selectedButtonType = 'Quick Reply';
  List<Map<String, String>> _quickReplyButtons = [];
  List<Map<String, String>> _callToActionButtons = [];
  
  // Categories with descriptions
  final Map<String, Map<String, String>> _categories = {
    'Marketing': {
      'title': 'Marketing',
      'description': 'One-to-many bulk broadcast marketing messages',
      'icon': '📢'
    },
    'Utility': {
      'title': 'Utility',
      'description': 'Transactional messages that are sent on some user action',
      'icon': '🔧'
    },
    'Authentication': {
      'title': 'Authentication',
      'description': 'One time password messages for authentication',
      'icon': '🔐'
    },
  };
  
  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Arabic', 'Hindi'
  ];
  
  final List<String> _templateTypes = [
    'Custom', 'Standard', 'Quick Reply', 'Call to Action'
  ];
  
  final List<String> _headerTypes = [
    'None', 'Text', 'Image', 'Video', 'Document'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _headerController = TextEditingController();
    _bodyController = TextEditingController();
    _footerController = TextEditingController(text: 'Sent via MetaFly.com');
    
    if (widget.template != null) {
      _nameController.text = widget.template!['name'] ?? '';
      _bodyController.text = widget.template!['message'] ?? '';
      _selectedCategory = widget.template!['category'] ?? 'Marketing';
      
      // Load existing buttons if they exist
      if (widget.template!['buttons'] != null) {
        final buttonData = widget.template!['buttons'] as Map<String, dynamic>;
        _showButtonOptions = true;
        _selectedButtonType = buttonData['type'] == 'quick_reply' ? 'Quick Reply' : 'Call To Action';
        
        if (buttonData['type'] == 'quick_reply') {
          _quickReplyButtons = List<Map<String, String>>.from(
            (buttonData['buttons'] as List).map((button) => Map<String, String>.from(button))
          );
        } else if (buttonData['type'] == 'call_to_action') {
          _callToActionButtons = List<Map<String, String>>.from(
            (buttonData['buttons'] as List).map((button) => Map<String, String>.from(button))
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerController.dispose();
    _bodyController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'Add Message Template' : 'Edit Message Template',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use single column layout for mobile devices (width < 800)
          if (constraints.maxWidth < 800) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplateNameSection(),
                    const SizedBox(height: 24),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildLanguageAndTypeSection(),
                    const SizedBox(height: 24),
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildBodySection(),
                    const SizedBox(height: 24),
                    _buildFooterSection(),
                    const SizedBox(height: 24),
                    _buildButtonSection(),
                    const SizedBox(height: 24),
                    _buildActionsSection(),
                    const SizedBox(height: 100), // Extra space for bottom
                  ],
                ),
              ),
            );
          }
          
          // Use side-by-side layout for larger screens
          return Row(
            children: [
              // Main Form
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTemplateNameSection(),
                        const SizedBox(height: 32),
                        _buildCategorySection(),
                        const SizedBox(height: 32),
                        _buildLanguageAndTypeSection(),
                        const SizedBox(height: 32),
                        _buildHeaderSection(),
                        const SizedBox(height: 32),
                        _buildBodySection(),
                        const SizedBox(height: 32),
                        _buildFooterSection(),
                        const SizedBox(height: 32),
                        _buildButtonSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              // Sidebar - Actions and Preview
              Container(
                width: 400,
                color: Colors.white,
                child: Column(
                  children: [
                    _buildActionsSection(),
                    const Divider(height: 1),
                    Expanded(child: _buildPreviewSection()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TEMPLATE NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_nameController.text.length} / 512',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter template name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Template name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Spaces and special characters are not allowed.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _categories.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = entry.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.teal : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.teal.withValues(alpha: 0.05) : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSelected) 
                            const Icon(Icons.radio_button_checked, color: Colors.teal, size: 16)
                          else 
                            Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Text(entry.value['icon']!, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            entry.value['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.teal : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value['description']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select template category',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLanguageAndTypeSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LANGUAGE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _languages.map((language) {
                  return DropdownMenuItem(value: language, child: Text(language));
                }).toList(),
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select template language',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEMPLATE TYPE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTemplateType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _templateTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTemplateType = value!),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select template type',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Header (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add a title that you want to show in message header.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const Text(
          'HEADER TYPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedHeaderType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _headerTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _selectedHeaderType = value!),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the header type.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (_selectedHeaderType == 'Text') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _headerController,
            decoration: const InputDecoration(
              labelText: 'Header Text',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBodySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the text for your message in the language you\'ve selected.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'BODY CONTENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_bodyController.text.length} / 1024',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          maxLines: 6,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showVariableOptions,
                tooltip: 'Add Variables',
              ),
            ),
          ),
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Body content is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter body content. HTML not allowed. You can format the text using following shorthands:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _buildFormattingHelp(),
      ],
    );
  }

  Widget _buildFormattingHelp() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormatExample('Bold:', '*text* will become ', 'text', FontWeight.bold),
          _buildFormatExample('Italics:', '_text_ will become ', 'text', FontWeight.normal, isItalic: true),
          _buildFormatExample('Strikethrough:', '~text~ will become ', 'text', FontWeight.normal, isStrikethrough: true),
          _buildFormatExample('Monospace or code:', '```text``` will become ', 'text', FontWeight.normal, isMonospace: true),
        ],
      ),
    );
  }

  Widget _buildFormatExample(String label, String prefix, String text, FontWeight weight, {bool isItalic = false, bool isStrikethrough = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Text(prefix, style: const TextStyle(fontSize: 12)),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: weight,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Footer (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add a short line of text to the bottom of your message template.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'FOOTER TEXT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_footerController.text.length} / 60',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _footerController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => setState(() {}),
          maxLength: 60,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter footer text.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Button (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create buttons that let customers respond to your message or take action.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _showButtonOptions = !_showButtonOptions;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: _showButtonOptions ? Colors.teal[50] : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  _showButtonOptions ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add a button',
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(
                  _showButtonOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (_showButtonOptions) ...[
          const SizedBox(height: 16),
          _buildButtonTypeSelector(),
          const SizedBox(height: 16),
          _buildButtonConfiguration(),
        ],
      ],
    );
  }

  Widget _buildButtonTypeSelector() {
    final buttonTypes = [
      {
        'type': 'Quick Reply',
        'description': 'Custom (Max 10)',
        'icon': Icons.reply,
        'color': Colors.blue,
      },
      {
        'type': 'Call To Action',
        'description': 'Website, Phone & Offer buttons',
        'icon': Icons.touch_app,
        'color': Colors.green,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Button Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...buttonTypes.map((buttonType) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedButtonType = buttonType['type'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedButtonType == buttonType['type']
                    ? buttonType['color'] as Color
                    : Colors.grey[300]!,
                width: _selectedButtonType == buttonType['type'] ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedButtonType == buttonType['type']
                  ? (buttonType['color'] as Color).withValues(alpha: 0.1)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (buttonType['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    buttonType['icon'] as IconData,
                    color: buttonType['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buttonType['type'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buttonType['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (_selectedButtonType == buttonType['type'])
                  Icon(
                    Icons.check_circle,
                    color: buttonType['color'] as Color,
                  ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildButtonConfiguration() {
    if (_selectedButtonType == 'Quick Reply') {
      return _buildQuickReplyButtons();
    } else {
      return _buildCallToActionButtons();
    }
  }

  Widget _buildQuickReplyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Reply Buttons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_quickReplyButtons.length}/10',
              style: TextStyle(
                color: _quickReplyButtons.length >= 10 ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._quickReplyButtons.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String> button = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: button['text'],
                    decoration: const InputDecoration(
                      hintText: 'Button text (max 20 characters)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLength: 20,
                    onChanged: (value) {
                      setState(() {
                        _quickReplyButtons[index]['text'] = value;
                      });
                    },
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _quickReplyButtons.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          );
        }),
        if (_quickReplyButtons.length < 10)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _quickReplyButtons.add({'text': '', 'id': 'quick_reply_${_quickReplyButtons.length + 1}'});
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Quick Reply Button'),
          ),
      ],
    );
  }

  Widget _buildCallToActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call to Action Buttons',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        // Visit Website buttons
        _buildCallToActionSection(
          'Visit Website',
          'website',
          Icons.language,
          Colors.blue,
          2,
          'Website URL',
          'https://example.com',
        ),
        
        const SizedBox(height: 16),
        
        // Call Phone buttons
        _buildCallToActionSection(
          'Call Phone Number',
          'phone',
          Icons.phone,
          Colors.green,
          1,
          'Phone Number',
          '+1234567890',
        ),
        
        const SizedBox(height: 16),
        
        // Copy Offer Code buttons
        _buildCallToActionSection(
          'Copy Offer Code',
          'copy',
          Icons.content_copy,
          Colors.orange,
          1,
          'Offer Code',
          'SAVE20',
        ),
      ],
    );
  }

  Widget _buildCallToActionSection(
    String title,
    String type,
    IconData icon,
    Color color,
    int maxCount,
    String hintText,
    String placeholderValue,
  ) {
    List<Map<String, String>> buttons = _callToActionButtons
        .where((button) => button['type'] == type)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Max $maxCount)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${buttons.length}/$maxCount',
              style: TextStyle(
                color: buttons.length >= maxCount ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...buttons.asMap().entries.map((entry) {
          Map<String, String> button = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: button['text'],
                        decoration: const InputDecoration(
                          hintText: 'Button text (max 20 characters)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLength: 20,
                        onChanged: (value) {
                          setState(() {
                            int originalIndex = _callToActionButtons.indexWhere(
                              (b) => b['id'] == button['id'],
                            );
                            if (originalIndex != -1) {
                              _callToActionButtons[originalIndex]['text'] = value;
                            }
                          });
                        },
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _callToActionButtons.removeWhere((b) => b['id'] == button['id']);
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: button['value'],
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      int originalIndex = _callToActionButtons.indexWhere(
                        (b) => b['id'] == button['id'],
                      );
                      if (originalIndex != -1) {
                        _callToActionButtons[originalIndex]['value'] = value;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        if (buttons.length < maxCount)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _callToActionButtons.add({
                  'text': '',
                  'value': '',
                  'type': type,
                  'id': '${type}_${DateTime.now().millisecondsSinceEpoch}',
                });
              });
            },
            icon: Icon(Icons.add, color: color),
            label: Text('Add $title Button', style: TextStyle(color: color)),
          ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('Submit button tapped!');
                debugPrint('Template name: "${_nameController.text}"');
                debugPrint('Body text: "${_bodyController.text}"');
                debugPrint('Form valid: ${_formKey.currentState?.validate()}');
                _submitTemplate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit for Approval',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview message bubble
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedHeaderType != 'None' && _headerController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _headerController.text,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(
                          _bodyController.text.isEmpty ? 'Body text here' : _bodyController.text,
                          style: TextStyle(
                            color: _bodyController.text.isEmpty ? Colors.grey : Colors.black87,
                          ),
                        ),
                        if (_footerController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _footerController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        // Show button previews
                        if (_showButtonOptions && (_quickReplyButtons.isNotEmpty || _callToActionButtons.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildButtonPreviews(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sent via MetaFly.com',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonPreviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        if (_selectedButtonType == 'Quick Reply' && _quickReplyButtons.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._quickReplyButtons.where((button) => button['text']!.isNotEmpty).map((button) => 
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    button['text']!,
                    style: const TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_selectedButtonType == 'Call To Action' && _callToActionButtons.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._callToActionButtons.where((button) => button['text']!.isNotEmpty).map((button) {
            IconData icon;
            Color color;
            switch (button['type']) {
              case 'website':
                icon = Icons.language;
                color = Colors.blue;
                break;
              case 'phone':
                icon = Icons.phone;
                color = Colors.green;
                break;
              case 'copy':
                icon = Icons.content_copy;
                color = Colors.orange;
                break;
              default:
                icon = Icons.touch_app;
                color = Colors.grey;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    button['text']!,
                    style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showVariableOptions() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Variables'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('WhatsApp Business API Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildVariableOption('{{1}}', 'First parameter ($userName)'),
            _buildVariableOption('{{2}}', 'Second parameter (Meta Fly)'),
            _buildVariableOption('{{3}}', 'Third parameter (Current date)'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Named Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildVariableOption('{{name}}', 'User name ($userName)'),
            _buildVariableOption('{{company}}', 'Company name (Meta Fly)'),
            _buildVariableOption('{{date}}', 'Current date'),
            _buildVariableOption('{{time}}', 'Current time'),
            _buildVariableOption('{{phone}}', 'User phone'),
            _buildVariableOption('{{email}}', 'User email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableOption(String variable, String description) {
    return ListTile(
      title: Text(variable),
      subtitle: Text(description),
      onTap: () {
        final currentText = _bodyController.text;
        final currentPosition = _bodyController.selection.start;
        final newText = currentText.substring(0, currentPosition) + 
                       variable + 
                       currentText.substring(currentPosition);
        _bodyController.text = newText;
        _bodyController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition + variable.length),
        );
        Navigator.pop(context);
        setState(() {});
      },
    );
  }

  void _submitTemplate() {
    debugPrint('_submitTemplate called');
    
    if (_formKey.currentState!.validate()) {
      debugPrint('Form validation passed');
      
      // Prepare button data
      Map<String, dynamic> buttonData = {};
      
      if (_showButtonOptions) {
        if (_selectedButtonType == 'Quick Reply' && _quickReplyButtons.isNotEmpty) {
          buttonData['type'] = 'quick_reply';
          buttonData['buttons'] = _quickReplyButtons
              .where((button) => button['text']!.isNotEmpty)
              .toList();
        } else if (_selectedButtonType == 'Call To Action' && _callToActionButtons.isNotEmpty) {
          buttonData['type'] = 'call_to_action';
          buttonData['buttons'] = _callToActionButtons
              .where((button) => button['text']!.isNotEmpty && button['value']!.isNotEmpty)
              .toList();
        }
      }
      
      // Create template data
      Map<String, dynamic> templateData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'language': _selectedLanguage,
        'type': _selectedTemplateType,
        'headerType': _selectedHeaderType,
        'header': _headerController.text.trim(),
        'message': _bodyController.text.trim(),
        'footer': _footerController.text.trim(),
        'status': _status,
        'createdAt': DateTime.now().toIso8601String(),
        'usageCount': 0,
        'buttons': buttonData.isNotEmpty ? buttonData : null,
      };

      debugPrint('Template data prepared: $templateData');

      // Return the template data
      Navigator.pop(context, templateData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template submitted for approval successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (Template Name and Body Content)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}