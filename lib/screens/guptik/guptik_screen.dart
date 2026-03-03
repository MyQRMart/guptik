import 'package:flutter/material.dart';
import 'package:guptik/services/guptik/mobile_ollama_service.dart';

class GuptikScreen extends StatefulWidget {
  final String tunnelUrl; // Pass this from Supabase when they click the icon

  const GuptikScreen({Key? key, required this.tunnelUrl}) : super(key: key);

  @override
  State<GuptikScreen> createState() => _GuptikScreenState();
}

class _GuptikScreenState extends State<GuptikScreen> {
  late MobileOllamaService _ollamaService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  String _selectedModel = 'llama3'; // Default fallback
  List<String> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ollamaService = MobileOllamaService(tunnelUrl: widget.tunnelUrl);
    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await _ollamaService.getInstalledModels();
    if (models.isNotEmpty && mounted) {
      setState(() {
        _availableModels = models;
        _selectedModel = models.first;
      });
    }
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

    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({
        "role": "assistant",
        "content": "",
      }); // Empty placeholder for streaming
      _isLoading = true;
    });
    _scrollToBottom();

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
          // Append the chunk to the last message (the assistant's reply)
          _messages.last["content"] = _messages.last["content"]! + chunk;
        });
        _scrollToBottom();
      }
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
    // Colors for the ChatGPT vibe
    final bgDark = const Color(0xFF212121);
    final userBubble = const Color(0xFF2F2F2F);
    final aiBubble = Colors.transparent;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _availableModels.contains(_selectedModel)
                ? _selectedModel
                : null,
            dropdownColor: const Color(0xFF2F2F2F),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            decoration: BoxDecoration(
              color: bgDark,
              border: Border(
                top: BorderSide(color: Colors.grey.shade800, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F2F2F),
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
