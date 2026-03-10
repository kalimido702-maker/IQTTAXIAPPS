import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/pos_transaction_model.dart';

/// Full-screen QR scanner page for POS device payment verification.
///
/// Scans a QR code emitted by the POS device after a card transaction.
/// Parses the JSON, validates `ResponseCode == "00"`, and pops with
/// the parsed [PosTransactionModel] on success or `null` on failure/cancel.
class PosQrScannerPage extends StatefulWidget {
  const PosQrScannerPage({super.key});

  @override
  State<PosQrScannerPage> createState() => _PosQrScannerPageState();
}

class _PosQrScannerPageState extends State<PosQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    final transaction = PosTransactionModel.tryParse(raw);

    if (transaction == null) {
      // Not a valid POS JSON — show error and keep scanning.
      setState(() => _errorMessage = AppStrings.invalidQrCode);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = null);
      });
      return;
    }

    if (!transaction.isSuccessful) {
      // Transaction failed on POS side.
      _handled = true;
      HapticFeedback.heavyImpact();
      _showResultDialog(
        success: false,
        message: AppStrings.posPaymentFailed,
        detail:
            '${AppStrings.responseCode}: ${transaction.responseCode}\n${transaction.responseMessage}',
      );
      return;
    }

    // Success!
    _handled = true;
    HapticFeedback.mediumImpact();
    _showResultDialog(
      success: true,
      message: AppStrings.posPaymentSuccess,
      detail: '${AppStrings.amount}: ${transaction.amount}',
      transaction: transaction,
    );
  }

  void _showResultDialog({
    required bool success,
    required String message,
    required String detail,
    PosTransactionModel? transaction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        icon: Icon(
          success ? Icons.check_circle_rounded : Icons.error_rounded,
          color: success ? AppColors.success : AppColors.error,
          size: 56.w,
        ),
        title: IqText(
          message,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: success ? AppColors.success : AppColors.error,
          ),
          textAlign: TextAlign.center,
        ),
        content: IqText(
          detail,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              Navigator.of(context).pop(transaction); // pop scanner page
            },
            child: IqText(
              success ? AppStrings.confirm : AppStrings.cancel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Preview ──
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Dark overlay with cutout ──
          _ScannerOverlay(cutoutSize: 280.w),

          // ── Top bar ──
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24.w,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IqText(
                    AppStrings.scanQrCode,
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 40.w), // balance
                ],
              ),
            ),
          ),

          // ── Instruction text ──
          Positioned(
            bottom: 120.h,
            left: 32.w,
            right: 32.w,
            child: Column(
              children: [
                IqText(
                  AppStrings.scanQrInstruction,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: IqText(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Flash toggle ──
          Positioned(
            bottom: 48.h,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _controller.toggleTorch(),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, state, __) {
                      final isOn = state.torchState == TorchState.on;
                      return Icon(
                        isOn ? Icons.flash_on : Icons.flash_off,
                        color: isOn ? AppColors.primary : Colors.white,
                        size: 28.w,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a dark overlay with a transparent square cutout in the centre.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.cutoutSize});

  final double cutoutSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _OverlayPainter(cutoutSize: cutoutSize),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.cutoutSize});

  final double cutoutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final center = Offset(size.width / 2, size.height / 2);
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: cutoutSize, height: cutoutSize),
      Radius.circular(16.0),
    );

    // Full-screen path minus cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Corner brackets
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLen = cutoutSize * 0.12;
    final rect = cutoutRect.outerRect;

    // Top-left
    canvas.drawLine(rect.topLeft, Offset(rect.left + cornerLen, rect.top), borderPaint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cornerLen), borderPaint);
    // Top-right
    canvas.drawLine(rect.topRight, Offset(rect.right - cornerLen, rect.top), borderPaint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cornerLen), borderPaint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom), borderPaint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - cornerLen), borderPaint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, Offset(rect.right - cornerLen, rect.bottom), borderPaint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - cornerLen), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
