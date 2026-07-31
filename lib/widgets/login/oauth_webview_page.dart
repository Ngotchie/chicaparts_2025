import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OAuthWebViewPage extends StatefulWidget {
  const OAuthWebViewPage({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  final String initialUrl;
  final String title;

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: (request) {
            if (_handleCallback(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _handleCallback(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  bool _handleCallback(String url) {
    if (_completed || !url.startsWith('chicbooking://oauth/callback')) {
      return false;
    }

    _completed = true;
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    final token = uri.queryParameters['token'];
    final error = uri.queryParameters['error'];

    if (status == 'success' && token != null && token.isNotEmpty) {
      Navigator.pop(context, token);
    } else {
      Navigator.pop(context, OAuthWebViewError(error ?? 'OAuth failed'));
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

class OAuthWebViewError {
  final String message;

  const OAuthWebViewError(this.message);
}
