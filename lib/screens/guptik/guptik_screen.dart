import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:guptik/services/guptik/mobile_ollama_service.dart';

class GuptikScreen extends StatefulWidget {
  final String tunnelUrl; // Pass this from Supabase when they click the icon

  const GuptikScreen({super.key, required this.tunnelUrl});

  @override
  State<GuptikScreen> createState() => _GuptikScreenState();
}

class _GuptikScreenState extends State<GuptikScreen> {
  late MobileOllamaService _ollamaService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  String _sessionId = const Uuid().v4();
  List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _sessions = []; // Stores history from desktop

  String _selectedModel = 'llama3'; // Default fallback
  List<String> _availableModels = [];

  bool _isLoading = false;
  bool _isLoadingHistory = false;

  // Colors for the ChatGPT vibe
  final Color bgDark = const Color(0xFF212121);
  final Color userBubble = const Color(0xFF2F2F2F);
  final Color aiBubble = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _ollamaService = MobileOllamaService(tunnelUrl: widget.tunnelUrl);
    _loadModels();
    _loadSessions(); // Fetch history on startup
  }

  // --- API ROUTE: Get Installed Models ---
  Future<void> _loadModels() async {
    final models = await _ollamaService.getInstalledModels();
    if (models.isNotEmpty && mounted) {
      setState(() {
        _availableModels = models;
        _selectedModel = models.first;
      });
    }
  }

  // --- API ROUTE: Load Chat Sessions for Sidebar ---
  Future<void> _loadSessions() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.tunnelUrl}/api/sessions'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      print("Error loading sessions: $e");
    }
  }

  // --- API ROUTE: Load Specific Chat History ---
  Future<void> _loadHistory(String sessionId) async {
    setState(() => _isLoadingHistory = true);

    try {
      final response = await http.get(
        Uri.parse('${widget.tunnelUrl}/api/history/$sessionId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sessionId = sessionId;
          _messages = data
              .map(
                (m) => {
                  'role': m['role'].toString(),
                  'content': m['content'].toString(),
                },
              )
              .toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // --- API ROUTE: Save Message to Desktop ---
  Future<void> _saveMessageToDesktop(String role, String content) async {
    try {
      await http.post(
        Uri.parse('${widget.tunnelUrl}/api/chat/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'role': role,
          'content': content,
          'model': _selectedModel,
        }),
      );
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  void _createNewChat() {
    setState(() {
      _sessionId = const Uuid().v4();
      _messages = [];
    });
    Navigator.pop(context); // Close the drawer
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    // 1. Add User Message to UI
    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "assistant", "content": ""}); // Placeholder
      _isLoading = true;
    });
    _scrollToBottom();

    // 2. Save User Message to Desktop DB
    await _saveMessageToDesktop('user', text);

    // Prepare history for API (excluding the empty placeholder)
    final apiHistory = _messages.sublist(0, _messages.length - 1);

    try {
      final stream = _ollamaService.generateChatStream(
        model: _selectedModel,
        history: apiHistory,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          _messages.last["content"] = _messages.last["content"]! + chunk;
        });
        _scrollToBottom();
      }

      // 3. Save Assistant Message to Desktop DB once streaming finishes
      await _saveMessageToDesktop('assistant', _messages.last["content"]!);

      // 4. Refresh the sidebar to show the new chat
      _loadSessions();
    } catch (e) {
      setState(() {
        _messages.last["content"] =
            "Connection error. Make sure your desktop tunnel is active.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      // 🛡️ The AppBar with the Hamburger Menu
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Hamburger icon color
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _availableModels.contains(_selectedModel)
                ? _selectedModel
                : null,
            dropdownColor: userBubble,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            items: _availableModels.map((model) {
              return DropdownMenuItem(value: model, child: Text(model));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedModel = val);
            },
            hint: const Text(
              "Select Model",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
        centerTitle: true,
      ),

      // 🛡️ The Slide-out Sidebar for Chat History
      drawer: Drawer(
        backgroundColor: bgDark,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _createNewChat,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "New Chat",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userBubble,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "History",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _sessions.isEmpty
                    ? const Center(
                        child: Text(
                          "No history yet.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final s = _sessions[index];
                          final isActive = s['id'] == _sessionId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            title: Text(
                              s['title'],
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: isActive,
                            selectedTileColor: userBubble.withOpacity(0.5),
                            onTap: () {
                              _loadHistory(s['id']);
                              Navigator.pop(context); // Close drawer
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg["role"] == "user";

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              const CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 16,
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser ? userBubble : aiBubble,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  msg["content"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgDark),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: userBubble,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: "Message Guptik...",
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: _isLoading ? Colors.grey : Colors.white,
                      radius: 22,
                      child: Icon(
                        _isLoading ? Icons.stop : Icons.arrow_upward,
                        color: Colors.black,
                      ),
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
}
