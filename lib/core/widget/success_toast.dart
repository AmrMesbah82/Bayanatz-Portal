// ******************* FILE INFO *******************
// File Name: success_toast.dart
// Purpose: BUG-46 — a short "saved" confirmation that survives navigation.
//
// The SnackBars shown after Create / Save / Delete were attached to the page
// that was being closed, so nobody ever saw them. This message lives in the
// ROOT overlay: it stays visible while pages pop and closes by itself.
//
// Look = the Figma message dialog (BAYANATZ WEB › DIALOGS, node 7126:33417:
// illustration, bold upper-case title, grey text, no buttons) — the same
// card as the app's confirm dialogs (edit_main_page_dialog.svg, Back/Confirm).
// It is drawn in the overlay instead of with showDialog so that the
// Navigator.pop() calls that follow it close the PAGE, not this message.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../custom_svg.dart';
import '../theme/appcolors.dart';
import '../theme/new_theme.dart';

OverlayEntry? _current;
Timer? _timer;

void _dismiss() {
  _timer?.cancel();
  _timer = null;
  _current?.remove();
  _current = null;
}

/// Shows [message] in the Figma message dialog for [duration].
/// [title] defaults to SUCCESS (or WARNING when [isError]).
void showSuccessToast(
  BuildContext context,
  String message, {
  String? title,
  bool isError = false,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _dismiss();

  final heading = (title ?? (isError ? 'Warning' : 'Success')).toUpperCase();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned.fill(
      child: GestureDetector(
        // Tap anywhere to close it early (like a dialog barrier).
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_current == entry) _dismiss();
        },
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 600.w,
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.light
                      ? Colors.white
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(-3, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: 180.w,
                      height: 160.h,
                      child: CustomSvg(
                          assetPath: 'assets/images/edit_main_page_dialog.svg'),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: StyleText.fontSize16Weight600.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: StyleText.fontSize13Weight400.copyWith(
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  _current = entry;
  _timer = Timer(duration, () {
    if (_current == entry) _dismiss();
  });
}
