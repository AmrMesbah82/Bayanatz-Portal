// ******************* FILE INFO *******************
// File Name: 16-custom_dialog_manager.dart
// Description: The shared dialog manager. Every confirm / message dialog in
//              the admin app should come from here instead of each page
//              re-declaring its own `showDialog` + Dialog + button row.
//
// Why a Future<bool> instead of an onConfirm callback:
//   The old per-page helpers handed the caller a VoidCallback and expected it
//   to close the dialog itself (`Navigator.of(context).pop()` as the first
//   line of every handler). Forgetting that pop left the dialog stuck over a
//   finished action, and popping twice closed the page behind it. Here the
//   dialog always closes itself and simply reports what the user chose:
//
//     final ok = await CustomDialogManager.showConfirm(...);
//     if (!ok) return;
//     ...do the work...
//
// Created by: Amr Mesbah

/// Module: core › custom

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constant/color.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';
import '../widget/auto_close_dialog.dart';

class CustomDialogManager {
  const CustomDialogManager._();

  /// Default illustration shown above the title.
  static const String defaultImage = 'assets/images/dashboard_image.svg';

  // ══════════════════════════════════════════════════════════════════════════
  //  CONFIRM
  // ══════════════════════════════════════════════════════════════════════════

  /// Confirmation dialog — illustration, title, message, [cancelText] /
  /// [confirmText] buttons.
  ///
  /// Returns `true` only when the user pressed the confirm button; `false`
  /// for cancel, the barrier, or the back gesture. The dialog closes itself
  /// before returning, so callers never pop it.
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Back',
    String imagePath = defaultImage,
    Color? confirmColor,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => Dialog(
        backgroundColor: ColorPick.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath.isNotEmpty) ...[
                SvgPicture.asset(imagePath, height: 120.h, fit: BoxFit.contain),
                SizedBox(height: 20.h),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: StyleText.fontSize18Weight500.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: StyleText.fontSize13Weight400.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: cancelText,
                      color: Colors.grey.shade300,
                      textColor: AppColors.text,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _dialogButton(
                      label: confirmText,
                      color: confirmColor ?? ColorPick.primary,
                      textColor: Colors.white,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MESSAGE
  // ══════════════════════════════════════════════════════════════════════════

  /// Message dialog for a result the user just has to see (saved, failed,
  /// nothing to export…). App rule (29/9/2026): no button — it closes itself
  /// after 3 s. [buttonText] / [buttonColor] are kept for old callers only.
  static Future<void> showMessage({
    required BuildContext context,
    required String title,
    String message = '',
    String buttonText = 'OK',
    String imagePath = defaultImage,
    Color? buttonColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AutoCloseDialog(
       child: Dialog(
        backgroundColor: ColorPick.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          width: 450.w,
          padding: EdgeInsets.all(30.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath.isNotEmpty) ...[
                SvgPicture.asset(imagePath, height: 120.h, fit: BoxFit.contain),
                SizedBox(height: 20.h),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: StyleText.fontSize18Weight500.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              if (message.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize13Weight400.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
       ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INTERNAL
  // ══════════════════════════════════════════════════════════════════════════

  static Widget _dialogButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: StyleText.fontSize14Weight600.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
