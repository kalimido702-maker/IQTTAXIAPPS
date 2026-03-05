import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';
import 'iq_app_bar.dart';

/// A reusable in-app page that fetches HTML content from an API endpoint
/// and renders it inside a WebView.
///
/// The API is expected to return JSON: `{"success": true, "data": "<html>..."}`
///
/// Used for terms & conditions, privacy policy, instructions, etc.
class IqWebViewPage extends StatefulWidget {
  const IqWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  /// AppBar title.
  final String title;

  /// The API URL that returns JSON with an HTML `data` field.
  final String url;

  @override
  State<IqWebViewPage> createState() => _IqWebViewPageState();
}

class _IqWebViewPageState extends State<IqWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    _fetchAndLoadHtml();
  }

  Future<void> _fetchAndLoadHtml() async {
    try {
      final response = await Dio().get<dynamic>(widget.url);
      final body = response.data;

      // Parse JSON — handle both pre-decoded Map and raw String.
      final Map<String, dynamic> json;
      if (body is Map<String, dynamic>) {
        json = body;
      } else if (body is String) {
        json = jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response type');
      }

      final htmlContent = json['data'] as String? ?? '';

      // Wrap in a basic HTML document for proper RTL + styling.
      final fullHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, sans-serif;
      padding: 16px;
      line-height: 1.7;
      color: #333;
      direction: rtl;
      text-align: right;
    }
    h2 { font-size: 20px; margin-bottom: 12px; }
    p  { margin-bottom: 10px; font-size: 15px; }
  </style>
</head>
<body>$htmlContent</body>
</html>
''';

      await _controller.loadHtmlString(fullHtml);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'فشل تحميل المحتوى';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(title: widget.title),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.buttonYellow,
                    ),
                  ),
              ],
            ),
    );
  }
}
