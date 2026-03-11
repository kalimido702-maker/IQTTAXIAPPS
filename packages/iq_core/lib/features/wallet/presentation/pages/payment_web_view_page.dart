import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';

/// Result of a QiCard WebView payment.
enum PaymentResult { success, failure, cancelled }

/// Full-screen WebView that loads the QiCard hosted payment page.
///
/// Detects the callback URL with `status=SUCCESS` or `status=FAILURE`
/// and pops with [PaymentResult].
class PaymentWebViewPage extends StatefulWidget {
  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
  });

  final String paymentUrl;

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            // QiCard callback detection
            if (url.contains('callback') || url.contains('redirect')) {
              final uri = Uri.tryParse(request.url);
              final status =
                  uri?.queryParameters['status']?.toUpperCase() ?? '';

              if (status == 'SUCCESS') {
                Navigator.of(context).pop(PaymentResult.success);
                return NavigationDecision.prevent;
              } else if (status == 'FAILURE' || status == 'FAIL') {
                Navigator.of(context).pop(PaymentResult.failure);
                return NavigationDecision.prevent;
              }
            }

            // Also check for success/failure in the URL path itself
            if (url.contains('/success')) {
              Navigator.of(context).pop(PaymentResult.success);
              return NavigationDecision.prevent;
            }
            if (url.contains('/failure') || url.contains('/fail')) {
              Navigator.of(context).pop(PaymentResult.failure);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(PaymentResult.cancelled);
        }
      },
      child: Scaffold(
        appBar: IqAppBar(title: AppStrings.onlinePayment),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16.h),
                    IqText(
                      AppStrings.loadingPaymentPage,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
