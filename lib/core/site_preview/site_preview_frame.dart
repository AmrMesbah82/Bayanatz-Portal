// ******************* FILE INFO *******************
// File Name: site_preview_frame.dart
// Description: The fake browser viewport every admin preview renders inside.
//
//              It reproduces the conditions a real visitor's browser gives the
//              site, so the widgets inside pick exactly the layout they would
//              pick in production:
//                • ScreenUtil design size  → .w / .h resolve as they do on the
//                  live site, not against the admin's 1920×1080 window
//                • MediaQuery size         → drives the desktop/tablet/mobile
//                  breakpoint the site checks
//                • Directionality          → LTR / RTL for the ENG / AR toggle
//                • AbsorbPointer           → the site's links call context.go(),
//                  which would navigate the ADMIN app away from the preview
//
//              Standard viewports, matching website_app/lib/main.dart:
//                Desktop 1366×768 · Tablet 1024×768 · Mobile 375×812
//
// Created by: Amr Mesbah

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The device sizes the previews offer.
enum SitePreviewDevice { desktop, tablet, mobile }

extension SitePreviewDeviceSize on SitePreviewDevice {
  double get width => switch (this) {
        SitePreviewDevice.desktop => 1366,
        SitePreviewDevice.tablet  => 1024,
        SitePreviewDevice.mobile  => 375,
      };

  double get height => switch (this) {
        SitePreviewDevice.desktop => 768,
        SitePreviewDevice.tablet  => 768,
        SitePreviewDevice.mobile  => 812,
      };

  String get label => switch (this) {
        SitePreviewDevice.desktop => 'Desktop',
        SitePreviewDevice.tablet  => 'Tablet',
        SitePreviewDevice.mobile  => 'Mobile',
      };
}

/// Renders [child] as if it were running in a [fakeWidth] × [fakeHeight]
/// browser, scaled down to whatever width the admin layout gives it.
class SitePreviewFrame extends StatelessWidget {
  const SitePreviewFrame({
    super.key,
    required this.fakeWidth,
    required this.fakeHeight,
    required this.isRtl,
    required this.child,
    this.interactive = false,
    this.borderRadius,
  });

  /// [heightFactor] makes the fake browser TALLER than the real device, without
  /// touching its width.
  ///
  /// Why: the page inside scrolls its own body, but the preview does not take
  /// pointer events (the site's links call context.go(), which would navigate
  /// the ADMIN app away), so that inner scroll cannot be driven by hand. Laying
  /// the page out in a tall viewport puts the whole page on screen at once, and
  /// the admin screen's own scroll then walks down it.
  ///
  /// It distorts nothing: ScreenUtil's design size and the MediaQuery size are
  /// both set to this viewport, so `.h` resolves exactly as it does at 1× —
  /// only the amount of page laid out changes.
  SitePreviewFrame.device({
    Key? key,
    required SitePreviewDevice device,
    required bool isRtl,
    required Widget child,
    bool interactive = false,
    BorderRadius? borderRadius,
    double heightFactor = 1.0,
  }) : this(
          key: key,
          fakeWidth: device.width,
          fakeHeight: device.height * heightFactor,
          isRtl: isRtl,
          interactive: interactive,
          borderRadius: borderRadius,
          child: child,
        );

  final double fakeWidth;
  final double fakeHeight;
  final bool   isRtl;
  final Widget child;

  /// Leave false. The site navigates with context.go() — letting taps through
  /// pulls the admin app out of the preview screen.
  final bool interactive;

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availW = constraints.maxWidth;
        final double scale  = _safeScale(availW / fakeWidth);
        final double outerH = fakeHeight * scale;

        // BUG-15: no nested ScreenUtilInit any more — see [PreviewViewport].
        Widget viewport = PreviewViewport(
          width:  fakeWidth,
          height: fakeHeight,
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child,
          ),
        );

        if (!interactive) viewport = AbsorbPointer(child: viewport);

        Widget frame = SizedBox(
          width:  availW,
          height: outerH,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth:  fakeWidth,
              maxWidth:  fakeWidth,
              minHeight: fakeHeight,
              maxHeight: fakeHeight,
              child: Transform.scale(
                scale:     scale,
                alignment: Alignment.topLeft,
                child:     viewport,
              ),
            ),
          ),
        );

        if (borderRadius != null) {
          frame = ClipRRect(borderRadius: borderRadius!, child: frame);
        }
        return frame;
      },
    );
  }

  static double _safeScale(double v) =>
      (v.isFinite && !v.isNaN && v > 0) ? v : 1.0;
}

/// BUG-15 — "Mobile" preview re-scaled the WHOLE admin (menu cut at
/// "Web Pag…", giant headings) until a reload.
///
/// Cause: every preview wrapped the site widgets in a nested
/// `ScreenUtilInit(designSize: <device>)`. ScreenUtil is a global singleton,
/// so that call re-configured `.w/.h/.sp` for the entire app, not just the
/// preview, and switching back to Desktop re-configured it again.
///
/// Fix: never touch ScreenUtil from a preview. The site widgets keep the
/// admin's scale factor `s`, and they are laid out in a viewport of
/// `device × s` logical pixels (so every `.w` value and every
/// `width < 600.w` breakpoint lands exactly where it would on the device),
/// then that viewport is scaled to fit the [width] × [height] box the caller
/// reserved.
class PreviewViewport extends StatelessWidget {
  const PreviewViewport({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  /// The device size being simulated, e.g. 375 × 812.
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s = ScreenUtil().scaleWidth;
    if (!s.isFinite || s.isNaN || s <= 0) s = 1.0;
    final double vw = width * s;
    final double vh = height * s;

    return SizedBox(
      width:  width,
      height: height,
      child: FittedBox(
        fit:       BoxFit.contain,
        alignment: Alignment.topLeft,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: Size(vw, vh)),
          child: SizedBox(width: vw, height: vh, child: child),
        ),
      ),
    );
  }
}
