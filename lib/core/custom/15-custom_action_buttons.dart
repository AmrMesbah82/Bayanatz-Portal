// ******************* FILE INFO *******************
// File Name: 15-custom_action_buttons.dart
// Purpose: The four standard admin action buttons — Preview, Publish,
//          Discard, Save For Later — each built on customButton
//          (core/widget/button.dart), NOT ElevatedButton.
//
// Fixed (static) values:
// - Height 44.h, radius 8.r, text StyleText.fontSize14Weight600 white
// - Colors: ColorPick.preview / primary / saveForLater
// - Discard AND Back share AppColors.darkGrey — every "get me out of here"
//   button in the app is the same colour, set in this one place.
//
// Usage:
//   customPreviewButton(onTap: _preview)
//   customPublishButton(onTap: _publish, enabled: _isPublishEnabled)
//   customDiscardButton(onTap: _discard)
//   customBackButton(onTap: _back)
//   customSaveForLaterButton(onTap: _saveForLater)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../main_widgets/form_dirty_scope.dart';
import '../constant/color.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';
import '../widget/button.dart';

// ── Shared base (all four use this — one place for the style) ────────────────
Widget _actionButtonBase({
  required String title,
  required Color color,
  VoidCallback? onTap,
  bool enabled = true,
  double? width,
  double? height,
  /// Fired when the button is tapped while DISABLED. A dead button tells the
  /// user nothing, so Publish uses this to reveal which fields are still empty.
  VoidCallback? onBlockedTap,
}) {
  final bool active = enabled && onTap != null;

  return customButton(
    title:    title,
    function: active ? onTap : (onBlockedTap ?? () {}),
    width:    width,
    height:   height ?? 44.h,
    radius:   4.r,
    color:    active ? color : AppColors.secondaryText,
    textStyle: StyleText.fontSize14Weight600.copyWith(color: Colors.white),
  );
}

// ── Preview ──────────────────────────────────────────────────────────────────
Widget customPreviewButton({
  VoidCallback? onTap,
  String title  = 'Preview',
  Color? color,
  double? width,
  double? height,
}) =>
    _actionButtonBase(
      title:  title,
      color:  color ?? ColorPick.preview,
      onTap:  onTap,
      width:  width,
      height: height,
    );

// ── Publish ──────────────────────────────────────────────────────────────────
Widget customPublishButton({
  VoidCallback? onTap,
  String title  = 'Publish',
  bool  enabled = true,
  Color? color,
  double? width,
  double? height,
  VoidCallback? onBlockedTap,
  /// Publish also needs something to publish. Set false for a screen that may
  /// legitimately re-publish an untouched form.
  bool requireChanges = true,
}) =>
    // Builder gives us a BuildContext without changing a single call site, so
    // the button can read the page's has-changed flag.
    Builder(
      builder: (context) => _actionButtonBase(
        title:   title,
        color:   color ?? ColorPick.primary,
        onTap:   onTap,
        enabled: enabled &&
            (!requireChanges || FormDirtyScope.isDirty(context)),
        width:        width,
        height:       height,
        onBlockedTap: onBlockedTap,
      ),
    );

// ── Discard ──────────────────────────────────────────────────────────────────
Widget customDiscardButton({
  VoidCallback? onTap,
  String title  = 'Discard',
  Color? color,
  double? width,
  double? height,
}) =>
    _actionButtonBase(
      title:  title,
      color:  color ?? AppColors.darkGrey,
      onTap:  onTap,
      width:  width,
      height: height,
    );

// ── Back ─────────────────────────────────────────────────────────────────────
// Same colour and shape as Discard — both mean "leave without publishing".
// Use this instead of hand-rolling a grey Container on each page.
Widget customBackButton({
  VoidCallback? onTap,
  String title  = 'Back',
  Color? color,
  double? width,
  double? height,
}) =>
    _actionButtonBase(
      title:  title,
      color:  color ?? AppColors.darkGrey,
      onTap:  onTap,
      width:  width,
      height: height,
    );

// ── Save For Later ───────────────────────────────────────────────────────────
Widget customSaveForLaterButton({
  VoidCallback? onTap,
  String title  = 'Save For Later',
  bool  enabled = true,
  Color? color,
  double? width,
  double? height,
}) =>
    _actionButtonBase(
      title:   title,
      color:   color ?? ColorPick.saveForLater,
      onTap:   onTap,
      enabled: enabled,
      width:   width,
      height:  height,
    );
