import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/app_config.dart';

/// Full-screen viewer for a hosted legal document (Terms, Privacy Policy).
///
/// Kept in-app rather than handed off to an external browser so the user never
/// loses their place in the sign-up form while reading.
class LegalViewerPage extends StatefulWidget {
  final String title;
  final String url;

  const LegalViewerPage({
    super.key,
    required this.title,
    required this.url,
  });

  /// Convenience constructors so call sites don't repeat the URLs.
  factory LegalViewerPage.terms() => const LegalViewerPage(
        title: 'Terms & Conditions',
        url: AppConfig.termsUrl,
      );

  factory LegalViewerPage.privacy() => const LegalViewerPage(
        title: 'Privacy Policy',
        url: AppConfig.privacyUrl,
      );

  @override
  State<LegalViewerPage> createState() => _LegalViewerPageState();
}

class _LegalViewerPageState extends State<LegalViewerPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (!AppConfig.isConfigured) {
      _loading = false;
      _error = 'Documents are not published yet.\n\n'
          'Set AppConfig.siteBaseUrl to your Hostinger domain and rebuild.';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (e) {
            // Subframe/favicon failures shouldn't blank out a page that loaded.
            if (e.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'Could not load the document.\n\n'
                    'Check your internet connection and try again.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF3E729F),
        foregroundColor: Colors.white,
      ),
      body: _error != null ? _buildError() : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF3E729F)),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (AppConfig.isConfigured) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E729F),
                  foregroundColor: Colors.white,
                ),
                onPressed: _retry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
