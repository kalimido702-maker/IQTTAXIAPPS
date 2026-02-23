import 'package:flutter/material.dart';

/// App-wide Text replacement.
///
/// **Why?**
///  - Centralises every text customisation (direction, locale, font
///    fallback, accessibility scaling, analytics hooks, etc.) in one
///    place instead of scattering `textDirection:` across 50+ files.
///  - Easy to flip the entire app between RTL ↔ LTR by changing a
///    single default.
///
/// **Usage — identical to [Text]:**
/// ```dart
/// IqText('مرحباً', style: AppTypography.heading1)
/// IqText('Hello', dir: TextDirection.ltr)
/// IqText.rich(TextSpan(children: [...]))
/// ```
class IqText extends StatelessWidget {
  // ─── Plain text ───────────────────────────────────────────────

  /// Creates an [IqText] with plain string data.
  const IqText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.dir,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.semanticsLabel,
    this.textScaler,
  })  : _textSpan = null,
        _isRich = false;

  // ─── Rich text ────────────────────────────────────────────────

  /// Creates an [IqText] with an [InlineSpan] tree (same as [Text.rich]).
  const IqText.rich(
    InlineSpan textSpan, {
    super.key,
    this.style,
    this.textAlign,
    this.dir,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.semanticsLabel,
    this.textScaler,
  })  : data = null,
        _textSpan = textSpan,
        _isRich = true;

  /// The text to display (null when using [IqText.rich]).
  final String? data;

  /// The [InlineSpan] tree (null when using the plain constructor).
  final InlineSpan? _textSpan;

  /// Whether this was created via [IqText.rich].
  final bool _isRich;

  /// Text style — forwarded directly to [Text].
  final TextStyle? style;

  /// Alignment — forwarded directly to [Text].
  final TextAlign? textAlign;

  /// Text direction override.
  ///
  /// **Defaults to the ambient [Directionality]** which, in the IQ Taxi
  /// apps, is set to [TextDirection.rtl] at the [MaterialApp] level.
  /// Pass [TextDirection.ltr] explicitly for Latin / number strings
  /// that must always be left-to-right.
  final TextDirection? dir;

  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final String? semanticsLabel;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    if (_isRich) {
      return Text.rich(
        _textSpan!,
        key: key,
        style: style,
        textAlign: textAlign,
        textDirection: dir,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
        semanticsLabel: semanticsLabel,
        textScaler: textScaler,
      );
    }

    return Text(
      data ?? '',
      key: key,
      style: style,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: dir,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      semanticsLabel: semanticsLabel,
      textScaler: textScaler,
    );
  }
}
