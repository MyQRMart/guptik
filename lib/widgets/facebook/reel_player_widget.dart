import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReelPlayerWidget extends StatefulWidget {
  final String reelId;
  final String? thumbnailUrl;

  const ReelPlayerWidget({super.key, required this.reelId, this.thumbnailUrl});

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final String htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body { margin:0; padding:0; background:black; }
    .container { width:100vw; height:100vh; display:flex; justify-content:center; align-items:center; }
    iframe { width:100%; height:100%; border:none; }
  </style>
</head>
<body>
  <div class="container">
    <iframe src="https://www.instagram.com/reel/${widget.reelId}/embed"
            allow="autoplay; fullscreen"
            allowfullscreen>
    </iframe>
  </div>
</body>
</html>
    ''';

    final String base64Html = base64Encode(
      const Utf8Encoder().convert(htmlContent),
    );
    final String dataUri = 'data:text/html;base64,$base64Html';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _hasError = true),
        ),
      )
      ..loadRequest(Uri.parse(dataUri));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.black,
            child: Center(
              child: widget.thumbnailUrl != null
                  ? Image.network(widget.thumbnailUrl!, fit: BoxFit.cover)
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        if (_hasError)
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Failed to load reel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
