// ******************* FILE INFO *******************
// File Name: image_upload_circle.dart
// Description: Shared circular "before upload" image picker used across
//              every CMS edit page (logos, avatars, section icons, etc.)
//              so every image-upload circle in the app looks and behaves
//              identically. Mirrors the reference implementation that used
//              to live only in about_us_edit/ui_helpers.dart.
// Created by: Amr Mesbah

/// Module: core › custom

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constant/color.dart';
import '../custom_svg.dart';
import '../main_widgets/form_dirty_scope.dart';
import '../main_widgets/validation_scope.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

int _imgUploadViewCounter = 0;

String _detectImageMime(Uint8List b) {
  if (b.length >= 4 &&
      b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    return 'image/png';
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (b.length >= 4 &&
      b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46) {
    return 'image/webp';
  }
  if (b.length >= 6 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) {
    return 'image/gif';
  }
  return 'image/svg+xml';
}

String _svgBytesToDataUrl(Uint8List bytes) {
  final base64 = base64Encode(bytes);
  return 'data:${_detectImageMime(bytes)};base64,$base64';
}

Widget _buildImageWidget(Uint8List? bytes, String url) {
  if (bytes != null) {
    final dataUrl = _svgBytesToDataUrl(bytes);
    final viewId =
        'img-upload-circle-bytes-${bytes.hashCode}-${_imgUploadViewCounter++}';

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final img = html.ImageElement()
        ..src = dataUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain';
      return img;
    });

    return Center(
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: SizedBox(
          width: 30.w,
          height: 30.h,
          child: HtmlElementView(viewType: viewId),
        ),
      ),
    );
  }

  if (url.isNotEmpty) {
    final viewId =
        'img-upload-circle-url-${url.hashCode}-${_imgUploadViewCounter++}';

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain';
      return img;
    });

    return Center(
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: SizedBox(
          width: 30.w,
          height: 30.h,
          child: HtmlElementView(viewType: viewId),
        ),
      ),
    );
  }

  return Icon(Icons.image_outlined, color: Colors.grey[500], size: 28.sp);
}

/// The circle + camera-badge control itself, with no label above it. Use
/// this when the call site already renders its own label/heading text
/// separately, so the label doesn't end up duplicated.
Widget imageUploadCircleBare({
  required Uint8List? bytes,
  required String url,
  required VoidCallback onTap,
  /// Set `isRequired: true` for an image the page cannot be published without.
  /// When a blocked Publish reveals what is missing, an empty circle then
  /// outlines itself in red — the same signal text fields and dropdowns give.
  /// See core/main_widgets/validation_scope.dart.
  bool isRequired = false,
  /// Ignored — kept so any call site that already passes it still compiles.
  BuildContext? context,
}) {
  final hasImage = bytes != null || url.isNotEmpty;
  // Builder gives every existing call site a BuildContext without adding an
  // argument, so the red border and the dirty-mark both work as-is.
  return Builder(builder: (ctx) {
  final bool missing =
      isRequired && !hasImage && ValidationScope.revealed(ctx);
  return GestureDetector(
    onTap: () {
      // Tapping the circle opens the file picker. Marking dirty here can
      // over-trigger if the user cancels, which is much better than a page
      // whose only change was an image staying stuck on "nothing to publish".
      FormDirtyScope.markDirty(ctx);
      onTap();
    },
    child: Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: missing
                ? Border.all(color: AppColors.red, width: 1.5)
                : null,
          ),
          child: hasImage
              ? ClipOval(child: _buildImageWidget(bytes, url))
              : Icon(
                  Icons.add,
                  color: Colors.grey[600],
                  size: 28.sp,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 25.w,
              height: 25.h,
              decoration: BoxDecoration(
                color: ColorPick.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: CustomSvg(
                  assetPath: "assets/control/camera.svg",
                  width: 10.w,
                  height: 10.h,
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  });
}

/// Standard circular image-upload control used across every CMS edit page.
/// Shows a plain "+" placeholder circle until an image is picked/loaded,
/// then displays the image clipped to a circle, with a small camera-badge
/// button (bottom-right) that always triggers [onTap].
Widget imageUploadCircle({
  required String label,
  required Uint8List? bytes,
  required String url,
  required VoidCallback onTap,
  bool isRequired = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: StyleText.fontSize14Weight400.copyWith(color: AppColors.text),
      ),
      SizedBox(height: 8.h),
      imageUploadCircleBare(
        bytes: bytes,
        url: url,
        onTap: onTap,
        isRequired: isRequired,
      ),
    ],
  );
}
