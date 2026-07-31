import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapWebViewPage extends StatefulWidget {
  final Uri mapUri;
  final String title;

  const MapWebViewPage({
    super.key,
    required this.mapUri,
    required this.title,
  });

  @override
  State<MapWebViewPage> createState() => _MapWebViewPageState();
}

class _MapWebViewPageState extends State<MapWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ThemeData.light().colorScheme.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            debugPrint(
              'Map WebView error: code=${error.errorCode} '
              'mainFrame=${error.isForMainFrame}',
            );
          },
        ),
      )
      ..loadRequest(widget.mapUri);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }
}
