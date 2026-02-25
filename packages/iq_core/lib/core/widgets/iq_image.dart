import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iq_core/core/theme/app_colors.dart';

/// The single image widget the entire app relies on.
///
/// Automatically detects the source type and renders accordingly:
///  • **SVG asset**  – path ends with `.svg`
///  • **Network**    – path starts with `http://` or `https://`
///  • **Raster asset** – everything else (png, jpg, webp …)
///
/// Usage:
/// ```dart
/// IqImage(AppAssets.iqTaxiLogo, width: 80, height: 80);
/// IqImage('https://example.com/photo.jpg', width: 120);
/// IqImage(AppAssets.splashWavePattern, fit: BoxFit.cover);
/// ```
class IqImage extends StatelessWidget {
  /// The image path — asset path **or** network URL.
  final String source;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// How the image should be inscribed into the box.
  final BoxFit fit;

  /// Optional colour applied on top of the image.
  ///  • For SVGs this sets a [ColorFilter] with [BlendMode.srcIn].
  ///  • For raster / network images this sets the [color] + [colorBlendMode].
  final Color? color;

  /// Blend mode used together with [color] for raster / network images.
  /// Defaults to [BlendMode.srcIn].
  final BlendMode colorBlendMode;

  /// Filter quality for raster images. Ignored for SVGs.
  final FilterQuality filterQuality;

  /// Placeholder widget shown while a **network** image loads.
  /// Falls back to a centred [CircularProgressIndicator] with the
  /// app's primary yellow colour.
  final Widget? placeholder;

  /// Widget shown when a **network** image fails to load.
  /// Falls back to a centred error icon.
  final Widget? errorWidget;

  /// Optional border radius — wraps the image in a [ClipRRect].
  final BorderRadius? borderRadius;

  /// If `true`, avoids the offscreen buffer that the [Opacity] widget uses
  /// and instead tints via colour blending (cheaper on the GPU).
  final double opacity;

  const IqImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.opacity = 1.0,
  });

  // ───────────────────────────────────────────
  // Source-type helpers
  // ───────────────────────────────────────────

  bool get _isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  bool get _isSvg => source.toLowerCase().endsWith('.svg');

  // ───────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isNetwork && _isSvg) {
      child = _buildNetworkSvg();
    } else if (_isNetwork) {
      child = _buildNetwork();
    } else if (_isSvg) {
      child = _buildSvg();
    } else {
      child = _buildAsset();
    }

    // Apply opacity via colour tint (avoids offscreen GPU buffer).
    if (opacity < 1.0) {
      if (_isSvg) {
        // SVGs: use ColorFiltered
        child = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color.fromRGBO(255, 255, 255, opacity),
            BlendMode.modulate,
          ),
          child: child,
        );
      }
      // Raster/network images get opacity via color parameter below.
    }

    // Apply border radius clipping.
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }

  // ───────────────────────────────────────────
  // SVG (asset only — network SVGs are rare)
  // ───────────────────────────────────────────

  Widget _buildSvg() {
    return SvgPicture.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }

  // ───────────────────────────────────────────
  // Network SVG
  // ───────────────────────────────────────────

  Widget _buildNetworkSvg() {
    return SvgPicture.network(
      source,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) =>
          placeholder ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.buttonYellow),
                ),
              ),
            ),
          ),
    );
  }

  // ───────────────────────────────────────────
  // Network image (with caching)
  // ───────────────────────────────────────────

  Widget _buildNetwork() {
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final effectiveColor = opacity < 1.0 && !_isSvg
        ? Color.fromRGBO(255, 255, 255, opacity)
        : color;
    final effectiveBlendMode = opacity < 1.0 && !_isSvg
        ? BlendMode.modulate
        : colorBlendMode;
    return CachedNetworkImage(
      imageUrl: source,
      width: width,
      height: height,
      fit: fit,
      color: effectiveColor,
      colorBlendMode: effectiveBlendMode,
      filterQuality: filterQuality,
      memCacheWidth: width != null ? (width! * dpr).toInt() : null,
      memCacheHeight: height != null ? (height! * dpr).toInt() : null,
      placeholder: (_, __) =>
          placeholder ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonYellow),
                ),
              ),
            ),
          ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.grayPlaceholder,
                size: 32,
              ),
            ),
          ),
    );
  }

  // ───────────────────────────────────────────
  // Raster asset (png, jpg, webp …)
  // ───────────────────────────────────────────

  Widget _buildAsset() {
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final effectiveColor = opacity < 1.0 && !_isSvg
        ? Color.fromRGBO(255, 255, 255, opacity)
        : color;
    final effectiveBlendMode = opacity < 1.0 && !_isSvg
        ? BlendMode.modulate
        : colorBlendMode;
    return Image.asset(
      source,
      width: width,
      height: height,
      fit: fit,
      color: effectiveColor,
      colorBlendMode: effectiveBlendMode,
      filterQuality: filterQuality,
      cacheWidth: width != null ? (width! * dpr).toInt() : null,
      cacheHeight: height != null ? (height! * dpr).toInt() : null,
      errorBuilder: (_, __, ___) =>
          errorWidget ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.grayPlaceholder,
                size: 32,
              ),
            ),
          ),
    );
  }
}
