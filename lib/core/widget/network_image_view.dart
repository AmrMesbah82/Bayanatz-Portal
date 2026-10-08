// ******************* FILE INFO *******************
// File Name: network_image_view.dart
// Description: Renders any network image/SVG through an HTML <img> element
//              (HtmlElementView) so both raster and SVG URLs display reliably
//              on Flutter web. Mirrors the pattern used in home sections.dart.
// Created by: Amr Mesbah

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_app_admin/core/custom_svg.dart';

/// Universal network image widget for the admin web app.
///
/// Renders [url] inside a real browser `<img>` element via [HtmlElementView].
/// This handles remote SVGs and raster images identically, matching the
/// behaviour used across the home / careers preview screens.
///
/// Two visual modes:
///  • Default (plain): just the image, sized by [width]/[height] and optionally
///    clipped by [borderRadius]. Use inside your own container/shape.
///  • [NetworkImageView.circle]: reproduces the sections.dart logo/icon circle —
///    a white circular background with padding, the image clipped to a circle,
///    and an `image.svg` placeholder when the URL is empty.
///
/// Note: because the image is drawn by the browser, SVG colour tinting is not
/// applied — the asset shows in its original colours (same as the reference
/// implementation in sections.dart).
class NetworkImageView extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Shown when [url] is empty (plain mode only).
  final Widget? placeholder;

  /// Circle (sections.dart) mode.
  final bool circle;
  final Color backgroundColor;
  final String emptyIconAsset;

  const NetworkImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.placeholder,
  })  : circle = false,
        backgroundColor = Colors.white,
        emptyIconAsset = 'assets/control/image.svg';

  /// Reproduces the white logo/icon circle from home `sections.dart`.
  ///
  /// [diameter] is the outer circle size; the image is inset with padding and
  /// clipped to a circle, exactly like `_logoCircle` / `_readOnlyIconCircle`.
  const NetworkImageView.circle({
    super.key,
    required this.url,
    required double diameter,
    this.backgroundColor = Colors.white,
    this.emptyIconAsset = 'assets/control/image.svg',
  })  : circle = true,
        width = diameter,
        height = diameter,
        fit = BoxFit.contain,
        borderRadius = null,
        placeholder = null;

  String get _objectFit {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
      case BoxFit.contain:
        return 'contain';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.none:
        return 'none';
    }
  }

  Widget _htmlImage() {
    final viewId =
        'net-img-${url.hashCode}-${width?.toInt()}-${height?.toInt()}-${fit.index}';
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _objectFit;
      return img;
    });
    return HtmlElementView(viewType: viewId);
  }

  @override
  Widget build(BuildContext context) {
    // ── Circle (sections.dart) mode ──────────────────────────────────────────
    if (circle) {
      final double d = width ?? 70.w;
      return Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: url.isNotEmpty
            ? Center(
                // The logo / icon used to fill only 43 % of the circle and
                // looked tiny everywhere this circle is used (Main logo,
                // section icons …). It now fills the circle's inner square
                // (≈ 70 %), so nothing is cut and the image reads clearly.
                child: ClipOval(
                  child: SizedBox(
                    width: d * 0.7,
                    height: d * 0.7,
                    child: _htmlImage(),
                  ),
                ),
              )
            : Center(
                child: CustomSvg(
                  assetPath: emptyIconAsset,
                  width: d * 0.43,
                  height: d * 0.43,
                  fit: BoxFit.fill,
                ),
              ),
      );
    }

    // ── Plain mode ───────────────────────────────────────────────────────────
    if (url.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    Widget inner = _htmlImage();
    if (width != null || height != null) {
      inner = SizedBox(width: width, height: height, child: inner);
    }
    if (borderRadius != null) {
      inner = ClipRRect(borderRadius: borderRadius!, child: inner);
    }
    return inner;
  }
}
