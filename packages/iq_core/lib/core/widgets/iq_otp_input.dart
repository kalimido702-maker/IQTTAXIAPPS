import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Premium OTP input with:
/// - Smooth focus/fill animations
/// - Full paste support (auto-distributes across fields)
/// - Proper backspace handling (jumps to previous field even when empty)
/// - Haptic feedback on each digit
/// - Cursor blinking on focused empty field
/// - Theme-aware colors (dark mode ready)
class IqOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  const IqOtpInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
  });

  @override
  State<IqOtpInput> createState() => _IqOtpInputState();
}

class _IqOtpInputState extends State<IqOtpInput>
    with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  /// Track which field is currently focused for visual feedback
  int _focusedIndex = -1;

  /// Prevent duplicate [onCompleted] calls
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.addListener(() => _onFocusChanged(i, node.hasFocus));
      return node;
    });

    // Scale-bounce animation per digit
    _scaleControllers = List.generate(
      widget.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      ),
    );
    _scaleAnimations = _scaleControllers
        .map((c) => Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack))
            .animate(c))
        .toList();

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final a in _scaleControllers) {
      a.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──

  String get _otp => _controllers.map((c) => c.text).join();

  void _onFocusChanged(int index, bool hasFocus) {
    setState(() => _focusedIndex = hasFocus ? index : -1);
  }

  /// Fill fields from a pasted/typed multi-character string starting at [start].
  void _distributeDigits(String digits, int start) {
    for (int i = 0; i < digits.length && (start + i) < widget.length; i++) {
      _controllers[start + i].text = digits[i];
      _playBounce(start + i);
    }

    // Move focus to the field after the last filled
    final nextIndex = (start + digits.length).clamp(0, widget.length - 1);
    if (nextIndex < widget.length) {
      _focusNodes[nextIndex].requestFocus();
    }

    _notifyChange();
  }

  void _notifyChange() {
    final otp = _otp;
    widget.onChanged?.call(otp);

    if (otp.length == widget.length && !_hasCompleted) {
      _hasCompleted = true;
      HapticFeedback.mediumImpact();
      widget.onCompleted?.call(otp);
    } else if (otp.length < widget.length) {
      _hasCompleted = false;
    }
  }

  void _playBounce(int index) {
    HapticFeedback.lightImpact();
    _scaleControllers[index]
      ..reset()
      ..forward().then((_) {
        if (mounted) _scaleControllers[index].reverse();
      });
  }

  void _onChanged(int index, String value) {
    // ── Paste / multi-char input ──
    if (value.length > 1) {
      // Extract only digits
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        _controllers[index].clear();
        _distributeDigits(digits, index);
      }
      return;
    }

    // ── Single digit entered ──
    if (value.length == 1) {
      _playBounce(index);
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field — dismiss keyboard
        _focusNodes[index].unfocus();
      }
    }

    _notifyChange();
  }

  /// Handle keyboard events for proper backspace behaviour.
  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;

    if (isBackspace) {
      if (_controllers[index].text.isNotEmpty) {
        // Clear current field
        _controllers[index].clear();
        _notifyChange();
        setState(() {}); // rebuild to update visual
        return KeyEventResult.handled;
      } else if (index > 0) {
        // Field is already empty — jump to previous and clear it
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        _notifyChange();
        setState(() {}); // rebuild to update visual
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) => _buildField(i, isDark)),
      ),
    );
  }

  Widget _buildField(int index, bool isDark) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusedIndex == index;

    // ── Colors ──
    final Color borderColor;
    final double borderWidth;
    if (hasValue) {
      borderColor = AppColors.primary;
      borderWidth = 2.0;
    } else if (isFocused) {
      borderColor = AppColors.primary.withValues(alpha: 0.6);
      borderWidth = 1.5;
    } else {
      borderColor = isDark ? AppColors.grayLight : AppColors.inputBorder;
      borderWidth = 1.0;
    }

    final bgColor = hasValue
        ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent);

    return AnimatedBuilder(
      listenable: _scaleAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[index].value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55.w,
        height: 54.h,
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: KeyboardListener(
          focusNode: FocusNode(), // wrapper focus node for key events
          onKeyEvent: (event) => _onKeyEvent(index, event),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _OtpPasteFormatter(
                fieldIndex: index,
                totalFields: widget.length,
                onPaste: _distributeDigits,
              ),
            ],
            onChanged: (v) => _onChanged(index, v),
            showCursor: isFocused && !hasValue,
            cursorColor: AppColors.primary,
            cursorWidth: 2,
            style: AppTypography.numberLarge.copyWith(
              fontSize: 22.sp,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: isFocused ? '' : '-',
              hintStyle: AppTypography.numberLarge.copyWith(
                color: AppColors.black,
                fontSize: 22.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same as [AnimatedBuilder] but allows a child for performance.
class AnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Intercepts paste events containing multiple digits and distributes
/// them across the OTP fields instead of cramming into one field.
class _OtpPasteFormatter extends TextInputFormatter {
  final int fieldIndex;
  final int totalFields;
  final void Function(String digits, int startIndex) onPaste;

  _OtpPasteFormatter({
    required this.fieldIndex,
    required this.totalFields,
    required this.onPaste,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final incoming = newValue.text;

    // If more than one digit was entered (paste), distribute
    if (incoming.length > 1) {
      // Schedule the distribution for the next frame to avoid
      // modifying controllers during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPaste(incoming, fieldIndex);
      });
      // Keep only the first digit in this field
      return TextEditingValue(
        text: incoming[0],
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    return newValue;
  }
}
